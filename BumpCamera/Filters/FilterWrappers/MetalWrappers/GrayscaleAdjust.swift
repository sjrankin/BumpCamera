//
//  GrayscaleAdjust.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit

class GrayscaleAdjust: FilterParent, Renderer
{
    required override init()
    {
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "GrayscaleKernel")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    static let _ID: UUID = UUID(uuidString: "6a76fc03-e4e4-4192-82b6-40cf8e520861")!
    
    func ID() -> UUID
    {
        return GrayscaleAdjust._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    static func Title() -> String
    {
        return "Grayscale"
    }
    
    func Title() -> String
    {
        return GrayscaleAdjust.Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Grayscale"
    
    var IconName: String = "Grayscale"
    
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
        Reset("GrayscaleAdjust.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in GrayscaleAdjust.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        
        Initialized = true
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in GrayscaleAdjust.")
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
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        if !Initialized
        {
            fatalError("GrayscaleAdjust not initialized at Render(CVPixelBuffer) call.")
        }
        
        //BufferPool is nil - nothing to do (or can do). This probably occurred because the user changed
        //filters out from under us and the video sub-system hadn't quite caught up to the new filter and
        //sent a frame to the no-longer-active filter.
        if BufferPool == nil
        {
            return nil
        }
        
        let Start = CACurrentMediaTime()
        let FinalCommand = ParameterManager.GetInt(From: ID(), Field: .Command, Default: 0)
        let RMul = ParameterManager.GetDouble(From: ID(), Field: .RAdjustment, Default: 0.3)
        let GMul = ParameterManager.GetDouble(From: ID(), Field: .GAdjustment, Default: 0.5)
        let BMul = ParameterManager.GetDouble(From: ID(), Field: .BAdjustment, Default: 0.2)
        let Parameter = GrayscaleParameters(Command: simd_int1(FinalCommand), RMultiplier: simd_float1(RMul),
                                            GMultiplier: simd_float1(GMul), BMultiplier: simd_float1(BMul))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<GrayscaleParameters>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<GrayscaleParameters>.stride)
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
        guard let OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in GrayscaleAdjust.")
            return nil
        }
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: PixelBuffer, textureFormat: .bgra8Unorm),
            let OutputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: OutputBuffer, textureFormat: .bgra8Unorm) else
        {
            print("Error creating textures in GrayscaleAdjust.")
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
        
        CommandEncoder.label = "Grayscale Kernel"
        CommandEncoder.setComputePipelineState(ComputePipelineState!)
        CommandEncoder.setTexture(InputTexture, index: 0)
        CommandEncoder.setTexture(OutputTexture, index: 1)
        CommandEncoder.setBuffer(ParameterBuffer, offset: 0, index: 0)
        /*
        let ReturnBufferCount = 10
        let ReturnBufferData = [Float](repeating: 0, count: ReturnBufferCount)
        let ReturnBufferLength = ReturnBufferCount * MemoryLayout<Float>.stride
        let ReturnBuffer = MetalDevice?.makeBuffer(bytes: ReturnBufferData, length: ReturnBufferLength, options: [])
        CommandEncoder.setBuffer(ReturnBuffer, offset: 0, index: 1)
        */
        let w = ComputePipelineState!.threadExecutionWidth
        let h = ComputePipelineState!.maxTotalThreadsPerThreadgroup / w
        let ThreadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        let ThreadGroupsPerGrid = MTLSize(width: (InputTexture.width + w - 1) / w,
                                          height: (InputTexture.height + h - 1) / h,
                                          depth: 1)
        CommandEncoder.dispatchThreadgroups(ThreadGroupsPerGrid, threadsPerThreadgroup: ThreadsPerThreadGroup)
        CommandEncoder.endEncoding()
        CommandBuffer.commit()
        CommandBuffer.waitUntilCompleted()
        /*
        let Result = ReturnBuffer?.contents().bindMemory(to: Float.self, capacity: ReturnBufferCount)
        var Values = [Float](repeating: 0, count: ReturnBufferCount)
        for i in 0 ..< ReturnBufferCount
        {
            Values[i] = Result![i]
        }
        */
        
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
        let KernelFunction = DefaultLibrary?.makeFunction(name: "GrayscaleKernel")
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
        
        let Start = CACurrentMediaTime()
        var CgImage = Image.cgImage
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
            print("Error creating input texture in GrayscaleAdjust.Render.")
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
        
        let FinalCommand = ParameterManager.GetInt(From: ID(), Field: .Command, Default: 0)
        let RMul = ParameterManager.GetDouble(From: ID(), Field: .RAdjustment, Default: 0.3)
        let GMul = ParameterManager.GetDouble(From: ID(), Field: .GAdjustment, Default: 0.5)
        let BMul = ParameterManager.GetDouble(From: ID(), Field: .BAdjustment, Default: 0.2)
        let Parameter = GrayscaleParameters(Command: simd_int1(FinalCommand), RMultiplier: simd_float1(RMul),
                                            GMultiplier: simd_float1(GMul), BMultiplier: simd_float1(BMul))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<GrayscaleParameters>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<GrayscaleParameters>.stride)
        CommandEncoder!.setBuffer(ParameterBuffer, offset: 0, index: 0)
        /*
        let ReturnBufferCount = 10
        let ReturnBufferData = [Float](repeating: 0, count: ReturnBufferCount)
        let ReturnBufferLength = ReturnBufferCount * MemoryLayout<Float>.stride
        let ReturnBuffer = ImageDevice?.makeBuffer(bytes: ReturnBufferData, length: ReturnBufferLength, options: [])
        CommandEncoder?.setBuffer(ReturnBuffer, offset: 0, index: 1)
        */
        let ThreadGroupCount  = MTLSizeMake(8, 8, 1)
        let ThreadGroups = MTLSizeMake(Texture.width / ThreadGroupCount.width,
                                       Texture.height / ThreadGroupCount.height,
                                       1)
        
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        
        CommandEncoder!.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder!.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        /*
        let Result = ReturnBuffer?.contents().bindMemory(to: Float.self, capacity: ReturnBufferCount)
        var Values = [Float](repeating: 0, count: ReturnBufferCount)
        for i in 0 ..< 10
        {
            Values[i] = Result![i]
            print("\(i): \(Values[i])")
        }
        */
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
        
        ImageRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: ImageRenderTime, ID: ID(), ForImage: true)
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
                print("Error converting UIImage to CIImage in GrayscaleAdjust.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in GrayscaleAdjust.Render(CIImage)")
            return nil
        }
    }
    
    /// Returns the generated image. If the filter does not support generated images nil is returned.
    ///
    /// - Returns: Nil is always returned.
    func Generate() -> CIImage?
    {
        return nil
    }
    
    func Query(PixelBuffer: CVPixelBuffer, Parameters: [String: Any]) -> [String: Any]?
    {
        return nil
    }
    
    func Query(Image: UIImage, Parameters: [String: Any]) -> [String: Any]?
    {
        return nil
    }
    
    func Query(Image: CIImage, Parameters: [String: Any]) -> [String: Any]?
    {
        return nil
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
        case .Command:
            return (.IntType, 0 as Any?)
            
        case .RAdjustment:
            return (.DoubleType, 0.3 as Any?)
            
        case .GAdjustment:
            return (.DoubleType, 0.5 as Any?)
            
        case .BAdjustment:
            return (.DoubleType, 0.2 as Any?)
            
        case .RenderImageCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeImageRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .RenderLiveCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeLiveRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        default:
            return (.NoType, nil)
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return GrayscaleAdjust.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.Command)
        Fields.append(.RAdjustment)
        Fields.append(.GAdjustment)
        Fields.append(.BAdjustment)
        Fields.append(.RenderImageCount)
        Fields.append(.CumulativeImageRenderDuration)
        Fields.append(.RenderLiveCount)
        Fields.append(.CumulativeLiveRenderDuration)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return GrayscaleAdjust.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "GrayscaleSettingsUI"
    }
    
    public static func GrayscaleTypeTitle(For: GrayscaleTypes) -> String
    {
        switch For
        {
        case .Mean:
            return "Mean"
            
        case .Red:
            return "Red Channel"
            
        case .Green:
            return "Green Channel"
            
        case .Blue:
            return "Blue Channel"
            
        case .Luma:
            return "Luminance"
            
        case .BT601:
            return "BT.601"
            
        case .BT709:
            return "BT.709"
            
        case .Desaturation:
            return "Desaturation"
            
        case .MaxDecomposition:
            return "Max Decomposition"
            
        case .MinDecomposition:
            return "Min Decomposition"
            
        case .Cyan:
            return "Cyan Channel"
            
        case .Magenta:
            return "Magenta Channel"
            
        case .Yellow:
            return "Yellow Channel"
            
        case .Hue:
            return "Hue Channel"
            
        case .Saturation:
            return "Saturation Channel"
            
        case .Brightness:
            return "Brightness Channel"
            
        case .MeanCMYK:
            return "Mean CMYK Value"
            
        case .MeanHSB:
            return "Mean HSB Value"
            
        case .CMYK_C:
            return "CMYK Cyan"
            
        case .CMYK_M:
            return "CMYK Magenta"
            
        case .CMYK_Y:
            return "CMYK Yellow"
            
        case .CMYK_K:
            return "CMYK Black"
            
        case .ByParameters:
            return "User Parameters"
        }
    }
    
    public static func GrayscaleTypeDescription(For: GrayscaleTypes) -> String
    {
        switch For
        {
        case .Mean:
            return "Mean of the color channels: gray = (red + green + blue) / 3"
            
        case .Red:
            return "The red channel value used for all color channels."
            
        case .Green:
            return "The green channel value used for all color channels."
            
        case .Blue:
            return "The blue channel value used for all color channels."
            
        case .Luma:
            return "Early correction for human eyes: gray = (red * 0.3) + (green * 0.59)  + (blue * 0.11)"
            
        case .BT601:
            return "BT.601 for human eyes: gray = (red * 0.299) + (green * 0.587)  + (blue * 0.114)"
            
        case .BT709:
            return "BT.709 for human eyes: gray = (red * 0.2126) + (green * 0.7152)  + (blue * 0.0722)"
            
        case .Desaturation:
            return "Desaturate the color until it is set to 0."
            
        case .MaxDecomposition:
            return "Maximum decomposition: gray = max(red, green, blue)"
            
        case .MinDecomposition:
            return "Minimum decomposition: gray = min(red, green, blue)"
            
        case .Cyan:
            return "Mean of the cyan channels: gray = (green + blue) / 2"
            
        case .Magenta:
            return "Mean of the magenta channels: gray = (red + blue) / 2"
            
        case .Yellow:
            return "Mean of the yellow channels: gray = (red + green) / 2"
            
        case .Hue:
            return "The hue channel from the conversion to HSB."
            
        case .Saturation:
            return "The saturation channel from the conversion to HSB."
            
        case .Brightness:
            return "The brightness channel from the conversion to HSB. Also known as the brightness map."
            
        case .MeanCMYK:
            return "The mean CMYK channel value propagated to the red, green, and blue channels."
            
        case .MeanHSB:
            return "The mean HSB value propagate to the red, green, and blue channels."
            
        case .CMYK_C:
            return "The cyan channel after color is converted to CMYK. Propagated to the red, green, and blue channels."
            
        case .CMYK_M:
            return "The magenta channel after color is converted to CMYK. Propagated to the red, green, and blue channels."
            
        case .CMYK_Y:
            return "The yellow channel after color is converted to CMYK. Propagated to the red, green, and blue channels."
            
        case .CMYK_K:
            return "The black channel after color is converted to CMYK. Propagated to the red, green, and blue channels."
            
        case .ByParameters:
            return "Enter values below to multiply against the red, green, and blue channels. Values must add up to 1.0 or no action will be taken."
        }
    }
    
    public static func GrayscaleTypesInOrder() -> [GrayscaleTypes]
    {
        return [.Mean, .Luma, .Desaturation, .BT601, .BT709, .MaxDecomposition, .MinDecomposition,
                .Red, .Green, .Blue, .Cyan, .Magenta, .Yellow, .CMYK_C, .CMYK_M, .CMYK_Y, .CMYK_K,
                .Hue, .Saturation, .Brightness, .MeanCMYK, .MeanHSB, .ByParameters]
    }
    
    public static func GetGrayscaleTypeFromCommandIndex(_ Index: Int) -> GrayscaleTypes
    {
        return GrayscaleTypes(rawValue: Index)!
    }
    
    func IsSlow() -> Bool
    {
        return false
    }
    
    public static func FilterTarget() -> [FilterTargets]
    {
        return [.LiveView, .Video, .Still]
    }
    
    func FilterTarget() -> [FilterTargets]
    {
        return GrayscaleAdjust.FilterTarget()
    }
    
    private var ImageRenderStart: Double = 0.0
    private var LiveRenderStart: Double = 0.0
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
        Keywords.append("Filter: GrayscaleKernel")
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
            return GrayscaleAdjust.FilterKernel
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
        return GrayscaleAdjust.Ports()
    }
}

/// Types of grayscale conversions supported by this filter.
///
/// - Mean: Takes the mean of the RGB channels.
/// - Red: Propagates the red channel to the green and blue channels.
/// - Green: Propagates the green channel to the red and blue channels.
/// - Blue: Propagates the blue channel to the red and green channels.
/// - Luma: Luminance of the color.
/// - BT601: BT601 standard.
/// - BT709: BT709 standard.
/// - Desaturation: Desaturates the color to 0 saturation.
/// - MaxDecomposition: Maximum of the RGB channels propagated to the other channels.
/// - MinDecomposition: Minimum of the RGB channels propagated to the other channels.
/// - Cyan: Propagates the cyan channel to the red, green, and blue channels.
/// - Magenta: Propagates the magenta channel to the red, green, and blue channels.
/// - Yellow: Propagates the yellow channel to the red, green, and blue channels.
/// - Hue: Propagates the color's hue value to the red, green, and blue channels.
/// - Saturation: Propagates the saturation value to the red, green, and blue channels.
/// - Brightness: Propagates the brightness value to the red, geen, and blue channels.
/// - MeanCMYK: Propagates the mean of the CMYK channels to the red, green, and blue channels.
/// - MeanHSB: Propagates the mean of the HSB values to the red, green, and blue channels.
/// - CMYK_C: Cyan channel after conversion to CMYK colorspace.
/// - CMYK_M: Magenta channel after conversion to CMYK colorspace.
/// - CMYK_Y: Yellow channel after conversion to CMYK colorspace.
/// - CMYK_K: Black channel after conversion to CMYK colorspace.
/// - ByParameters: Use user parameters to as multiplicative value against the red, green, and blue chanels.
enum GrayscaleTypes: Int
{
    case Mean = 0
    case Red = 1
    case Green = 2
    case Blue = 3
    case Luma = 4
    case BT601 = 5
    case BT709 = 6
    case Desaturation = 7
    case MaxDecomposition = 8
    case MinDecomposition = 9
    case Cyan = 10
    case Magenta = 11
    case Yellow = 12
    case Hue = 13
    case Saturation = 14
    case Brightness = 15
    case MeanCMYK = 16
    case MeanHSB = 17
    case CMYK_C = 18
    case CMYK_M = 19
    case CMYK_Y = 20
    case CMYK_K = 21
    case ByParameters = 100
}
