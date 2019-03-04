//
//  ColorInverter.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit

class ColorInverter: FilterParent, Renderer
{
    required override init()
    {
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "ColorInverter")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    static let _ID: UUID = UUID(uuidString: "11902e06-8516-4697-ae40-f233ab88bf77")!
    
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
        return "Invert Colors"
    }
    
    func Title() -> String
    {
        return type(of: self).Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Invert Colors"
    
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
        Reset("ColorInverter.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in ColorInverter.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        
        Initialized = true
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in ColorInverter.")
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
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        if !Initialized
        {
            fatalError("ColorInverter not initialized at Render(CVPixelBuffer) call.")
        }
        
        //BufferPool is nil - nothing to do (or can do). This probably occurred because the user changed
        //filters out from under us and the video sub-system hadn't quite caught up to the new filter and
        //sent a frame to the no-longer-active filter.
        if BufferPool == nil
        {
            return nil
        }
        
        let Start = CACurrentMediaTime()
        let Colorspace = ParameterManager.GetUInt1(From: ID(), Field: .CIColorspace, Default: 0)
        let Invert1 = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertChannel1, Default: false)
        let Invert2 = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertChannel2, Default: false)
        let Invert3 = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertChannel3, Default: false)
        let Invert4 = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertChannel4, Default: false)
        let EnableThreshold1 = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableChannel1Threshold, Default: false)
        let EnableThreshold2 = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableChannel2Threshold, Default: false)
        let EnableThreshold3 = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableChannel3Threshold, Default: false)
        let EnableThreshold4 = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableChannel4Threshold, Default: false)
        let Threshold1 = ParameterManager.GetFloat1(From: ID(), Field: .CIChannel1Threshold, Default: 0.5)
        let Threshold2 = ParameterManager.GetFloat1(From: ID(), Field: .CIChannel2Threshold, Default: 0.5)
        let Threshold3 = ParameterManager.GetFloat1(From: ID(), Field: .CIChannel3Threshold, Default: 0.5)
        let Threshold4 = ParameterManager.GetFloat1(From: ID(), Field: .CIChannel4Threshold, Default: 0.5)
        let GreaterInvert1 = ParameterManager.GetSimdBool(From: ID(), Field: .CIChannel1InvertIfGreater, Default: false)
        let GreaterInvert2 = ParameterManager.GetSimdBool(From: ID(), Field: .CIChannel2InvertIfGreater, Default: false)
        let GreaterInvert3 = ParameterManager.GetSimdBool(From: ID(), Field: .CIChannel3InvertIfGreater, Default: false)
        let GreaterInvert4 = ParameterManager.GetSimdBool(From: ID(), Field: .CIChannel4InvertIfGreater, Default: false)
        let InvertAlpha = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertAlpha, Default: false)
        let EnableAlphaThreshold = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableAlphaThreshold, Default: false)
        let AlphaThreshold = ParameterManager.GetFloat1(From: ID(), Field: .CIAlphaThreshold, Default: 0.5)
        let AlphaGreaterInvert = ParameterManager.GetSimdBool(From: ID(), Field: .CIAlphaInvertIfGreater, Default: false)
        let Parameter = ColorInverterParameters(Colorspace: Colorspace,
                                                InvertChannel1: Invert1,
                                                InvertChannel2: Invert2,
                                                InvertChannel3: Invert3,
                                                InvertChannel4: Invert4,
                                                EnableChannel1Threshold: EnableThreshold1,
                                                EnableChannel2Threshold: EnableThreshold2,
                                                EnableChannel3Threshold: EnableThreshold3,
                                                EnableChannel4Threshold: EnableThreshold4,
                                                Channel1Threshold: Threshold1,
                                                Channel2Threshold: Threshold2,
                                                Channel3Threshold: Threshold3,
                                                Channel4Threshold: Threshold4,
                                                Channel1InvertIfGreater: GreaterInvert1,
                                                Channel2InvertIfGreater: GreaterInvert2,
                                                Channel3InvertIfGreater: GreaterInvert3,
                                                Channel4InvertIfGreater: GreaterInvert4,
                                                InvertAlpha: InvertAlpha,
                                                EnableAlphaThreshold: EnableAlphaThreshold,
                                                AlphaThreshold: AlphaThreshold,
                                                AlphaInvertIfGreater: AlphaGreaterInvert)
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ColorInverterParameters>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<ColorInverterParameters>.stride)
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
        guard let OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in ColorInverter.")
            return nil
        }
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: PixelBuffer, textureFormat: .bgra8Unorm),
            let OutputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: OutputBuffer, textureFormat: .bgra8Unorm) else
        {
            print("Error creating textures in ColorInverter.")
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
        
        CommandEncoder.label = "Color Inverter Kernel"
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
        let DefaultLibrary = ImageDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "ColorInverter")
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
            print("Error creating input texture in ColorInverter.Render.")
            return nil
        }
        
        let Region = MTLRegionMake2D(0, 0, Int(ImageWidth), Int(ImageHeight))
        Texture.replace(region: Region, mipmapLevel: 0, withBytes: &RawData, bytesPerRow: Int((CgImage?.bytesPerRow)!))
        let OutputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Texture.pixelFormat,
                                                                               width: Texture.width, height: Texture.height, mipmapped: true)
        OutputTextureDescriptor.usage = MTLTextureUsage.shaderWrite
        let OutputTexture = ImageDevice?.makeTexture(descriptor: OutputTextureDescriptor)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(Texture, index: 0)
        CommandEncoder?.setTexture(OutputTexture, index: 1)
        
        let Colorspace = ParameterManager.GetUInt1(From: ID(), Field: .CIColorspace, Default: 0)
        let Invert1 = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertChannel1, Default: false)
        let Invert2 = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertChannel2, Default: false)
        let Invert3 = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertChannel3, Default: false)
        let Invert4 = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertChannel4, Default: false)
        let EnableThreshold1 = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableChannel1Threshold, Default: false)
        let EnableThreshold2 = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableChannel2Threshold, Default: false)
        let EnableThreshold3 = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableChannel3Threshold, Default: false)
        let EnableThreshold4 = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableChannel4Threshold, Default: false)
        let Threshold1 = ParameterManager.GetFloat1(From: ID(), Field: .CIChannel1Threshold, Default: 0.5)
        let Threshold2 = ParameterManager.GetFloat1(From: ID(), Field: .CIChannel2Threshold, Default: 0.5)
        let Threshold3 = ParameterManager.GetFloat1(From: ID(), Field: .CIChannel3Threshold, Default: 0.5)
        let Threshold4 = ParameterManager.GetFloat1(From: ID(), Field: .CIChannel4Threshold, Default: 0.5)
        let GreaterInvert1 = ParameterManager.GetSimdBool(From: ID(), Field: .CIChannel1InvertIfGreater, Default: false)
        let GreaterInvert2 = ParameterManager.GetSimdBool(From: ID(), Field: .CIChannel2InvertIfGreater, Default: false)
        let GreaterInvert3 = ParameterManager.GetSimdBool(From: ID(), Field: .CIChannel3InvertIfGreater, Default: false)
        let GreaterInvert4 = ParameterManager.GetSimdBool(From: ID(), Field: .CIChannel4InvertIfGreater, Default: false)
        let InvertAlpha = ParameterManager.GetSimdBool(From: ID(), Field: .CIInvertAlpha, Default: false)
        let EnableAlphaThreshold = ParameterManager.GetSimdBool(From: ID(), Field: .CIEnableAlphaThreshold, Default: false)
        let AlphaThreshold = ParameterManager.GetFloat1(From: ID(), Field: .CIAlphaThreshold, Default: 0.5)
        let AlphaGreaterInvert = ParameterManager.GetSimdBool(From: ID(), Field: .CIAlphaInvertIfGreater, Default: false)
        let Parameter = ColorInverterParameters(Colorspace: Colorspace,
                                                InvertChannel1: Invert1,
                                                InvertChannel2: Invert2,
                                                InvertChannel3: Invert3,
                                                InvertChannel4: Invert4,
                                                EnableChannel1Threshold: EnableThreshold1,
                                                EnableChannel2Threshold: EnableThreshold2,
                                                EnableChannel3Threshold: EnableThreshold3,
                                                EnableChannel4Threshold: EnableThreshold4,
                                                Channel1Threshold: Threshold1,
                                                Channel2Threshold: Threshold2,
                                                Channel3Threshold: Threshold3,
                                                Channel4Threshold: Threshold4,
                                                Channel1InvertIfGreater: GreaterInvert1,
                                                Channel2InvertIfGreater: GreaterInvert2,
                                                Channel3InvertIfGreater: GreaterInvert3,
                                                Channel4InvertIfGreater: GreaterInvert4,
                                                InvertAlpha: InvertAlpha,
                                                EnableAlphaThreshold: EnableAlphaThreshold,
                                                AlphaThreshold: AlphaThreshold,
                                                AlphaInvertIfGreater: AlphaGreaterInvert)
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ColorInverterParameters>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<ColorInverterParameters>.stride)
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
                print("Error converting UIImage to CIImage in ColorInverter.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in ColorInverter.Render(CIImage)")
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
        case .CIColorspace:
            return (.IntType, 0 as Any?)
            
        case .CIInvertChannel1:
            return (.BoolType, false as Any?)
            
        case .CIInvertChannel2:
            return (.BoolType, false as Any?)
            
        case .CIInvertChannel3:
            return (.BoolType, false as Any?)
            
        case .CIInvertChannel4:
            return (.BoolType, false as Any?)
            
        case .CIChannel1Threshold:
            return (.DoubleType, 0.5 as Any?)
            
        case .CIChannel2Threshold:
            return (.DoubleType, 0.5 as Any?)
            
        case .CIChannel3Threshold:
            return (.DoubleType, 0.5 as Any?)
            
        case .CIChannel4Threshold:
            return (.DoubleType, 0.5 as Any?)
            
        case .CIChannel1InvertIfGreater:
            return (.BoolType, false as Any?)
            
        case .CIChannel2InvertIfGreater:
            return (.BoolType, false as Any?)
            
        case .CIChannel3InvertIfGreater:
            return (.BoolType, false as Any?)
            
        case .CIChannel4InvertIfGreater:
            return (.BoolType, false as Any?)
            
        case .CIEnableChannel1Threshold:
            return (.BoolType, false as Any?)
            
        case .CIEnableChannel2Threshold:
            return (.BoolType, false as Any?)
            
        case .CIEnableChannel3Threshold:
            return (.BoolType, false as Any?)
            
        case .CIEnableChannel4Threshold:
            return (.BoolType, false as Any?)
            
        case .CIInvertAlpha:
            return (.BoolType, false as Any?)
            
        case .CIEnableAlphaThreshold:
            return (.BoolType, false as Any?)
            
        case .CIAlphaThreshold:
            return (.DoubleType, 0.5 as Any?)
            
        case .CIAlphaInvertIfGreater:
            return (.BoolType, false as Any?)
            
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
        return type(of: self).SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        return [.CIColorspace,
                .CIInvertChannel1, .CIInvertChannel2, .CIInvertChannel3, .CIInvertChannel4,
                .CIEnableChannel1Threshold, .CIEnableChannel2Threshold, .CIEnableChannel3Threshold, .CIEnableChannel4Threshold,
                .CIChannel1Threshold, .CIChannel2Threshold, .CIChannel3Threshold, .CIChannel4Threshold,
                .CIChannel1InvertIfGreater, .CIChannel2InvertIfGreater, .CIChannel3InvertIfGreater, .CIChannel4InvertIfGreater,
                .CIInvertAlpha, .CIEnableAlphaThreshold, .CIAlphaThreshold, .CIAlphaInvertIfGreater,
                .RenderImageCount, .CumulativeImageRenderDuration, .RenderLiveCount, .CumulativeLiveRenderDuration]
    }
    
    func SettingsStoryboard() -> String?
    {
        return type(of: self).SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "ColorInverterSettingsUI"
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
        return type(of: self).FilterTarget()
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
        Keywords.append("Filter: ColorInverter")
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

