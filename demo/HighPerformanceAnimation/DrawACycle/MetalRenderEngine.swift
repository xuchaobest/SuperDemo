//
//  MetalCircleDrawView.swift
//  demo
//
//  Created by RichardX on 2026/8/15.
//

import UIKit
import Metal
import MetalKit

// 确保整个类在主线程执行
@MainActor
class MetalCircleRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var uniformsBuffer: MTLBuffer!
    private var startTime: CFTimeInterval = 0
    
    // 动画时间常量
    private let drawDuration: Float = 1.4 // 绘制 M 和圆圈耗时
    private let pauseDuration: Float = 0.6 // 画完定格 0.6 秒
    private var totalCycleDuration: Float { return drawDuration + pauseDuration } // 2.0秒
    
    @objc init?(mtkView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = commandQueue
        mtkView.device = device
        mtkView.backgroundColor = .clear
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.drawableSize = mtkView.frame.size
        
        guard let library = device.makeDefaultLibrary(),
              let vertexFunc = library.makeFunction(name: "vertex_main"),
              let fragmentFunc = library.makeFunction(name: "fragment_main") else { return nil }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch { return nil }
        
        super.init()
        mtkView.delegate = self
        startTime = CACurrentMediaTime()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let currentTime = CACurrentMediaTime() - startTime
        let cycleTime = Float(currentTime).truncatingRemainder(dividingBy: totalCycleDuration)
        
        // 核心逻辑：延迟 0.6秒 重绘
        var progress: Float = 0.0
        if cycleTime <= drawDuration {
            progress = cycleTime / drawDuration
        } else {
            progress = 1.0 // 剩余 0.6秒 保持完成状态
        }
        
        struct UniformsData {
            var progress: Float
            var viewportSize: SIMD2<Float>
        }
        
        let viewSize = view.drawableSize
        var uniforms = UniformsData(
            progress: progress,
            viewportSize: SIMD2<Float>(Float(viewSize.width), Float(viewSize.height))
        )
        
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<UniformsData>.size, options: [])
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
