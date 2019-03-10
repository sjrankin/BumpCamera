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
    
    static let _ID: UUID = UUID(uuidString: "b49e8644-99be-4492-aecc-f9f4430012fd")!
    
    func ID() -> UUID
    {
        return ChannelMixer._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    static func Title() -> String
    {
        return "Channel Mixer"
    }
    
    func Title() -> String
    {
        return ChannelMixer.Title()
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
        
        //BufferPool is nil - nothing to do (or can do). This probably occurred because the user changed
        //filters out from under us and the video sub-system hadn't quite caught up to the new filter and
        //sent a frame to the no-longer-active filter.
        if BufferPool == nil
        {
            return nil
        }
        
        let Start = CACurrentMediaTime()
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "HSBSwizzling")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
        
        let (C1, C2, C3) = GetSwizzleValues()
        var IsHSB = false
        if ChannelIsInHSB(Channel: C1) || ChannelIsInHSB(Channel: C2) || ChannelIsInHSB(Channel: C3)
        {
            IsHSB = true
        }
        var IsCMYK = false
        if ChannelIsInCMYK(Channel: C1) || ChannelIsInCMYK(Channel: C2) || ChannelIsInCMYK(Channel: C3)
        {
            IsCMYK = true
        }
        let InvertRed = ParameterManager.GetBool(From: ID(), Field: .InvertRed, Default: false)
        let InvertGreen = ParameterManager.GetBool(From: ID(), Field: .InvertGreen, Default: false)
        let InvertBlue = ParameterManager.GetBool(From: ID(), Field: .InvertBlue, Default: false)
        let Parameter = ChannelSwizzles(Channel1: simd_int1(C1), Channel2: simd_int1(C2), Channel3: simd_int1(C3),
                                        HasHSB: simd_bool(IsHSB), HasCMYK: simd_bool(IsCMYK),
                                        InvertRed: simd_bool(InvertRed), InvertGreen: simd_bool(InvertGreen),
                                        InvertBlue: simd_bool(InvertBlue))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ChannelSwizzles>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<ChannelSwizzles>.stride)
        
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
        InitializedForImage = true
    }
    
    func Render(Image: UIImage) -> UIImage?
    {
        if !InitializedForImage
        {
            fatalError("Not initialized.")
        }
        
        let Start = CACurrentMediaTime()
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "HSBSwizzling")
        do
        {
            ImageComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
        
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
        
        let (C1, C2, C3) = GetSwizzleValues()
        var IsHSB = false
        if ChannelIsInHSB(Channel: C1) || ChannelIsInHSB(Channel: C2) || ChannelIsInHSB(Channel: C3)
        {
            IsHSB = true
        }
        var IsCMYK = false
        if ChannelIsInCMYK(Channel: C1) || ChannelIsInCMYK(Channel: C2) || ChannelIsInCMYK(Channel: C3)
        {
            IsCMYK = true
        }
        let InvertRed = ParameterManager.GetBool(From: ID(), Field: .InvertRed, Default: false)
        let InvertGreen = ParameterManager.GetBool(From: ID(), Field: .InvertGreen, Default: false)
        let InvertBlue = ParameterManager.GetBool(From: ID(), Field: .InvertBlue, Default: false)
        let Parameter = ChannelSwizzles(Channel1: simd_int1(C1), Channel2: simd_int1(C2), Channel3: simd_int1(C3),
                                        HasHSB: simd_bool(IsHSB), HasCMYK: simd_bool(IsCMYK),
                                        InvertRed: simd_bool(InvertRed), InvertGreen: simd_bool(InvertGreen),
                                        InvertBlue: simd_bool(InvertBlue))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ChannelSwizzles>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<ChannelSwizzles>.stride)
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
    
    func GetSwizzleValues() -> (Int, Int, Int)
    {
        var C1: Int = Channels.Red.rawValue
        var C2: Int = Channels.Green.rawValue
        var C3: Int = Channels.Blue.rawValue
        let RawC1 = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Channel1)
        if let C1Val = RawC1 as? Int
        {
            C1 = C1Val
        }
        let RawC2 = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Channel2)
        if let C2Val = RawC2 as? Int
        {
            C2 = C2Val
        }
        let RawC3 = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Channel3)
        if let C3Val = RawC3 as? Int
        {
            C3 = C3Val
        }
        return (C1, C2, C3)
    }
    
    func ChannelIsInHSB(Channel: Int) -> Bool
    {
        return Channel >= Channels.Hue.rawValue && Channel <= Channels.Brightness.rawValue
    }
    
    func ChannelIsInCMYK(Channel: Int) -> Bool
    {
        return Channel >= Channels.Cyan.rawValue && Channel <= Channels.Black.rawValue
    }
    
    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    {
        switch Field
        {
        case .RenderImageCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeImageRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .RenderLiveCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeLiveRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .Channel1:
            return (FilterManager.InputTypes.IntType, Channels.Red.rawValue as Any?)
            
        case .Channel2:
            return (FilterManager.InputTypes.IntType, Channels.Green.rawValue as Any?)
            
        case .Channel3:
            return (FilterManager.InputTypes.IntType, Channels.Blue.rawValue as Any?)
            
        case .InvertRed:
            return (.BoolType, false as Any?)
            
        case .InvertGreen:
            return (.BoolType, false as Any?)
            
        case .InvertBlue:
            return (.BoolType, false as Any?)
            
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
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return ChannelMixer.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.RenderImageCount)
        Fields.append(.CumulativeImageRenderDuration)
        Fields.append(.InvertRed)
        Fields.append(.InvertGreen)
        Fields.append(.InvertBlue)
        Fields.append(.Channel1)
        Fields.append(.Channel2)
        Fields.append(.Channel3)
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
        Fields.append(.RenderLiveCount)
        Fields.append(.CumulativeLiveRenderDuration)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return ChannelMixer.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "ChannelMixerSettingsUI"
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
        return ChannelMixer.FilterTarget()
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
        Keywords.append("Filter: HSBSwizzling")
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
            return ChannelMixer.FilterKernel
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
        return ChannelMixer.Ports()
    }
}

/// Color channel defintions.
///
/// - Red: Red channel.
/// - Green: Green channel.
/// - Blue: Blue channel.
/// - Hue: Hue value from HSB color space.
/// - Saturation: Saturation value from HSB color space.
/// - Brightness: Brightness value from HSB color space.
/// - Cyan: Cyan channel from CMYK color space.
/// - Magenta: Magenta channel from CMYK color space.
/// - Yellow: Yellow channel from CMYK color space.
/// - Black: Black channel from CMYK color space.
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

