//
//  PreviewMetalView.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

/*
 See LICENSE.txt for this sample’s licensing information.
 
 Abstract:
 Metal preview view.
 */

import Foundation
import CoreMedia
import Metal
import MetalKit

class LiveMetalView: MTKView
{
    /// Standard UI rotations.
    ///
    /// - rotate0Degrees: At 0° rotation.
    /// - rotate90Degrees: At 90° rotation.
    /// - rotate180Degrees: At 180° rotation.
    /// - rotate270Degrees: At 270° rotation.
    enum Rotation: Int
    {
        case rotate0Degrees
        case rotate90Degrees
        case rotate180Degrees
        case rotate270Degrees
    }
    
    var mirroring = false
    {
        didSet
        {
            SyncQueue.sync
                {
                    InternalMirroring = mirroring
            }
        }
    }
    
    private var InternalMirroring: Bool = false
    
    var rotation: Rotation = .rotate0Degrees
    {
        didSet {
            SyncQueue.sync
                {
                    InternalRotation = rotation
            }
        }
    }
    
    private var InternalRotation: Rotation = .rotate0Degrees
    
    var PixelBufferLock = NSObject()
    
    var pixelBuffer: CVPixelBuffer?
    {
        didSet
        {
            SyncQueue.sync
                {
                    objc_sync_enter(PixelBufferLock)
                    defer {objc_sync_exit(PixelBufferLock)}
                    InternalPixelBuffer = pixelBuffer
            }
        }
    }
    
    private var InternalPixelBuffer: CVPixelBuffer?
    
    private let SyncQueue = DispatchQueue(label: "Preview View Sync Queue",
                                          qos: .userInitiated, attributes: [],
                                          autoreleaseFrequency: .workItem)
    
    private var textureCache: CVMetalTextureCache?
    
    private var textureWidth: Int = 0
    
    private var textureHeight: Int = 0
    
    private var textureMirroring = false
    
    private var textureRotation: Rotation = .rotate0Degrees
    
    private var sampler: MTLSamplerState!
    
    private var renderPipelineState: MTLRenderPipelineState!
    
    private var commandQueue: MTLCommandQueue?
    
    private var vertexCoordBuffer: MTLBuffer!
    
    private var textCoordBuffer: MTLBuffer!
    
    private var InternalBounds: CGRect!
    
    private var textureTranform: CGAffineTransform?
    
    func texturePointForView(point: CGPoint) -> CGPoint?
    {
        var result: CGPoint?
        guard let transform = textureTranform else
        {
            return result
        }
        let transformPoint = point.applying(transform)
        
        if CGRect(origin: .zero, size: CGSize(width: textureWidth, height: textureHeight)).contains(transformPoint)
        {
            result = transformPoint
        }
        else
        {
            print("Invalid point \(point) result point \(transformPoint)")
        }
        
        return result
    }
    
    func viewPointForTexture(point: CGPoint) -> CGPoint?
    {
        var result: CGPoint?
        guard let transform = textureTranform?.inverted() else
        {
            return result
        }
        let transformPoint = point.applying(transform)
        
        if InternalBounds.contains(transformPoint)
        {
            result = transformPoint
        }
        else
        {
            print("Invalid point \(point) result point \(transformPoint)")
        }
        
        return result
    }
    
    func FlushTextureCache()
    {
        textureCache = nil
    }
    
    private func setupTransform(width: Int, height: Int, mirroring: Bool, rotation: Rotation)
    {
        var scaleX: Float = 1.0
        var scaleY: Float = 1.0
        var resizeAspect: Float = 1.0
        
        InternalBounds = self.bounds
        textureWidth = width
        textureHeight = height
        textureMirroring = mirroring
        textureRotation = rotation
        
        if textureWidth > 0 && textureHeight > 0
        {
            switch textureRotation
            {
            case .rotate0Degrees, .rotate180Degrees:
                scaleX = Float(InternalBounds.width / CGFloat(textureWidth))
                scaleY = Float(InternalBounds.height / CGFloat(textureHeight))
                
            case .rotate90Degrees, .rotate270Degrees:
                scaleX = Float(InternalBounds.width / CGFloat(textureHeight))
                scaleY = Float(InternalBounds.height / CGFloat(textureWidth))
            }
        }
        // Resize aspect
        resizeAspect = min(scaleX, scaleY)
        if scaleX < scaleY
        {
            scaleY = scaleX / scaleY
            scaleX = 1.0
        }
        else
        {
            scaleX = scaleY / scaleX
            scaleY = 1.0
        }
        
        if textureMirroring
        {
            scaleX *= -1.0
        }
        
        // Vertex coordinate takes the gravity into account
        let vertexData: [Float] =
            [
                -scaleX, -scaleY, 0.0, 1.0,
                scaleX,  -scaleY, 0.0, 1.0,
                -scaleX, scaleY,  0.0, 1.0,
                scaleX,  scaleY,  0.0, 1.0
        ]
        vertexCoordBuffer = device!.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        
        // Texture coordinate takes the rotation into account
        var textData: [Float]
        switch textureRotation
        {
        case .rotate0Degrees:
            textData =
                [
                    0.0, 1.0,
                    1.0, 1.0,
                    0.0, 0.0,
                    1.0, 0.0
            ]
            
        case .rotate180Degrees:
            textData =
                [
                    1.0, 0.0,
                    0.0, 0.0,
                    1.0, 1.0,
                    0.0, 1.0
            ]
            
        case .rotate90Degrees:
            textData =
                [
                    1.0, 1.0,
                    1.0, 0.0,
                    0.0, 1.0,
                    0.0, 0.0
            ]
            
        case .rotate270Degrees:
            textData =
                [
                    0.0, 0.0,
                    0.0, 1.0,
                    1.0, 0.0,
                    1.0, 1.0
            ]
        }
        textCoordBuffer = device?.makeBuffer(bytes: textData, length: textData.count * MemoryLayout<Float>.size, options: [])
        
        // Calculate the transform from texture coordinates to view coordinates
        var transform = CGAffineTransform.identity
        if textureMirroring
        {
            transform = transform.concatenating(CGAffineTransform(scaleX: -1, y: 1))
            transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(textureWidth), y: 0))
        }
        
        switch textureRotation
        {
        case .rotate0Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(0)))
            
        case .rotate180Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(Double.pi)))
            transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(textureWidth), y: CGFloat(textureHeight)))
            
        case .rotate90Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(Double.pi) / 2))
            transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(textureHeight), y: 0))
            
        case .rotate270Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: 3 * CGFloat(Double.pi) / 2))
            transform = transform.concatenating(CGAffineTransform(translationX: 0, y: CGFloat(textureWidth)))
        }
        
        transform = transform.concatenating(CGAffineTransform(scaleX: CGFloat(resizeAspect), y: CGFloat(resizeAspect)))
        let tranformRect = CGRect(origin: .zero, size: CGSize(width: textureWidth, height: textureHeight)).applying(transform)
        let tx = (InternalBounds.size.width - tranformRect.size.width) / 2
        let ty = (InternalBounds.size.height - tranformRect.size.height) / 2
        transform = transform.concatenating(CGAffineTransform(translationX: tx, y: ty))
        textureTranform = transform.inverted()
    }
    
    required init(coder: NSCoder)
    {
        super.init(coder: coder)
        
        device = MTLCreateSystemDefaultDevice()
        
        configureMetal()
        
        createTextureCache()
        
        colorPixelFormat = .bgra8Unorm
    }
    
    func configureMetal()
    {
        if let defaultLibrary = device!.makeDefaultLibrary()
        {
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexPassThrough")
            pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentPassThrough")
            
            // To determine how our textures are sampled, we create a sampler descriptor, which
            // will be used to ask for a sampler state object from our device below.
            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.sAddressMode = .clampToEdge
            samplerDescriptor.tAddressMode = .clampToEdge
            samplerDescriptor.minFilter = .linear
            samplerDescriptor.magFilter = .linear
            sampler = device!.makeSamplerState(descriptor: samplerDescriptor)
            if sampler != nil
            {
                do {
                    renderPipelineState = try device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
                }
                catch
                {
                    fatalError("Unable to create preview Metal view pipeline state. (\(error))")
                }
                
                commandQueue = device!.makeCommandQueue()
            }
            else
            {
                print("Error creating sampler.")
            }
        }
        else
        {
            print("Error creating default library.")
        }
    }
    
    func createTextureCache()
    {
        var newTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device!, nil, &newTextureCache) == kCVReturnSuccess {
            textureCache = newTextureCache
        }
        else
        {
            assertionFailure("Unable to allocate texture cache")
        }
    }
    
    var DrawingLock = NSObject()
    
    override func draw(_ rect: CGRect)
    {
        //objc_sync_enter(DrawingLock)
        //defer {objc_sync_exit(DrawingLock)}
        //objc_sync_enter(PixelBufferLock)
        //defer {objc_sync_exit(PixelBufferLock)}
        var pixelBuffer: CVPixelBuffer?
        var mirroring = false
        var rotation: Rotation = .rotate0Degrees
        
        SyncQueue.sync
            {
                pixelBuffer = InternalPixelBuffer
                mirroring = InternalMirroring
                rotation = InternalRotation
        }
        
        guard let drawable = currentDrawable,
            let currentRenderPassDescriptor = currentRenderPassDescriptor,
            let previewPixelBuffer = pixelBuffer else
        {
            return
        }
        
        // Create a Metal texture from the image buffer
        let width = CVPixelBufferGetWidth(previewPixelBuffer)
        let height = CVPixelBufferGetHeight(previewPixelBuffer)
        
        if textureCache == nil
        {
            createTextureCache()
        }
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  textureCache!,
                                                  previewPixelBuffer,
                                                  nil,
                                                  .bgra8Unorm,
                                                  width,
                                                  height,
                                                  0,
                                                  &cvTextureOut)
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else
        {
            print("LiveMetalView: Failed to create preview texture")
            
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        if texture.width != textureWidth ||
            texture.height != textureHeight ||
            self.bounds != InternalBounds ||
            mirroring != textureMirroring ||
            rotation != textureRotation {
            setupTransform(width: texture.width, height: texture.height, mirroring: mirroring, rotation: rotation)
        }
        
        // Set up command buffer and encoder
        guard let commandQueue = commandQueue else
        {
            print("Failed to create Metal command queue")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else
        {
            print("Failed to create Metal command buffer")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor) else
        {
            print("Failed to create Metal command encoder")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        commandEncoder.label = "Metal Live View Display"
        commandEncoder.setRenderPipelineState(renderPipelineState!)
        commandEncoder.setVertexBuffer(vertexCoordBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textCoordBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()
        
        commandBuffer.present(drawable) // Draw to the screen
        commandBuffer.commit()
    }
}
