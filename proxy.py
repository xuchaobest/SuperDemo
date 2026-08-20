import os
import json
import logging
import fnmatch
from pathlib import Path
from typing import Optional, List, Dict, Set

import httpx
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

from dotenv import load_dotenv
load_dotenv()
# ===================== 配置区（可通过环境变量覆盖） =====================
DEEPSEEK_API_URL = os.getenv("DEEPSEEK_API_URL", "https://api.deepseek.com/v1/chat/completions")
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
TRIGGER_MARKER = os.getenv("INJECT_TRIGGER", "@ctx")
MARKER = "[XcodeProxy-AgentsSkillsContext]"
MAX_FILE_SIZE = 50 * 1024          # 单个文件最大 50KB
MAX_TOTAL_CONTEXT = 200 * 1024     # 总上下文最大 200KB
CONTEXT_IGNORE_FILE = ".contextignore"
SKILLS_DIR = ".agents/skills"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("xcode-proxy")

# 缓存：文件路径 -> (mtime_ns, size, content)
_file_cache: Dict[str, tuple] = {}

# ===================== 工具函数 =====================

def mask_headers(headers: dict) -> dict:
    masked = dict(headers)
    if "authorization" in masked:
        masked["authorization"] = "Bearer ***"
    if "x-api-key" in masked:
        masked["x-api-key"] = "***"
    return masked


def find_project_root(start_dir: Path) -> Optional[Path]:
    current = start_dir.resolve()
    while True:
        if any(current.glob("*.xcodeproj")) or any(current.glob("*.xcworkspace")) or (current / ".git").exists():
            return current
        if current.parent == current:
            return start_dir.resolve()
        current = current.parent


def read_file_with_cache(file_path: Path) -> Optional[str]:
    """读取文件，带缓存（基于 mtime 和 size）"""
    try:
        stat = file_path.stat()
    except FileNotFoundError:
        _file_cache.pop(str(file_path), None)
        return None

    cache_key = str(file_path)
    cached = _file_cache.get(cache_key)
    if cached and cached[0] == stat.st_mtime_ns and cached[1] == stat.st_size:
        return cached[2]

    if stat.st_size > MAX_FILE_SIZE:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read(MAX_FILE_SIZE) + "\n...[truncated]"
    else:
        content = file_path.read_text(encoding="utf-8")

    content = content.lstrip("\ufeff")
    if not content.strip():
        _file_cache.pop(cache_key, None)
        return None

    _file_cache[cache_key] = (stat.st_mtime_ns, stat.st_size, content)
    return content


def load_contextignore(project_root: Path) -> List[str]:
    """解析 .contextignore，返回忽略模式列表（类似 .gitignore）"""
    ignore_file = project_root / CONTEXT_IGNORE_FILE
    if not ignore_file.is_file():
        return []
    patterns = []
    for line in ignore_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            patterns.append(line)
    return patterns


def is_ignored(rel_path: str, patterns: List[str]) -> bool:
    """判断相对路径是否匹配忽略模式（支持简单通配符）"""
    for pattern in patterns:
        if fnmatch.fnmatch(rel_path, pattern) or fnmatch.fnmatch(rel_path, pattern.rstrip("/") + "/*"):
            return True
        # 支持目录匹配
        if pattern.endswith("/") and rel_path.startswith(pattern):
            return True
    return False


def collect_skill_files(skills_dir: Path, ignore_patterns: List[str]) -> List[Path]:
    """收集 .agents/skills 下的所有 .md 文件，排除被忽略的"""
    if not skills_dir.is_dir():
        return []
    skill_files = []
    for file_path in skills_dir.rglob("*.md"):
        rel_path = file_path.relative_to(skills_dir).as_posix()
        # 注意：需要相对于项目根目录的路径，但这里我们先相对 skills_dir，忽略规则也应对此生效
        if not is_ignored(rel_path, ignore_patterns):
            skill_files.append(file_path)
    return sorted(skill_files)  # 按路径排序，保持确定性


def build_context_content(project_root: Path) -> Optional[str]:
    """构建完整的上下文字符串"""
    parts = []

    # 1. AGENTS.md
    agents_md = read_file_with_cache(project_root / "AGENTS.md")
    if agents_md:
        parts.append(f"## AGENTS.md\n{agents_md}")

    # 2. .contextignore 加载
    ignore_patterns = load_contextignore(project_root)

    # 3. .agents/skills/ 下的技能文件
    skills_dir = project_root / SKILLS_DIR
    skill_files = collect_skill_files(skills_dir, ignore_patterns)
    if skill_files:
        skills_content = []
        for sf in skill_files:
            content = read_file_with_cache(sf)
            if content:
                # 使用相对于 skills_dir 的名称作为标题
                rel = sf.relative_to(skills_dir).as_posix()
                skills_content.append(f"### {rel}\n{content}")
        if skills_content:
            parts.append("## Skills\n" + "\n\n".join(skills_content))

    if not parts:
        return None

    total_size = sum(len(p.encode("utf-8")) for p in parts)
    if total_size > MAX_TOTAL_CONTEXT:
        logger.warning(f"Total context size {total_size} exceeds limit {MAX_TOTAL_CONTEXT}, truncating")
        # 简单截断：按比例减小各部分，或只保留 AGENTS.md 的开头
        # 这里只做简单截断：取前 MAX_TOTAL_CONTEXT 字节
        combined = "\n\n".join(parts)
        truncated = combined[:MAX_TOTAL_CONTEXT] + "\n...[truncated]"
    else:
        truncated = "\n\n".join(parts)

    return f"{MARKER}\n以下是项目规范和技能指南，请在编码时严格遵守：\n\n{truncated}"


def extract_text_content(message: dict) -> str:
    content = message.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        texts = []
        for part in content:
            if isinstance(part, dict) and part.get("type") == "text":
                texts.append(part.get("text", ""))
        return " ".join(texts)
    return ""

def has_trigger(messages: List[dict]) -> bool:
    user_msgs = [m for m in messages if m.get("role") == "user"]
    if not user_msgs:
        return False
    last_content = extract_text_content(user_msgs[-1])
    return last_content.rstrip().endswith(TRIGGER_MARKER)


def inject_system_prompt(messages: List[dict], system_content: str) -> List[dict]:
    # 防重复
    if any(isinstance(m.get("content"), str) and MARKER in m["content"] for m in messages):
        return messages

    for i, m in enumerate(messages):
        if m.get("role") == "system":
            messages[i]["content"] = f"{system_content}\n\n{m.get('content', '')}"
            return messages
    messages.insert(0, {"role": "system", "content": system_content})
    return messages


# ===================== FastAPI 应用 =====================
app = FastAPI()

@app.get("/v1/models")
async def list_models():
    """Xcode 需要这个端点来发现模型"""
    return {
        "object": "list",
        "data": [
            {"id": "deepseek-coder", "object": "model", "created": 1677654321, "owned_by": "deepseek"}
        ]
    }
    
@app.post("/v1/chat/completions")
async def proxy_chat_completions(request: Request):
    try:
        body = await request.json()
    except Exception as e:
        logger.error(f"Invalid JSON: {e}")
        return JSONResponse(status_code=400, content={"error": "Invalid JSON"})

    # 记录原始请求
    logger.info("=" * 60)
    logger.info("Received request:")
    logger.info(f"Headers: {json.dumps(mask_headers(dict(request.headers)), indent=2, ensure_ascii=False)}")
    logger.info(f"Body: {json.dumps(body, indent=2, ensure_ascii=False)}")

    messages = body.get("messages")
    if not isinstance(messages, list):
        logger.warning("No 'messages' array, forwarding as-is")
    else:
        if has_trigger(messages):
            logger.info(f"Trigger '{TRIGGER_MARKER}' detected, collecting context...")

            # 确定项目根目录
            project_root_env = os.getenv("XCODE_PROJECT_ROOT")
            if project_root_env:
                project_root = Path(project_root_env)
            else:
                project_root = find_project_root(Path.cwd())

            if project_root:
                logger.info(f"Project root: {project_root}")
                context_content = build_context_content(project_root)
                if context_content:
                    body["messages"] = inject_system_prompt(messages, context_content)
                    logger.info(f"Injected context ({len(context_content)} chars)")
                    logger.info("Modified request body:")
                    logger.info(json.dumps(body, indent=2, ensure_ascii=False))
                else:
                    logger.warning("No context files found, skipping injection")
            else:
                logger.warning("Project root not found, skipping injection")
        else:
            logger.info("Trigger not found, forwarding without injection")

    # 转发请求
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
    }
    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            resp = await client.post(DEEPSEEK_API_URL, json=body, headers=headers)
            logger.info("-" * 60)
            logger.info(f"Response status: {resp.status_code}")
            logger.info(f"Response headers: {json.dumps(mask_headers(dict(resp.headers)), indent=2, ensure_ascii=False)}")
            try:
                resp_json = resp.json()
                logger.info(f"Response body: {json.dumps(resp_json, indent=2, ensure_ascii=False)}")
            except Exception:
                logger.info(f"Response body (non-JSON): {resp.text[:1000]}")

            return Response(
                content=resp.content,
                status_code=resp.status_code,
                headers=dict(resp.headers),
                media_type=resp.headers.get("content-type", "application/json"),
            )
        except httpx.HTTPError as e:
            logger.error(f"HTTP error: {e}")
            return JSONResponse(status_code=502, content={"error": "Upstream request failed"})
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            return JSONResponse(status_code=500, content={"error": "Internal server error"})


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000, log_level="info")
