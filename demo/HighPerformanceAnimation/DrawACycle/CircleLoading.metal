//
//  CircleDrawShader.metal
//  demo
//
//  Created by RichardX on 2026/8/15.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float progress; // 0.0 ~ 1.0 绘制进度
    float2 viewportSize;
};

// 顶点着色器：绘制全屏四边形
vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    const float4 positions[4] = {
        float4(-1.0, -1.0, 0.0, 1.0),
        float4( 1.0, -1.0, 0.0, 1.0),
        float4(-1.0,  1.0, 0.0, 1.0),
        float4( 1.0,  1.0, 0.0, 1.0)
    };
    const float2 uvs[4] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0)
    };
    VertexOut out;
    out.position = positions[vertexID];
    out.uv = uvs[vertexID];
    return out;
}

// 1. 定义从“M”到“外部圆圈”的连续路径关键点 (归一化坐标系)
constexpr constant int NUM_POINTS = 14;
constexpr constant float2 POINTS[NUM_POINTS] = {
    float2(-0.30, -0.10), // 0: 起点，M的左侧底部
    float2(-0.25,  0.25), // 1: M的左上顶点
    float2( 0.00, -0.15), // 2: M的中心凹点
    float2( 0.25,  0.25), // 3: M的右上顶点
    float2( 0.30, -0.10), // 4: M的右侧底部
    float2( 0.35, -0.10), // 5: 连接到外部圆圈的起点
    float2( 0.45,  0.00), // 6: 外部圆圈右侧边缘
    float2( 0.35,  0.25), // 7: 外部圆圈右上
    float2( 0.00,  0.35), // 8: 外部圆圈顶部
    float2(-0.35,  0.25), // 9: 外部圆圈左上
    float2(-0.45,  0.00), // 10: 外部圆圈左侧边缘
    float2(-0.35, -0.10), // 11: 外部圆圈左下
    float2( 0.00, -0.30), // 12: 外部圆圈底部
    float2( 0.33, -0.10)  // 13: 终点，即将闭合前结束 (留下缝隙)
};

// 计算点到线段的最短距离 (SDF)
float sdSegment(float2 p, float2 a, float2 b) {
    float2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// 片段着色器：根据 progress 绘制截断路径
fragment float4 fragment_main(VertexOut in [[stage_in]], constant Uniforms &uniforms [[buffer(0)]]) {
    // 等比例适配屏幕
    float2 uv = (in.uv - 0.5) * float2(uniforms.viewportSize.x / uniforms.viewportSize.y, 1.0);
    float lineWidth = 0.045; // 粗体线条宽度
    float minDist = 1e10;

    // 预先计算所有线段总长度
    float segLens[NUM_POINTS - 1];
    float totalLen = 0.0;
    for (int i = 0; i < NUM_POINTS - 1; ++i) {
        segLens[i] = length(POINTS[i + 1] - POINTS[i]);
        totalLen += segLens[i];
    }

    // 核心：计算当前需要绘制到的距离
    float currentLimit = uniforms.progress * totalLen;
    float currLen = 0.0;

    // 遍历路径，只绘制 `progress` 之前的线段
    for (int i = 0; i < NUM_POINTS - 1; ++i) {
        if (currLen < currentLimit) {
            float2 start = POINTS[i];
            float2 end = POINTS[i + 1];
            
            // 计算当前线段内需要绘制到的位置，形成“笔触”的头部
            float localT = (currentLimit - currLen) / segLens[i];
            localT = clamp(localT, 0.0, 1.0);
            float2 capEnd = mix(start, end, localT);
            
            // 计算当前像素到截断线段的距离
            float d = sdSegment(uv, start, capEnd);
            minDist = min(minDist, d);
        }
        currLen += segLens[i];
    }

    // 如果未触及任何线段，透明度为 0
    if (minDist > 9999.0) { discard_fragment(); }

    // 边缘抗锯齿平滑处理
    float alpha = 1.0 - smoothstep(lineWidth - 0.005, lineWidth + 0.005, minDist);
    if (alpha < 0.01) { discard_fragment(); }

    return float4(1.0, 1.0, 1.0, alpha);
}
