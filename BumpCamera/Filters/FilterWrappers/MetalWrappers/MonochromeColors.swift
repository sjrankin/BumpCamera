//
//  MonochromeColors.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import UIKit
import CoreMedia
import CoreVideo
import MetalKit

class MonochromeColors: FilterParent, Renderer
{
    required override init()
    {
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "MonochromeColorsKernel")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    static let _ID: UUID = UUID(uuidString: "2ea4460a-e126-4d5a-b747-6f31a62b41e7")!
    
    func ID() -> UUID
    {
        return MonochromeColors._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Monochrome Colors"
    
    var IconName: String = "Monochrome Colors"
    
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
        Reset("MonochromeColors.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in MonochromeColors.Initialize.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        
        Initialized = true
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in MonochromeColors.Initialize.")
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
    
    var ParameterBuffer: MTLBuffer! = nil
    var PreviousDebug = ""
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        if !Initialized
        {
            fatalError("MonochromeColors.Initialize not initialized at Render(CVPixelBuffer) call.")
        }
        
        //BufferPool is nil - nothing to do (or can do). This probably occurred because the user changed
        //filters out from under us and the video sub-system hadn't quite caught up to the new filter and
        //sent a frame to the no-longer-active filter.
        if BufferPool == nil
        {
            return nil
        }
        
        let UseBright = ParameterManager.GetSimdBool(From: ID(), Field: .BrightChannels, Default: true)
        let ForRed = ParameterManager.GetSimdBool(From: ID(), Field: .ForRed, Default: true)
        let ForGreen = ParameterManager.GetSimdBool(From: ID(), Field: .ForGreen, Default: true)
        let ForBlue = ParameterManager.GetSimdBool(From: ID(), Field: .ForBlue, Default: true)
        let ForCyan = ParameterManager.GetSimdBool(From: ID(), Field: .ForCyan, Default: true)
        let ForMagenta = ParameterManager.GetSimdBool(From: ID(), Field: .ForMagenta, Default: true)
        let ForYellow = ParameterManager.GetSimdBool(From: ID(), Field: .ForYellow, Default: true)
        let ForBlack = ParameterManager.GetSimdBool(From: ID(), Field: .ForBlack, Default: true)
        let HueSegmentCount = ParameterManager.GetUInt1(From: ID(), Field: .HueSegmentCount, Default: 10)
        let SelectedSegment = ParameterManager.GetUInt1(From: ID(), Field: .HueSelectedSegment, Default: 0)
        let Colorspace = ParameterManager.GetUInt1(From: ID(), Field: .MonochromeColorspace, Default: 0)
        let Parameter = MonochromeColorParameters(Colorspace: Colorspace, ForBright: UseBright,
                                                  ForRed: ForRed, ForGreen: ForGreen, ForBlue: ForBlue,
                                                  ForCyan: ForCyan, ForMagenta: ForMagenta, ForYellow: ForYellow, ForBlack: ForBlack,
                                                  HueSegmentCount: HueSegmentCount, SelectedIndex: SelectedSegment)
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<MonochromeColorParameters>.size, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<MonochromeColorParameters>.size)
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
        guard let OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in MonochromeColors.Initialize.")
            return nil
        }
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: PixelBuffer, textureFormat: .bgra8Unorm),
            let OutputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: OutputBuffer, textureFormat: .bgra8Unorm) else
        {
            print("Error creating textures in MonochromeColors.Initialize.")
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
        
        CommandEncoder.label = "Monochrome Colors Kernel"
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
        let DefaultLibrary = ImageDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "MonochromeColorsKernel")
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
            print("Error creating input texture in MonochromeColors.Initialize.Render.")
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
        
        let UseBright = ParameterManager.GetSimdBool(From: ID(), Field: .BrightChannels, Default: true)
        let ForRed = ParameterManager.GetSimdBool(From: ID(), Field: .ForRed, Default: true)
        let ForGreen = ParameterManager.GetSimdBool(From: ID(), Field: .ForGreen, Default: true)
        let ForBlue = ParameterManager.GetSimdBool(From: ID(), Field: .ForBlue, Default: true)
        let ForCyan = ParameterManager.GetSimdBool(From: ID(), Field: .ForCyan, Default: true)
        let ForMagenta = ParameterManager.GetSimdBool(From: ID(), Field: .ForMagenta, Default: true)
        let ForYellow = ParameterManager.GetSimdBool(From: ID(), Field: .ForYellow, Default: true)
        let ForBlack = ParameterManager.GetSimdBool(From: ID(), Field: .ForBlack, Default: true)
        let HueSegmentCount = ParameterManager.GetUInt1(From: ID(), Field: .HueSegmentCount, Default: 10)
        let SelectedSegment = ParameterManager.GetUInt1(From: ID(), Field: .HueSelectedSegment, Default: 0)
        let Colorspace = ParameterManager.GetUInt1(From: ID(), Field: .MonochromeColorspace, Default: 0)
        let Parameter = MonochromeColorParameters(Colorspace: Colorspace, ForBright: UseBright,
                                                  ForRed: ForRed, ForGreen: ForGreen, ForBlue: ForBlue,
                                                  ForCyan: ForCyan, ForMagenta: ForMagenta, ForYellow: ForYellow, ForBlack: ForBlack,
                                                  HueSegmentCount: HueSegmentCount, SelectedIndex: SelectedSegment)
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<MonochromeColorParameters>.size, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<MonochromeColorParameters>.size)
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
        LastUIImage = UIImage(cgImage: FinalImage!)
        return UIImage(cgImage: FinalImage!)
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        let UImage = UIImage(ciImage: Image)
        if let IFinal = Render(Image: UImage)
        {
            if let CFinal = IFinal.ciImage
            {
                LastCIImage = CFinal
                return CFinal
            }
            else
            {
                print("Error converting UIImage to CIImage in MonochromeColors.Initialize.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in MonochromeColors.Render(CIImage)")
            return nil
        }
    }
    
    var LastUIImage: UIImage? = nil
    var LastCIImage: CIImage? = nil
    
    func LastImageRendered(AsUIImage: Bool) -> Any?
    {
        if AsUIImage
        {
            return LastUIImage as Any?
        }
        else
        {
            return LastCIImage as Any?
        }
    }
    
    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    {
        switch Field
        {
        case .BrightChannels:
            return (.BoolType, true as Any?)
            
        case .ForRed:
            return (.BoolType, true as Any?)
            
        case .ForGreen:
            return (.BoolType, true as Any?)
            
        case .ForBlue:
            return (.BoolType, true as Any?)
            
        case .ForCyan:
            return (.BoolType, true as Any?)
            
        case .ForMagenta:
            return (.BoolType, true as Any?)
            
        case .ForYellow:
            return (.BoolType, true as Any?)
            
        case .ForBlack:
            return (.BoolType, false as Any?)
            
        case .HueSegmentCount:
            return (.IntType, 10 as Any?)
            
        case .MonochromeColorspace:
            return (.IntType, 0 as Any?)
            
        case .HueSelectedSegment:
            return (.IntType, 0 as Any?)
            
        default:
            return (.NoType, nil)
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return MonochromeColors.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.BrightChannels)
        Fields.append(.MonochromeColorspace)
        Fields.append(.ForRed)
        Fields.append(.ForGreen)
        Fields.append(.ForBlue)
        Fields.append(.ForCyan)
        Fields.append(.ForMagenta)
        Fields.append(.ForYellow)
        Fields.append(.ForBlack)
        Fields.append(.HueSegmentCount)
        Fields.append(.HueSelectedSegment)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return MonochromeColors.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "MonochromeColorsSettingsUI"
    }
    
    func IsSlow() -> Bool
    {
        return false
    }
    
    func FilterTarget() -> [FilterTargets]
    {
        return [.LiveView, .Video, .Still]
    }
}
