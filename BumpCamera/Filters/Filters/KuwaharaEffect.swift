//
//  KuwaharaEffect.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit

class KuwaharaEffect: FilterParent, Renderer
{
    required override init()
    {
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "KuwaharaKernel")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
    }
        
        var _ID: UUID = UUID(uuidString: "241c7331-bb81-4dbe-983f-bb73209eea85")!
        var ID: UUID
        {
            get
            {
                return _ID
            }
            set
            {
                _ID = newValue
            }
        }
        
        var InstanceID: UUID
        {
            return UUID()
        }
        
        var Description: String = "Kuwahara"
        
        var IconName: String = "Kuwahara"
        
        private let MetalDevice = MTLCreateSystemDefaultDevice()
        
        private var ComputePipelineState: MTLComputePipelineState? = nil
        
        private lazy var CommandQueue: MTLCommandQueue? =
        {
            return self.MetalDevice?.makeCommandQueue()
        }()
        
        private(set) var OutputFormatDescription: CMFormatDescription? = nil
        
        private(set) var InputFormatDescription: CMFormatDescription? = nil
        
        private var BufferPool: CVPixelBufferPool? = nil
        
        var Initialized = false
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    {
        Reset("Kuwahara.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in Kuwahara.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        
        Initialized = true
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in Kuwahara.")
        }
        else
        {
            TextureCache = MetalTextureCache
        }
    }
    
    func Reset(_ CalledBy: String = "")
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        BufferPool = nil
        OutputFormatDescription = nil
        InputFormatDescription = nil
        TextureCache = nil
        Initialized = false
    }
    
    func Reset()
    {
        Reset("")
    }
    
        var AccessLock = NSObject()
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        if !Initialized
        {
            fatalError("Kuwahara not initialized at Render(CVPixelBuffer) call.")
        }
        
        var FinalRadius: Float = 20.0
        if let RawDS = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.Radius)
        {
            if let DS = RawDS as? Double
            {
                FinalRadius = Float(DS)
            }
        }
        let Buffer0 = MetalDevice?.makeBuffer(bytes: &FinalRadius,
                                              length: MemoryLayout<Float>.size,
                                              options: MTLResourceOptions())
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
        guard let OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in KuwaharaEffect.")
            return nil
        }
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: PixelBuffer, textureFormat: .bgra8Unorm),
            let OutputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: OutputBuffer, textureFormat: .bgra8Unorm) else
        {
            print("Error creating textures in KuwaharaEffect.")
            return nil
        }
        
        guard let CommandQ = CommandQueue,
            let CommandBuffer = CommandQ.makeCommandBuffer(),
            let CommandEncoder = CommandBuffer.makeComputeCommandEncoder() else
        {
            print("Error creating Metal command queue.")
            CVMetalTextureCacheFlush(TextureCache!, 0)
            return nil
        }
        
        CommandEncoder.label = "Kuwahara Effect"
        CommandEncoder.setBuffer(Buffer0, offset: 0, index: 0)
        CommandEncoder.setComputePipelineState(ComputePipelineState!)
        CommandEncoder.setTexture(InputTexture, index: 0)
        CommandEncoder.setTexture(OutputTexture, index: 1)
        
        let w = ComputePipelineState!.threadExecutionWidth
        let h = ComputePipelineState!.maxTotalThreadsPerThreadgroup / w
        let ThreadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        let ThreadGroupsPerGrid = MTLSize(width: (InputTexture.width + w - 1) / w,
                                          height: (InputTexture.height + h - 1) / h,
                                          depth: 1)
        CommandEncoder.dispatchThreadgroups(ThreadGroupsPerGrid, threadsPerThreadgroup: ThreadsPerThreadGroup)
        CommandEncoder.endEncoding()
        CommandBuffer.commit()
        
        return OutputBuffer
    }
    
    var ImageDevice: MTLDevice? = nil
    var InitializedForImage = false
    private var ImageComputePipelineState: MTLComputePipelineState? = nil
    private lazy var ImageCommandQueue: MTLCommandQueue? =
    {
        return self.MetalDevice?.makeCommandQueue()
    }()
    
    func InitializeForImage()
    {
        ImageDevice = MTLCreateSystemDefaultDevice()
        let DefaultLibrary = ImageDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "KuwaharaKernel")
        do
        {
            ImageComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
        
        InitializedForImage = true
    }
    
    //http://flexmonkey.blogspot.com/2014/10/metal-kernel-functions-compute-shaders.html
    func Render(Image: UIImage) -> UIImage?
    {
        if !InitializedForImage
        {
            fatalError("Not initialized.")
        }
        let CgImage = Image.cgImage
        let ImageWidth: Int = (CgImage?.width)!
        let ImageHeight: Int = (CgImage?.height)!
        var RawData = [UInt8](repeating: 0, count: Int(ImageWidth * ImageHeight * 4))
        let RGBColorSpace = CGColorSpaceCreateDeviceRGB()
        let BitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let Context = CGContext(data: &RawData, width: ImageWidth, height: ImageHeight, bitsPerComponent: (CgImage?.bitsPerComponent)!,
                                bytesPerRow: (CgImage?.bytesPerRow)!, space: RGBColorSpace, bitmapInfo: BitmapInfo.rawValue)
        Context!.draw(CgImage!, in: CGRect(x: 0, y: 0, width: CGFloat(ImageWidth), height: CGFloat(ImageHeight)))
        let TextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                         width: Int(ImageWidth), height: Int(ImageHeight), mipmapped: true)
        guard let Texture = ImageDevice?.makeTexture(descriptor: TextureDescriptor) else
        {
            print("Error creating input texture in KuwaharaEffect.Render.")
            return nil
        }
        
        let Region = MTLRegionMake2D(0, 0, Int(ImageWidth), Int(ImageHeight))
        Texture.replace(region: Region, mipmapLevel: 0, withBytes: &RawData, bytesPerRow: Int((CgImage?.bytesPerRow)!))
        let OutputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Texture.pixelFormat,
                                                                               width: Texture.width, height: Texture.height, mipmapped: true)
        let OutputTexture = ImageDevice?.makeTexture(descriptor: OutputTextureDescriptor)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(Texture, index: 0)
        CommandEncoder?.setTexture(OutputTexture, index: 1)
        
        var FinalRadius: Float = 20.0
        if let RawDS = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.Radius)
        {
            if let DS = RawDS as? Double
            {
                FinalRadius = Float(DS)
            }
        }
        let Buffer0 = MetalDevice?.makeBuffer(bytes: &FinalRadius,
                                              length: MemoryLayout<Float>.size,
                                              options: MTLResourceOptions())
        CommandEncoder?.setBuffer(Buffer0, offset: 0, index: 0)
        
        let ThreadGroupCount  = MTLSizeMake(8, 8, 1)
        let ThreadGroups = MTLSizeMake(Texture.width / ThreadGroupCount.width,
                                       Texture.height / ThreadGroupCount.height,
                                       1)
        
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        
        CommandEncoder!.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder!.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        
        let ImageSize = CGSize(width: Texture.width, height: Texture.height)
        let ImageByteCount = Int(ImageSize.width * ImageSize.height * 4)
        let BytesPerRow = CgImage?.bytesPerRow
        var ImageBytes = [UInt8](repeating: 0, count: ImageByteCount)
        let ORegion = MTLRegionMake2D(0, 0, Int(ImageSize.width), Int(ImageSize.height))
        OutputTexture?.getBytes(&ImageBytes, bytesPerRow: BytesPerRow!, from: ORegion, mipmapLevel: 0)
        
        let SizeOfUInt8 = UInt8.SizeOf()
        let Provider = CGDataProvider(data: NSData(bytes: &ImageBytes, length: ImageBytes.count * SizeOfUInt8))
        let OBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let RenderingIntent = CGColorRenderingIntent.defaultIntent
        let FinalImage = CGImage(width: Int(ImageSize.width), height: Int(ImageSize.height),
                                 bitsPerComponent: (CgImage?.bitsPerComponent)!, bitsPerPixel: (CgImage?.bitsPerPixel)!,
                                 bytesPerRow: BytesPerRow!, space: RGBColorSpace, bitmapInfo: OBitmapInfo, provider: Provider!,
                                 decode: nil, shouldInterpolate: false, intent: RenderingIntent)
        return UIImage(cgImage: FinalImage!)
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        let UImage = UIImage(ciImage: Image)
        if let IFinal = Render(Image: UImage)
        {
            if let CFinal = IFinal.ciImage
            {
                return CFinal
            }
            else
            {
                print("Error converting UIImage to CIImage in Kuwahara.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in Kuwahara.Render(CIImage)")
            return nil
        }
    }

    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    {
        return (FilterManager.InputTypes.DoubleType, 10.0 as Any?)
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return KuwaharaEffect.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(FilterManager.InputFields.Radius)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return KuwaharaEffect.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "KuwaharaFilterSettingsUI"
    }
    
    func IsSlow() -> Bool
    {
        return true
    }
    
    func FilterTarget() -> [FilterTargets]
    {
        return [.Video, .Still]
    }
}
