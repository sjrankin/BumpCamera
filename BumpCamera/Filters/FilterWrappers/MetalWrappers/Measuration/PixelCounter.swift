//
//  PixelCounter.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit

class PixelCounter: FilterParent, Renderer
{
    required override init()
    {
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "PixelCounter")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    static let _ID: UUID = UUID(uuidString: "509490b1-69a0-48f1-9d04-132b0a48edea")!
    
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
        return "PixelCounter"
    }
    
    func Title() -> String
    {
        return type(of: self).Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "PixelCounter"
    
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
        Reset("PixelCounter.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in PixelCounter.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        
        Initialized = true
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in PixelCounter.")
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
        return nil
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
        let KernelFunction = DefaultLibrary?.makeFunction(name: "PixelCounter")
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
        return nil
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        return nil
    }
    
    // Must call Initialize first.
    func Query(PixelBuffer: CVPixelBuffer, Parameters: [String: Any]) -> [String: Any]?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        if !Initialized
        {
            fatalError("PixelCounter not initialized at Render(CVPixelBuffer) call.")
        }
        
        //BufferPool is nil - nothing to do (or can do). This probably occurred because the user changed
        //filters out from under us and the video sub-system hadn't quite caught up to the new filter and
        //sent a frame to the no-longer-active filter.
        if BufferPool == nil
        {
            return nil
        }
        
        let LookFor = Parameters["CountFor"] as! [UIColor]
        var SearchForColors = [simd_float4](repeating: simd_float4(0.0, 0.0, 0.0, 1.0), count: 256)
        for Index in 0 ..< LookFor.count
        {
            SearchForColors[Index] = simd_float4(Float(LookFor[Index].r), Float(LookFor[Index].g), Float(LookFor[Index].b), 1.0)
        }
        let IColorSearch = UnsafePointer(SearchForColors)
        let IColorSize = MemoryLayout<simd_float4>.stride * 256
        let ColorBuffer = MetalDevice!.makeBuffer(bytes: IColorSearch, length: IColorSize, options: [])
        
        let Start = CACurrentMediaTime()
        let Action = Parameters["Action"] as! Int
        let PixelSearchCount = Parameters["PixelSearchCount"] as! Int
        let CountFor = Parameters["CountFor"] as! [UIColor]
        let CountIf = Parameters["CountIf"] as! Int
        let HueOffset = Parameters["HueOffset"] as! Double
        let ReturnBufferSize = max(CountFor.count, 100)
        let RangeSize = Parameters["RangeSize"] as! Double
        
        let Parameter = PixelCounterParameters(Action: simd_uint1(Action),
                                               PixelSearchCount: simd_uint1(PixelSearchCount),
                                               CountIf: simd_uint1(CountIf),
                                               HueOffset: simd_float1(HueOffset),
                                               ReturnBufferSize: simd_uint1(ReturnBufferSize),
                                               RangeSize: simd_float1(RangeSize))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<PixelCounterParameters>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<PixelCounterParameters>.stride)
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(PixelBuffer: PixelBuffer, TextureFormat: .bgra8Unorm) else
        {
            print("Error creating textures in PixelCounter.")
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
        
        let ResultsCount = 10
        let ResultsBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ReturnBufferType>.stride * ResultsCount, options: [])
        let Results = UnsafeBufferPointer<ReturnBufferType>(start: UnsafePointer(ResultsBuffer!.contents().assumingMemoryBound(to: ReturnBufferType.self)),
                                                            count: ResultsCount)
        
        CommandEncoder.label = "Pixel Counter Kernel"
        CommandEncoder.setComputePipelineState(ComputePipelineState!)
        CommandEncoder.setTexture(InputTexture, index: 0)
        CommandEncoder.setBuffer(ParameterBuffer, offset: 0, index: 0)
        CommandEncoder.setBuffer(ColorBuffer, offset: 0, index: 1)
        CommandEncoder.setBuffer(ResultsBuffer, offset: 0, index: 2)
        
        #if true
        let ThreadsPerThreadGroup = MTLSizeMake(1, 1, 1)
        let ThreadGroupsPerGrid = MTLSizeMake(1, 1, 1)
        #else
        let w = ComputePipelineState!.threadExecutionWidth
        let h = ComputePipelineState!.maxTotalThreadsPerThreadgroup / w
        let ThreadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        let ThreadGroupsPerGrid = MTLSize(width: (InputTexture.width + w - 1) / w,
                                          height: (InputTexture.height + h - 1) / h,
                                          depth: 1)
        #endif
        CommandEncoder.dispatchThreadgroups(ThreadGroupsPerGrid, threadsPerThreadgroup: ThreadsPerThreadGroup)
        CommandEncoder.endEncoding()
        CommandBuffer.commit()
        
        var FinalResults = [String: Any]()
        switch Action
        {
        case 0:
            //count pixels
            var Index = 0
            for Value in Results
            {
                FinalResults["Color\(Index)"] = Double(Value)
                Index = Index + 1
            }
            
        case 1:
            //mean color
            FinalResults["PixelCount"] = Int(Results[0])
            FinalResults["MeanRed"] = Double(Results[1])
            FinalResults["MeanGreen"] = Double(Results[2])
            FinalResults["MeanBlue"] = Double(Results[3])
            
        case 2:
            //pixels in hue ranges
            var Index = 0
            for Value in Results
            {
                FinalResults["Range\(Index)"] = Double(Value)
                Index = Index + 1
            }
            
        default:
            return nil
        }
        
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
        
        return FinalResults
    }
    
    // Must call InitializeForImage first.
    func Query(Image: UIImage, Parameters: [String: Any]) -> [String: Any]?
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
            print("Error creating input texture in PixelCounter.Render.")
            return nil
        }
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        
        let LookFor = Parameters["CountFor"] as! [UIColor]
        var SearchForColors = [simd_float4](repeating: simd_float4(0.0, 0.0, 0.0, 1.0), count: 256)
        for Index in 0 ..< LookFor.count
        {
            SearchForColors[Index] = simd_float4(Float(LookFor[Index].r), Float(LookFor[Index].g), Float(LookFor[Index].b), 1.0)
        }
        let IColorSearch = UnsafePointer(SearchForColors)
        let IColorSize = MemoryLayout<simd_float4>.stride * 256
        let ColorBuffer = MetalDevice!.makeBuffer(bytes: IColorSearch, length: IColorSize, options: [])
        
        let Action = Parameters["Action"] as! Int
        let PixelSearchCount = Parameters["PixelSearchCount"] as! Int
        let CountFor = Parameters["CountFor"] as! [UIColor]
        let CountIf = Parameters["CountIf"] as! Int
        let HueOffset = Parameters["HueOffset"] as! Double
        let ReturnBufferSize = max(CountFor.count, 100)
        let RangeSize = Parameters["RangeSize"] as! Double
        
        let Parameter = PixelCounterParameters(Action: simd_uint1(Action),
                                               PixelSearchCount: simd_uint1(PixelSearchCount),
                                               CountIf: simd_uint1(CountIf),
                                               HueOffset: simd_float1(HueOffset),
                                               ReturnBufferSize: simd_uint1(ReturnBufferSize),
                                               RangeSize: simd_float1(RangeSize))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<PixelCounterParameters>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<PixelCounterParameters>.stride)
        CommandEncoder?.setBuffer(ParameterBuffer, offset: 0, index: 0)
        CommandEncoder?.setBuffer(ColorBuffer, offset: 0, index: 1)
        
        let ResultsCount = ReturnBufferSize
        let ResultsBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ReturnBufferType>.stride * ResultsCount, options: [])
        let Results = UnsafeBufferPointer<ReturnBufferType>(start: UnsafePointer(ResultsBuffer!.contents().assumingMemoryBound(to: ReturnBufferType.self)),
                                                            count: ResultsCount)
        CommandEncoder?.setBuffer(ResultsBuffer, offset: 0, index: 2)
        
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(Texture, index: 0)
        
        #if true
        let ThreadGroupCount = MTLSizeMake(1, 1, 1)
        let ThreadGroups = MTLSizeMake(1, 1, 1)
        #else
        let ThreadGroupCount = MTLSizeMake(8, 8, 1)
        let ThreadGroups = MTLSizeMake(Texture.width / ThreadGroupCount.width,
                                       Texture.height / ThreadGroupCount.height,
                                       1)
        #endif
        
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        
        CommandEncoder?.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder?.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        
        var FinalResults = [String: Any]()
        switch Action
        {
        case 0:
            //count pixels
            var Index = 0
            for Value in Results
            {
                FinalResults["Color\(Index)"] = Double(Value)
                Index = Index + 1
            }
            
        case 1:
            //mean color
            FinalResults["PixelCount"] = Int(Results[0])
            FinalResults["MeanRed"] = Double(Results[1])
            FinalResults["MeanGreen"] = Double(Results[2])
            FinalResults["MeanBlue"] = Double(Results[3])
            FinalResults["Width"] = Double(Results[4])
            FinalResults["Height"] = Double(Results[5])
            
        case 2:
            //pixels in hue ranges
            var Index = 0
            for Value in Results
            {
                FinalResults["Range\(Index)"] = Double(Value)
                Index = Index + 1
            }
            
        default:
            return nil
        }
        
        ImageRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: ImageRenderTime, ID: ID(), ForImage: true)
        
        return FinalResults
    }
    
    // Must call InitializeForImage first.
    func Query(Image: CIImage, Parameters: [String: Any]) -> [String: Any]?
    {
        let UImage = UIImage(ciImage: Image)
        if let IFinal = Query(Image: UImage, Parameters: Parameters)
        {
            return IFinal
        }
        return nil
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
        return [.RenderImageCount, .CumulativeImageRenderDuration, .RenderLiveCount, .CumulativeLiveRenderDuration]
    }
    
    func SettingsStoryboard() -> String?
    {
        return type(of: self).SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "PixelCounterSettingsUI"
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
        Keywords.append("Filter: PixelCounter")
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
        return [FilterPorts.Input]
    }
    
    /// Describes the available ports for the filter.
    ///
    /// - Returns: Array of ports.
    func Ports() -> [FilterPorts]
    {
        return type(of: self).Ports()
    }
}

