//
//  GaussianBlur.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/22/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit
import MetalPerformanceShaders

class GaussianBlur: FilterParent, Renderer
{
    required override init()
    {
        #if false
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "SolarizeKernel")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
        #endif
    }
    
    static let _ID: UUID = UUID(uuidString: "5ccbc7e0-7422-498c-a99a-ff1679399d9b")!
    
    func ID() -> UUID
    {
        return GaussianBlur._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    static func Title() -> String
    {
        return "Gaussian Blur"
    }
    
    func Title() -> String
    {
        return GaussianBlur.Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "GaussianBlur"
    
    private let MetalDevice = MTLCreateSystemDefaultDevice()
    
    //private var ComputePipelineState: MTLComputePipelineState? = nil
    
    private lazy var CommandQueue: MTLCommandQueue? =
    {
        return self.MetalDevice?.makeCommandQueue()
    }()
    
    private(set) var OutputFormatDescription: CMFormatDescription? = nil
    
    private(set) var InputFormatDescription: CMFormatDescription? = nil
    
    //private var BufferPool: CVPixelBufferPool? = nil
    
    var Initialized = false
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    {
        Reset("GaussianBlur.Initialize")
        CommandQueue = MetalDevice?.makeCommandQueue()
        Initialized = true
    }
    
    func Reset(_ CalledBy: String = "")
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        //BufferPool = nil
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
    
    //var ParameterBuffer: MTLBuffer! = nil
    //var PreviousDebug = ""
    
    //From MPSUnaryImageKernel.MPSCopyAllocator documentation.
    let SomeAllocator: MPSCopyAllocator =
    {
        (kernel: MPSKernel, buffer: MTLCommandBuffer, texture: MTLTexture) -> MTLTexture in
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: texture.pixelFormat, width: texture.width,
                                                                  height: texture.height, mipmapped: false)
        return buffer.device.makeTexture(descriptor: descriptor)!
    }
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        if !Initialized
        {
            fatalError("GaussianBlur not initialized at Render(CVPixelBuffer) call.")
        }
        
        let LVTextureLoader = MTKTextureLoader(device: MetalDevice!)
        guard let CommandBuffer = CommandQueue?.makeCommandBuffer() else
        {
            print("Error making command buffer.")
            return nil
        }
        let CiImage = CIImage(cvPixelBuffer: PixelBuffer)
        let ciContext = CIContext()
        var InputTexture: MTLTexture!
        if let CgImage = ciContext.createCGImage(CiImage, from: CiImage.extent)
        {
            do
            {
                InputTexture = try LVTextureLoader.newTexture(cgImage: CgImage, options: [:])
            }
            catch
            {
                print("Error loading texture: \(error.localizedDescription)")
                return nil
            }
        }
        let InPlaceTexture = UnsafeMutablePointer<MTLTexture>.allocate(capacity: 1)
        InPlaceTexture.initialize(to: InputTexture)
        let Sigma = ParameterManager.GetDouble(From: ID(), Field: .Sigma, Default: 5.0)
        let Shader = MPSImageGaussianBlur(device: MetalDevice!, sigma: Float(Sigma))
        Shader.encode(commandBuffer: CommandBuffer, inPlaceTexture: InPlaceTexture, fallbackCopyAllocator: SomeAllocator)
        CommandBuffer.commit()
        CommandBuffer.waitUntilCompleted()
        var Final: CIImage = CIImage(mtlTexture: InputTexture, options: [:])!
        Final = RotateImageRight(Final, AndMirror: true)
        InPlaceTexture.deallocate()
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
        if Final.pixelBuffer == nil
        {
            //Need to render with CIContext in this case.
            //https://stackoverflow.com/questions/33053412/how-to-initialise-cvpixelbufferref-in-swift
            var PixelBuffer: CVPixelBuffer? = nil
            CVPixelBufferCreate(kCFAllocatorDefault, Int(Final.extent.width), Int(Final.extent.height),
                                kCVPixelFormatType_32BGRA, nil, &PixelBuffer)
            
            ciContext.render(Final, to: PixelBuffer!)
            return PixelBuffer
        }
        return Final.pixelBuffer
    }
    
    var ImageDevice: MTLDevice? = nil
    var InitializedForImage = false
    #if false
    private var ImageComputePipelineState: MTLComputePipelineState? = nil
    #endif
    private lazy var ImageCommandQueue: MTLCommandQueue? =
    {
        return self.ImageDevice?.makeCommandQueue()
    }()
    
    var IGTextureLoader: MTKTextureLoader? = nil
    
    func InitializeForImage()
    {
        ImageDevice = MTLCreateSystemDefaultDevice()
        Reset("GaussianBlur.Initialize")
        CommandQueue = ImageDevice?.makeCommandQueue()
        IGTextureLoader = MTKTextureLoader(device: MetalDevice!)
        InitializedForImage = true
    }
    
    /// Renders the image with the wrapper's MPS image filter. In our case, the MPSImageGaussianBlur.
    ///
    /// - Note: [Metal kernel functions compute shaders](http://flexmonkey.blogspot.com/2014/10/metal-kernel-functions-compute-shaders.html)
    ///
    /// - Parameter Image: The image to render.
    /// - Returns: the rendered image.
    func Render(Image: UIImage) -> UIImage?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        if !InitializedForImage
        {
            fatalError("GaussianBlur not initialized at Render(UIImage) call.")
        }
        guard let CommandBuffer = ImageCommandQueue?.makeCommandBuffer() else
        {
            print("Error making command buffer.")
            return nil
        }
        let CiImage = CIImage(image: Image)
        let ciContext = CIContext()
        var InputTexture: MTLTexture!
        if let CgImage = ciContext.createCGImage(CiImage!, from: CiImage!.extent)
        {
            do
            {
                InputTexture = try IGTextureLoader?.newTexture(cgImage: CgImage, options: [:])
            }
            catch
            {
                print("Error loading texture.")
                return nil
            }
        }
        let InPlaceTexture = UnsafeMutablePointer<MTLTexture>.allocate(capacity: 1)
        InPlaceTexture.initialize(to: InputTexture)
        let Sigma = ParameterManager.GetDouble(From: ID(), Field: .Sigma, Default: 5.0)
        let Shader = MPSImageGaussianBlur(device: MetalDevice!, sigma: Float(Sigma))
        Shader.encode(commandBuffer: CommandBuffer, inPlaceTexture: InPlaceTexture, fallbackCopyAllocator: SomeAllocator)
        CommandBuffer.commit()
        CommandBuffer.waitUntilCompleted()
        var Final: CIImage = CIImage(mtlTexture: InputTexture, options: [:])!
        Final = RotateImage180(Final)
        InPlaceTexture.deallocate()
        ImageRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: ImageRenderTime, ID: ID(), ForImage: true)

        return UIImage(ciImage: Final)
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
                print("Error converting UIImage to CIImage in GaussianBlur.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in GaussianBlur.Render(CIImage)")
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
        case .Sigma:
            return (.DoubleType, 5.0 as Any?)
            
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
        return GaussianBlur.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.Sigma)
        Fields.append(.RenderImageCount)
        Fields.append(.CumulativeImageRenderDuration)
        Fields.append(.RenderLiveCount)
        Fields.append(.CumulativeLiveRenderDuration)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return GaussianBlur.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "GaussianBlurSettingsUI"
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
        return GaussianBlur.FilterTarget()
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
        Keywords.append("Filter: GaussianBlur")
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
            return GaussianBlur.FilterKernel
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
        return [FilterPorts.Input, FilterPorts.Output]
    }
    
    /// Describes the available ports for the filter.
    ///
    /// - Returns: Array of ports.
    func Ports() -> [FilterPorts]
    {
        return GaussianBlur.Ports()
    }
}
