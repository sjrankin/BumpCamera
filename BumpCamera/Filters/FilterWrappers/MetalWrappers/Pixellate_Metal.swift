//
//  Pixellate_Metal.swift
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

class Pixellate_Metal: FilterParent, Renderer
{
    required override init()
    {
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "PixellateKernel")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    static let _ID: UUID = UUID(uuidString: "ea2602d1-468e-4ff4-a1ea-1299af4b70aa")!
    
    func ID() -> UUID
    {
        return type(of: self)._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    static func Title() -> String
    {
        return "Metal Pixellate"
    }
    
    func Title() -> String
    {
        return type(of: self).Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Metal Pixellate"
    
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
        Reset("Pixellate_Metal.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in Pixellate_Metal.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        
        Initialized = true
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in Pixellate_Metal.")
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
    
    var ParameterBuffer: MTLBuffer? = nil
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        if !Initialized
        {
            fatalError("Pixellate_Metal not initialized at Render(CVPixelBuffer) call.")
        }
        
        //BufferPool is nil - nothing to do (or can do). This probably occurred because the user changed
        //filters out from under us and the video sub-system hadn't quite caught up to the new filter and
        //sent a frame to the no-longer-active filter.
        if BufferPool == nil
        {
            return nil
        }
        
        let Start = CACurrentMediaTime()
        
        let FinalWidth = ParameterManager.GetInt(From: ID(), Field: .BlockWidth, Default: 20)
        let FinalHeight = ParameterManager.GetInt(From: ID(), Field: .BlockHeight, Default: 20)
        let HAction = ParameterManager.GetInt(From: ID(), Field: .PixelHighlightAction, Default: 0)
        let HValue = ParameterManager.GetDouble(From: ID(), Field: .PixelHighlightActionValue, Default: 0.5)
        let HIfGreat = ParameterManager.GetBool(From: ID(), Field: .PixelHighlightActionIfGreater, Default: true)
        let HBy = ParameterManager.GetInt(From: ID(), Field: .PixellationHighlighting, Default: 3)
        let CDet = ParameterManager.GetInt(From: ID(), Field: .BlockColorDetermination, Default: 0)
        let Buffer0 = BlockInfoParameters(Width: simd_uint1(FinalWidth), Height: simd_uint1(FinalHeight),
                                          HighlightAction: simd_uint1(HAction), HighlightPixelBy: simd_uint1(HBy),
                                          BrightnessHighlight: simd_uint1(0),
                                          HighlightColor: UIColor.yellow.ToFloat4(),
                                          ColorDetermination: simd_uint1(CDet), HighlightValue: simd_float1(HValue),
                                          HighlightIfGreater: simd_bool(HIfGreat))
        let Buffers = [Buffer0]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<BlockInfoParameters>.stride, options: [])
        memcpy(ParameterBuffer?.contents(), Buffers, MemoryLayout<BlockInfoParameters>.stride)
        
        let ResultCount = 10
        let ResultsBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ReturnBufferType>.stride * ResultCount, options: [])
        let Results = UnsafeBufferPointer<ReturnBufferType>(start: UnsafePointer(ResultsBuffer!.contents().assumingMemoryBound(to: ReturnBufferType.self)),
                                                            count: ResultCount)
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
        guard var OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in Pixellate_Metal.")
            return nil
        }
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(PixelBuffer: PixelBuffer, TextureFormat: .bgra8Unorm),
            let OutputTexture = MakeTextureFromCVPixelBuffer(PixelBuffer: OutputBuffer, TextureFormat: .bgra8Unorm) else
        {
            print("Error creating textures in Pixellate_Metal.")
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
        
        CommandEncoder.label = "Pixellate Metal"
        CommandEncoder.setComputePipelineState(ComputePipelineState!)
        CommandEncoder.setTexture(InputTexture, index: 0)
        CommandEncoder.setTexture(OutputTexture, index: 1)
        CommandEncoder.setBuffer(ParameterBuffer, offset: 0, index: 0)
        CommandEncoder.setBuffer(ResultsBuffer, offset: 0, index: 1)
        
        let w = ComputePipelineState!.threadExecutionWidth
        let h = ComputePipelineState!.maxTotalThreadsPerThreadgroup / w
        let ThreadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        let ThreadGroupsPerGrid = MTLSize(width: (InputTexture.width + w - 1) / w,
                                          height: (InputTexture.height + h - 1) / h,
                                          depth: 1)
        CommandEncoder.dispatchThreadgroups(ThreadGroupsPerGrid, threadsPerThreadgroup: ThreadsPerThreadGroup)
        CommandEncoder.endEncoding()
        CommandBuffer.commit()
        
        if ParameterManager.GetBool(From: ID(), Field: .MergeWithBackground, Default: false)
        {
            let MaskFilter = Masking1()
            MaskFilter.Initialize(With: InputFormatDescription!, BufferCountHint: 3)
            OutputBuffer = MaskFilter.RenderWith(PixelBuffer: PixelBuffer, And: OutputBuffer)!
        }
        
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
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
        let KernelFunction = DefaultLibrary?.makeFunction(name: "PixellateKernel")
        do
        {
            ImageComputePipelineState = try MetalDevice!.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
        
        InitializedForImage = true
    }
    
    var ImageParameterBuffer: MTLBuffer? = nil
    
    //http://flexmonkey.blogspot.com/2014/10/metal-kernel-functions-compute-shaders.html
    func Render(Image: UIImage) -> UIImage?
    {
        if !InitializedForImage
        {
            fatalError("Not initialized.")
        }
        
        let Start = CACurrentMediaTime()
        var CgImage = Image.cgImage
        #if true
        CgImage = AdjustForMonochrome(Image: CgImage!)
        #else
        let ImageColorspace = CgImage?.colorSpace
        //Handle sneaky grayscale images.
        if ImageColorspace?.model == CGColorSpaceModel.monochrome
        {
            let NewColorSpace = CGColorSpaceCreateDeviceRGB()
            let NewBMInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
            let IWidth: Int = Int((CgImage?.width)!)
            let IHeight: Int = Int((CgImage?.height)!)
            var RawData = [UInt8](repeating: 0, count: Int(IWidth * IHeight * 4))
            let GContext = CGContext(data: &RawData, width: IWidth, height: IHeight,
                                     bitsPerComponent: 8, bytesPerRow: 4 * IWidth,
                                     space: NewColorSpace, bitmapInfo: NewBMInfo.rawValue)
            let ImageRect = CGRect(x: 0, y: 0, width: IWidth, height: IHeight)
            GContext!.draw(CgImage!, in: ImageRect)
            CgImage = GContext!.makeImage()
        }
        #endif
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
            print("Error creating input texture in Pixellate_Metal.Render.")
            return nil
        }
        
        let ResultCount = 10
        let ResultsBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ReturnBufferType>.stride * ResultCount, options: [])
        let Results = UnsafeBufferPointer<ReturnBufferType>(start: UnsafePointer(ResultsBuffer!.contents().assumingMemoryBound(to: ReturnBufferType.self)),
                                                            count: ResultCount)
        
        let Region = MTLRegionMake2D(0, 0, Int(ImageWidth), Int(ImageHeight))
        Texture.replace(region: Region, mipmapLevel: 0, withBytes: &RawData, bytesPerRow: Int((CgImage?.bytesPerRow)!))
        let OutputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Texture.pixelFormat,
                                                                               width: Texture.width, height: Texture.height, mipmapped: true)
        OutputTextureDescriptor.usage = .shaderWrite
        let OutputTexture = ImageDevice?.makeTexture(descriptor: OutputTextureDescriptor)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(Texture, index: 0)
        CommandEncoder?.setTexture(OutputTexture, index: 1)
        CommandEncoder?.setBuffer(ResultsBuffer, offset: 0, index: 1)
        
        let FinalWidth = ParameterManager.GetInt(From: ID(), Field: .BlockWidth, Default: 20)
        let FinalHeight = ParameterManager.GetInt(From: ID(), Field: .BlockHeight, Default: 20)
        let HAction = ParameterManager.GetInt(From: ID(), Field: .PixelHighlightAction, Default: 3)
        let HValue = ParameterManager.GetDouble(From: ID(), Field: .PixelHighlightActionValue, Default: 0.5)
        let HIfGreat = ParameterManager.GetBool(From: ID(), Field: .PixelHighlightActionIfGreater, Default: true)
        let HBy = ParameterManager.GetInt(From: ID(), Field: .PixellationHighlighting, Default: 3)
                let CDet = ParameterManager.GetInt(From: ID(), Field: .BlockColorDetermination, Default: 0)
        let Buffer0 = BlockInfoParameters(Width: simd_uint1(FinalWidth), Height: simd_uint1(FinalHeight),
                                          HighlightAction: simd_uint1(HAction), HighlightPixelBy: simd_uint1(HBy),
                                          BrightnessHighlight: simd_uint1(0),
                                          HighlightColor: UIColor.yellow.ToFloat4(),
                                          ColorDetermination: simd_uint1(CDet), HighlightValue: simd_float1(HValue),
                                          HighlightIfGreater: simd_bool(HIfGreat))
        let Buffers = [Buffer0]
        ImageParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<BlockInfoParameters>.stride, options: [])
        memcpy(ImageParameterBuffer?.contents(), Buffers, MemoryLayout<BlockInfoParameters>.stride)
        CommandEncoder!.setBuffer(ImageParameterBuffer, offset: 0, index: 0)
        
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
        
        if ParameterManager.GetBool(From: ID(), Field: .MergeWithBackground, Default: false)
        {
            let MaskFilter = Masking1()
            MaskFilter.InitializeForImage()
            let BottomImage = LastUIImage!
            LastUIImage = MaskFilter.RenderWith(Images: [BottomImage, Image])!
        }
        
        ImageRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: true)
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
                print("Error converting UIImage to CIImage in Pixellate_Metal.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in Pixellate_Metal.Render(CIImage)")
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
        case .BlockWidth:
            return (.IntType, 20 as Any?)
            
        case .PixelHighlightAction:
            return (.IntType, 0 as Any?)
            
        case .BlockHeight:
            return (.IntType, 20 as Any?)
            
        case .PixellationHighlighting:
            return (.IntType, 3 as Any?)
            
        case .PixelHighlightActionValue:
            return (.DoubleType, 0.5 as Any?)
            
        case .PixelHighlightActionIfGreater:
            return (.BoolType, true as Any?)
            
        case .HighlightColor:
            return (.BoolType, false as Any?)
            
        case .HighlightSaturation:
            return (.BoolType, false as Any?)
            
        case .HighlightBrightness:
            return (.BoolType, false as Any?)
            
        case .MergeWithBackground:
            return (.BoolType, false as Any?)
            
        case .ConditionalPixellation:
            return (.BoolType, false as Any?)
            
        case .InvertConditionalPixellationRange:
            return (.BoolType, false as Any?)
            
        case .ConditionalPixellationSelector:
            return (.IntType, 0 as Any?)
            
        case .ConditionalHueRangeLow:
            return (.DoubleType, 0.25 as Any?)
            
        case .ConditionalHueRangeHigh:
            return (.DoubleType, 0.75 as Any?)
            
        case .ConditionalSaturation:
            return (.DoubleType, 0.5 as Any?)
            
        case .ConditionalBrightness:
            return (.DoubleType, 0.5 as Any?)
            
        case .ConditionalBackground:
            return (.IntType, 0 as Any?)
            
        case .RenderImageCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeImageRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .RenderLiveCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeLiveRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        default:
            break
        }
        return (FilterManager.InputTypes.NoType, nil)
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return type(of: self).SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.PixelHighlightActionIfGreater)
        Fields.append(.PixellationHighlighting)
        Fields.append(.PixelHighlightAction)
        Fields.append(.PixelHighlightActionValue)
        Fields.append(.BlockWidth)
        Fields.append(.BlockHeight)
        Fields.append(.HighlightColor)
        Fields.append(.HighlightSaturation)
        Fields.append(.HighlightBrightness)
        Fields.append(.MergeWithBackground)
        Fields.append(.ConditionalPixellation)
        Fields.append(.InvertConditionalPixellationRange)
        Fields.append(.ConditionalHueRangeLow)
        Fields.append(.ConditionalHueRangeHigh)
        Fields.append(.ConditionalBrightness)
        Fields.append(.ConditionalSaturation)
        Fields.append(.ConditionalBackground)
        Fields.append(.RenderImageCount)
        Fields.append(.CumulativeImageRenderDuration)
        Fields.append(.RenderLiveCount)
        Fields.append(.CumulativeLiveRenderDuration)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return type(of: self).SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "Pixellate2SettingsUI"
    }
    
    func IsSlow() -> Bool
    {
        return true
    }
    
    public static func FilterTarget() -> [FilterTargets]
    {
        return [.LiveView, .Video, .Still]
    }
    
    func FilterTarget() -> [FilterTargets]
    {
        return Pixellate_Metal.FilterTarget()
    }
    
    private var ImageRenderTime: Double = 0.0
    private var LiveRenderTime: Double = 0.0
    
    /// Return the rendering time for the most recent image or live view render. Optionally reset the saved render
    /// time. Render time is from start of function call to return, not just kernel/filter time. One data point isn't
    /// terribly useful so be sure to collect several hundred in different environmental conditions to get a good idea
    /// of the actual rendering time.
    ///
    /// - Parameters:
    ///   - ForImage: If true, return the render time for the last image rendered. If false, return the render time
    ///               for the last live view frame rendered.
    ///   - Reset: If true, the render time is reset to 0.0 for the type of data being returned.
    /// - Returns: The number of seconds it took to render the for the type of data specified by ForImage.
    public func RenderTime(ForImage: Bool, Reset: Bool = false) -> Double
    {
        let Final = ForImage ? ImageRenderTime : LiveRenderTime
        if Reset
        {
            if ForImage
            {
                ParameterManager.SetField(To: ID(), Field: .RenderImageCount, Value: 0)
                ParameterManager.SetField(To: ID(), Field: .CumulativeImageRenderDuration, Value: 0.0)
            }
            else
            {
                ParameterManager.SetField(To: ID(), Field: .RenderLiveCount, Value: 0)
                ParameterManager.SetField(To: ID(), Field: .CumulativeLiveRenderDuration, Value: 0.0)
            }
        }
        return Final
    }
    
    /// Returns a list of strings intended to be used as key words in Exif data.
    ///
    /// - Returns: List of key words associated with the filter, including setting values.
    func ExifKeyWords() -> [String]
    {
        var Keywords = [String]()
        Keywords.append("Filter: PixellateKernel")
        Keywords.append("FilterType: Metal Kernel")
        Keywords.append("FilterID: \(ID().uuidString)")
        return Keywords
    }
    
    /// Returns a dictionary of Exif key-value pairs. Intended for use for inclusion in image Exif data.
    ///
    /// - Returns: Dictionary of key-value data for top-level Exif data.
    func ExifKeyValues() -> [String: String]
    {
        return [String: String]()
    }
    
    var FilterKernel: FilterManager.FilterKernelTypes
    {
        get
        {
            return type(of: self).FilterKernel
        }
    }
    
    static var FilterKernel: FilterManager.FilterKernelTypes
    {
        get
        {
            return FilterManager.FilterKernelTypes.Metal
        }
    }
    
    /// Describes the available ports for the filter. Static version.
    ///
    /// - Returns: Array of ports.
    static func Ports() -> [FilterPorts]
    {
        return [FilterPorts.Input, FilterPorts.Output]
    }
    
    /// Describes the available ports for the filter.
    ///
    /// - Returns: Array of ports.
    func Ports() -> [FilterPorts]
    {
        return type(of: self).Ports()
    }
}
