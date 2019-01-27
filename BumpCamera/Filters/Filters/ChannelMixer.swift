//
//  ChannelMixer.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage
import simd

class ChannelMixer: FilterParent, Renderer
{
    required override init()
    {
        /*
         let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
         let KernelFunction = DefaultLibrary?.makeFunction(name: "DesaturationKernel")
         do
         {
         ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
         }
         catch
         {
         print("Unable to create pipeline state: \(error.localizedDescription)")
         }
         */
    }
    
    var _ID: UUID = UUID(uuidString: "b49e8644-99be-4492-aecc-f9f4430012fd")!
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
    
    var Description: String = "Channel Mixer"
    
    var IconName: String = "Channel Mixer"
    
    private let MetalDevice = MTLCreateSystemDefaultDevice()
    
    private var ComputePipelineState: MTLComputePipelineState? = nil
    
    private lazy var CommandQueue: MTLCommandQueue? =
    {
        return self.MetalDevice?.makeCommandQueue()
    }()
    
    private(set) var OutputFormatDescription: CMFormatDescription? = nil
    
    private(set) var InputFormatDescription: CMFormatDescription? = nil
    
    private var BufferPool: CVPixelBufferPool? = nil
    
    var ParameterBuffer: MTLBuffer! = nil
    
    var Initialized = false
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    {
        Reset("ChannelMixer.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in ChannelMixer.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        
        Initialized = true
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in ChannelMixer.")
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
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        if !Initialized
        {
            fatalError("ChannelMixer not initialized at Render(CVPixelBuffer) call.")
        }
        
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let RawOutCS = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.OutputColorSpace)
        var OutCS = 0
        if let CS = RawOutCS as? Int
        {
            OutCS = CS
        }
        var KernelName = ""
        switch OutCS
        {
        case 0:
            KernelName = "RGBSwizzling"
            
        case 1:
            KernelName = "HSBSwizzling"
            
        default:
            KernelName = "RGBSwizzling"
        }
        let KernelFunction = DefaultLibrary?.makeFunction(name: KernelName)
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
        
        let (C1, C2, C3) = GetSwizzleValues(OutCS)
        let Parameter = ChannelSwizzles(Channel1: simd_float1(C1), Channel2: simd_float1(C2), Channel3: simd_float1(C3))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ChannelSwizzles>.size, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<ChannelSwizzles>.size)
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
        guard let OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in ChannelMixer.")
            return nil
        }
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: PixelBuffer, textureFormat: .bgra8Unorm),
            let OutputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: OutputBuffer, textureFormat: .bgra8Unorm) else
        {
            print("Error creating textures in ChannelMixer.")
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
        
        CommandEncoder.label = "Channel Mixer"
        CommandEncoder.setComputePipelineState(ComputePipelineState!)
        CommandEncoder.setTexture(InputTexture, index: 0)
        CommandEncoder.setTexture(OutputTexture, index: 1)
        CommandEncoder.setBuffer(ParameterBuffer, offset: 0, index: 0)
        
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
        InitializedForImage = true
    }
    
    func Render(Image: UIImage) -> UIImage?
    {
        if !InitializedForImage
        {
            fatalError("Not initialized.")
        }
        
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        
        let RawOutCS = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.OutputColorSpace)
        var OutCS = 0
        if let CS = RawOutCS as? Int
        {
            OutCS = CS
        }
        var KernelName = ""
        switch OutCS
        {
        case 0:
            KernelName = "RGBSwizzling"
            
        case 1:
            KernelName = "HSBSwizzling"
            
        default:
            KernelName = "RGBSwizzling"
        }
        //print("Using kernel \(KernelName)")
        let KernelFunction = DefaultLibrary?.makeFunction(name: KernelName)
        do
        {
            ImageComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
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
            print("Error creating input texture in DesaturateColors.Render.")
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
        
        let (C1, C2, C3) = GetSwizzleValues(OutCS)
        let Parameter = ChannelSwizzles(Channel1: simd_float1(C1), Channel2: simd_float1(C2), Channel3: simd_float1(C3))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ChannelSwizzles>.size, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<ChannelSwizzles>.size)
        CommandEncoder!.setBuffer(ParameterBuffer, offset: 0, index: 0)
        
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
                print("Error converting UIImage to CIImage in ChannelMixer.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in ChannelMixer.Render(CIImage)")
            return nil
        }
    }
    
    func GetSwizzleValues(_ ColorSpaceIndex: Int) -> (Int, Int, Int)
    {
        var C1: Int = Channels.Red.rawValue
        var C2: Int = Channels.Green.rawValue
        var C3: Int = Channels.Blue.rawValue
        #if false
        var C4: Int = Channels.Black.rawValue
        #endif
        
        var F1: FilterManager.InputFields!
        var F2: FilterManager.InputFields!
        var F3: FilterManager.InputFields!
        
        switch ColorSpaceIndex
        {
        case 0:
            F1 = FilterManager.InputFields.RedChannel
            F2 = FilterManager.InputFields.GreenChannel
            F3 = FilterManager.InputFields.BlueChannel
            
        case 1:
            F1 = FilterManager.InputFields.HueChannel
            F2 = FilterManager.InputFields.SaturationChannel
            F3 = FilterManager.InputFields.BrightnessChannel
            
        default:
            fatalError("Unexpected color space encountered: \(ColorSpaceIndex).")
        }
        
        let RawC1 = ParameterManager.GetField(From: ID, Field: F1)
        if let C1Val = RawC1 as? Int
        {
            C1 = C1Val
        }
        let RawC2 = ParameterManager.GetField(From: ID, Field: F2)
        if let C2Val = RawC2 as? Int
        {
            C2 = C2Val
        }
        let RawC3 = ParameterManager.GetField(From: ID, Field: F3)
        if let C3Val = RawC3 as? Int
        {
            C3 = C3Val
        }
        return (C1, C2, C3)
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.RedChannel)
        Fields.append(.GreenChannel)
        Fields.append(.BlueChannel)
        Fields.append(.HueChannel)
        Fields.append(.SaturationChannel)
        Fields.append(.BrightnessChannel)
        Fields.append(.CyanChannel)
        Fields.append(.MagentaChannel)
        Fields.append(.YellowChannel)
        Fields.append(.BlackChannel)
        Fields.append(.CMYKMap)
        Fields.append(.RGBMap)
        Fields.append(.HSBMap)
        Fields.append(.OutputColorSpace)
        return Fields
    }
    
    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    {
        switch Field
        {
        case .RedChannel:
            return (FilterManager.InputTypes.IntType, 0 as Any?)
            
        case .GreenChannel:
            return (FilterManager.InputTypes.IntType, 1 as Any?)
            
        case .BlueChannel:
            return (FilterManager.InputTypes.IntType, 2 as Any?)
            
        case .HueChannel:
            return (FilterManager.InputTypes.IntType, 3 as Any?)
            
        case .SaturationChannel:
            return (FilterManager.InputTypes.IntType, 4 as Any?)
            
        case .BrightnessChannel:
            return (FilterManager.InputTypes.IntType, 5 as Any?)
      
        case .CyanChannel:
            return (FilterManager.InputTypes.IntType, 6 as Any?)
            
        case .MagentaChannel:
            return (FilterManager.InputTypes.IntType, 7 as Any?)
            
        case .YellowChannel:
            return (FilterManager.InputTypes.IntType, 8 as Any?)
            
        case .BlackChannel:
            return (FilterManager.InputTypes.IntType, 9 as Any?)
            
        case .OutputColorSpace:
            return (FilterManager.InputTypes.IntType, 0 as Any?)
            
        case .RGBMap:
            return (FilterManager.InputTypes.StringType, "R:R,G:G,B:B" as Any?)
            
        case .HSBMap:
            return (FilterManager.InputTypes.StringType, "H:H,S:S,L:L" as Any?)
            
        case .CMYKMap:
            return (FilterManager.InputTypes.StringType, "C:C,M:M,Y:Y,K:K" as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func SettingsStoryboard() -> String?
    {
        return "ChannelMixerTable4"
    }
}

enum Channels: Int
{
    case Red = 0
    case Green = 1
    case Blue = 2
    case Hue = 3
    case Saturation = 4
    case Brightness = 5
    case Cyan = 6
    case Magenta = 7
    case Yellow = 8
    case Black = 9
}

