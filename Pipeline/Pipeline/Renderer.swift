//
//  Renderer.swift
//  Pipeline
//
//  Created by Paulo José on 09/03/23.
//

import MetalKit

class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var mesh: MTKMesh!
    var vextexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    
    init(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU is not available")
        }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let size: Float = 0.8
        let mdlMesh = MDLMesh(boxWithExtent: [size, size, size],
                              segments: [1, 1, 1],
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        
        do {
            mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch let error {
            print(error.localizedDescription)
        }
        
        vextexBuffer = mesh.vertexBuffers[0].buffer
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)
        metalView.delegate = self
        
        let library = device.makeDefaultLibrary()
        Renderer.library = library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let descriptor = view.currentRenderPassDescriptor,
              let renderEnconder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        renderEnconder.setRenderPipelineState(pipelineState)
        renderEnconder.setVertexBuffer(vextexBuffer, offset: 0, index: 0)
         
        for submesh in mesh.submeshes {
            renderEnconder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
        
        renderEnconder.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
