//
//  DeepSeekStreamClient.swift
//  demo
//
//  Created by RichardX on 2026/8/12.
//
import Foundation

enum StreamEvent: Sendable {
    case content(String)
    case thinking(String)
    case done
}

actor DeepSeekStreamManager {
    private let apiKey: String
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var buffer = Data()
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// 创建一个流式对话的 AsyncSequence
    func stream(messages: [[String: String]],
                model: String = "deepseek-chat") -> AsyncThrowingStream<StreamEvent, Error> {
        
        // 先取消之前未结束的流
        task?.cancel()
        task = nil
        buffer.removeAll()
        
        return AsyncThrowingStream { continuation in
            guard let url = URL(string: "https://api.deepseek.com/v1/chat/completions") else {
                continuation.finish(throwing: URLError(.badURL))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "model": model,
                "messages": messages,
                "stream": true
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let delegate = SessionDelegate(manager: self, continuation: continuation)
            let config = URLSessionConfiguration.default
            session = URLSession(configuration: config,
                                 delegate: delegate,
                                 delegateQueue: nil)  // nil 让系统创建后台串行队列
            task = session?.dataTask(with: request)
            task?.resume()
            
            // 当外界取消迭代时，自动取消网络请求
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.cancel()
                }
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
        buffer.removeAll()
    }
    
    // 由 delegate 调用，处理收到的数据
    fileprivate func handle(data: Data, continuation: AsyncThrowingStream<StreamEvent, Error>.Continuation) {
        buffer.append(data)
        parseBuffer(continuation: continuation)
    }
    
    // 由 delegate 调用，处理结束或错误
    func handleCompletion(error: Error?,
                                      continuation: AsyncThrowingStream<StreamEvent, Error>.Continuation) {
        if let error {
            continuation.finish(throwing: error)
        } else {
            // 最后可能缓冲区还有残留
            if !buffer.isEmpty {
                parseBuffer(continuation: continuation, isFinal: true)
            }
            continuation.finish()
        }
        task = nil
        buffer.removeAll()
    }
    
    // MARK: - SSE 解析（在 actor 中串行执行，线程安全）
    private func parseBuffer(continuation: AsyncThrowingStream<StreamEvent, Error>.Continuation,
                             isFinal: Bool = false) {
        guard var text = String(data: buffer, encoding: .utf8) else { return }
        
        // 保留不完整行
        if !isFinal && !text.hasSuffix("\n") {
            if let lastNewline = text.lastIndex(of: "\n") {
                let complete = String(text[...lastNewline])
                let incomplete = String(text[text.index(after: lastNewline)...])
                text = complete
                buffer = incomplete.data(using: .utf8) ?? Data()
            } else {
                return  // 无换行，等待下次数据
            }
        } else {
            buffer.removeAll()
        }
        
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))
            
            if jsonString == "[DONE]" {
                continuation.yield(.done)
                continue
            }
            
            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any] else {
                continue
            }
            
            if let reasoning = delta["reasoning_content"] as? String, !reasoning.isEmpty {
                continuation.yield(.thinking(reasoning))
            }
            if let content = delta["content"] as? String, !content.isEmpty {
                continuation.yield(.content(content))
            }
        }
    }
}

final class SessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let manager: DeepSeekStreamManager
    private let continuation: AsyncThrowingStream<StreamEvent, Error>.Continuation
    
    // 用于处理非2xx响应错误
    private var receivedData = Data()
    private var httpError: Error?
    private var responseStatusCode: Int?
    
    init(manager: DeepSeekStreamManager,
         continuation: AsyncThrowingStream<StreamEvent, Error>.Continuation) {
        self.manager = manager
        self.continuation = continuation
    }
    
    // 检查HTTP响应状态码
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            responseStatusCode = httpResponse.statusCode
            if !(200...299).contains(httpResponse.statusCode) {
                httpError = NSError(domain: "DeepSeekAPI",
                                    code: httpResponse.statusCode,
                                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            }
        }
        completionHandler(.allow)  // 继续接收数据，以便获取错误详情
    }
    
    // 接收数据
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        if httpError != nil {
            // 非2xx响应：只累积错误数据，不进行SSE解析
            receivedData.append(data)
        } else {
            // 正常响应：转发给 DeepSeekStreamManager 进行解析
            Task {
                await manager.handle(data: data, continuation: continuation)
            }
        }
    }
    
    // 请求结束或失败
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        var finalError = error
        
        if let httpError = httpError {
            // 尝试从错误响应数据中解析出服务器返回的具体错误信息
            if let data = receivedData as Data?,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = json["error"] as? [String: Any],
               let message = errorDict["message"] as? String {
                finalError = NSError(domain: "DeepSeekAPI",
                                     code: responseStatusCode ?? -1,
                                     userInfo: [NSLocalizedDescriptionKey: message])
            } else {
                finalError = httpError
            }
        }
        
        Task {
            await manager.handleCompletion(error: finalError, continuation: continuation)
        }
    }
}
