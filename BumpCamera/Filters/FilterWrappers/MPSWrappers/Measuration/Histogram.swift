//
//  Histogram.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit
import MetalPerformanceShaders

class Histogram: FilterParent, Renderer
{
    required override init()
    {
        super.init()
    }
    
    static let _ID: UUID = UUID(uuidString: "2aba47dc-5d62-478d-93ae-ad01bdce862d")!
    
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
        return "Histogram"
    }
    
    func Title() -> String
    {
        return type(of: self).Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Histogram"
    
    private let MetalDevice = MTLCreateSystemDefaultDevice()
    
    private lazy var CommandQueue: MTLCommandQueue? =
    {
        return self.MetalDevice?.makeCommandQueue()
    }()
    
    private(set) var OutputFormatDescription: CMFormatDescription? = nil
    
    private(set) var InputFormatDescription: CMFormatDescription? = nil
    
    var Initialized = false
    
    var bciContext: CIContext!
    
    private var BufferPool: CVPixelBufferPool? = nil
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    {
        Reset("Histogram.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in Histogram.Initialize.")
            return
        }
        CommandQueue = MetalDevice?.makeCommandQueue()
        bciContext = CIContext()
        Initialized = true
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in Histogram.")
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
        OutputFormatDescription = nil
        InputFormatDescription = nil
        TextureCache = nil
        ciContext = nil
        bciContext = nil
        CommandQueue = nil
        Initialized = false
    }
    
    func Reset()
    {
        Reset("")
    }
    
    var AccessLock = NSObject()
    
    /// Render the buffer passed with the Histogram MPS filter. The buffer is assumed to be from the live view.
    ///
    /// - Parameter PixelBuffer: The (assumedly) live view buffer.
    /// - Returns: Pixel buffer with the rendered image.
    func Query(PixelBuffer: CVPixelBuffer, Parameters: [String: Any]) -> [String: Any]?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        if !Initialized
        {
            fatalError("Histogram not initialized at Render(CVPixelBuffer) call.")
        }
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
       /*
        guard let OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in Histogram.")
            return nil
        }
 */
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(PixelBuffer: PixelBuffer, TextureFormat: .bgra8Unorm) else
        {
            print("Error creating input texture in Histogram.")
            return nil
        }
        /*
        guard let OutputTexture = MakeTextureFromCVPixelBuffer(PixelBuffer: OutputBuffer, TextureFormat: .bgra8Unorm) else
        {
            print("Error creating output texture in Histogram.")
            return nil
        }
 */
        
        guard let CommandQ = CommandQueue,
            let CommandBuffer = CommandQ.makeCommandBuffer() else
        {
            print("Error creating Metal command queue in Histogram.")
            CVMetalTextureCacheFlush(TextureCache!, 0)
            return nil
        }
        
        var HistogramInfo = MPSImageHistogramInfo(numberOfHistogramEntries: 256,
                                                  histogramForAlpha: false,
                                                  minPixelValue: vector_float4(0,0,0,0),
                                                  maxPixelValue: vector_float4(1,1,1,1))
        
        let Shader = MPSImageHistogram(device: MetalDevice!, histogramInfo: &HistogramInfo)
        let BufferLength = Shader.histogramSize(forSourceFormat: InputTexture.pixelFormat)
        let HistogramBuffer = MetalDevice!.makeBuffer(length: BufferLength, options: [.storageModePrivate])
        
        Shader.encode(to: CommandBuffer, sourceTexture: InputTexture, histogram: HistogramBuffer!, histogramOffset: 0)
        CommandBuffer.commit()
        CommandBuffer.waitUntilCompleted()
        
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
        
        let HBufPtr = HistogramBuffer?.contents()
        let HPtr = HBufPtr?.bindMemory(to: vector_float4.self, capacity: 256)
        let HPtrBuffer = UnsafeBufferPointer(start: HPtr, count: 256)
        let Final = Array(HPtrBuffer)
        
        var Results = [String: Any]()

        Results["Histogram"] = Final
        return Results
    }
    
    var ImageDevice: MTLDevice? = nil
    var InitializedForImage = false
    
    private lazy var ImageCommandQueue: MTLCommandQueue? =
    {
        return self.ImageDevice?.makeCommandQueue()
    }()
    
    var IGTextureLoader: MTKTextureLoader? = nil
    
    func InitializeForImage()
    {
        ImageDevice = MTLCreateSystemDefaultDevice()
        Reset("Histogram.Initialize")
        CommandQueue = ImageDevice?.makeCommandQueue()
        IGTextureLoader = MTKTextureLoader(device: MetalDevice!)
        InitializedForImage = true
        ciContext = CIContext()
    }
    
    func Query(Image: UIImage, Parameters: [String: Any]) -> [String: Any]?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        
        let CgImage = Image.cgImage
        //let PixelBuffer = GetPixelBufferFrom(Image)
        
        var SourceTexture: MTLTexture!
        let Loader = MTKTextureLoader(device: ImageDevice!)
        do
        {
            let OriginalTexture = try Loader.newTexture(cgImage: CgImage!, options: nil)
            SourceTexture = OriginalTexture.makeTextureView(pixelFormat: .bgra8Unorm)
        }
        catch
        {
            print("Error when trying to load texture from passed image: \(error.localizedDescription)")
            return nil
        }
        
        let InputTexture = SourceTexture
        
        guard let CommandQ = CommandQueue,
            let CommandBuffer = CommandQ.makeCommandBuffer() else
        {
            print("Error creating Metal command queue in Histogram.")
            CVMetalTextureCacheFlush(TextureCache!, 0)
            return nil
        }
        
        var HistogramInfo = MPSImageHistogramInfo(numberOfHistogramEntries: 256,
                                                  histogramForAlpha: false,
                                                  minPixelValue: vector_float4(0,0,0,0),
                                                  maxPixelValue: vector_float4(1,1,1,1))
        
        let Shader = MPSImageHistogram(device: MetalDevice!, histogramInfo: &HistogramInfo)
        let BufferLength = Shader.histogramSize(forSourceFormat: InputTexture!.pixelFormat)
        let HistogramBuffer = MetalDevice!.makeBuffer(length: BufferLength, options: [])
        
        Shader.encode(to: CommandBuffer, sourceTexture: InputTexture!, histogram: HistogramBuffer!, histogramOffset: 0)
        CommandBuffer.commit()
        CommandBuffer.waitUntilCompleted()
        
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
        
        let HBufPtr = HistogramBuffer?.contents()
        let HPtr = HBufPtr?.bindMemory(to: vector_float4.self, capacity: 256)
        let HPtrBuffer = UnsafeBufferPointer(start: HPtr, count: 256)
        let Final = Array(HPtrBuffer)
        
        var Results = [String: Any]()
        
        Results["Histogram"] = Final
        return Results
    }
    
    var ciContext: CIContext!
    
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
        var Fields = [FilterManager.InputFields]()
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
        return "HistogramGenerationSettingsUI"
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
        Keywords.append("Filter: Histogram")
        Keywords.append("FilterType: Metal Performance Shader")
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
            return FilterManager.FilterKernelTypes.MPS
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
