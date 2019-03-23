//
//  MPSLaplacian.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit
import MetalPerformanceShaders

class MPSLaplacian: FilterParent, Renderer
{
    required override init()
    {
        super.init()
    }
    
    static let _ID: UUID = UUID(uuidString: "43040a12-8490-4b94-9e71-b062e2f1b870")!
    
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
        return "MPSLaplacian"
    }
    
    func Title() -> String
    {
        return type(of: self).Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "MPSLaplacian"
    
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
        Reset("MPSLaplacian.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in MPSLaplacian.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        CommandQueue = MetalDevice?.makeCommandQueue()
        bciContext = CIContext()
        Initialized = true
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in MPSLaplacian.")
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
    
    /// Render the buffer passed with the Sobel MPS filter. The buffer is assumed to be from the live view.
    ///
    /// - Parameter PixelBuffer: The (assumedly) live view buffer.
    /// - Returns: Pixel buffer with the rendered image.
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        if !Initialized
        {
            fatalError("MPSLaplacian not initialized at Render(CVPixelBuffer) call.")
        }
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
        guard let OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in MPSLaplacian.")
            return nil
        }
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(PixelBuffer: PixelBuffer, TextureFormat: .bgra8Unorm) else
        {
            print("Error creating input texture in MPSLaplacian.")
            return nil
        }
        guard let OutputTexture = MakeTextureFromCVPixelBuffer(PixelBuffer: OutputBuffer, TextureFormat: .bgra8Unorm) else
        {
            print("Error creating output texture in MPSLaplacian.")
            return nil
        }
        
        guard let CommandQ = CommandQueue,
            let CommandBuffer = CommandQ.makeCommandBuffer() else
        {
            print("Error creating Metal command queue in MPSLaplacian.")
            CVMetalTextureCacheFlush(TextureCache!, 0)
            return nil
        }
        
        let Shader = MPSImageLaplacian(device: MetalDevice!)
        Shader.bias = Float(ParameterManager.GetDouble(From: ID(), Field: .Bias, Default: 0.5))
        Shader.encode(commandBuffer: CommandBuffer, sourceTexture: InputTexture, destinationTexture: OutputTexture)
        CommandBuffer.commit()
        CommandBuffer.waitUntilCompleted()
        
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
        return OutputBuffer
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
        Reset("MPSLaplacian.Initialize")
        CommandQueue = ImageDevice?.makeCommandQueue()
        IGTextureLoader = MTKTextureLoader(device: MetalDevice!)
        InitializedForImage = true
        ciContext = CIContext()
    }
    
    func CalculateCenter(Width: Int, Height: Int) -> Int
    {
        //Get the coordinates of the center.
        let MV = (Height / 2) + 1
        let MH = (Width / 2) + 1
        //Generate the index of the coordinates.
        let Index = (MV * Width) + MH
        return Index
    }
    
    func Render(Image: UIImage) -> UIImage?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        
        let CgImage = Image.cgImage
        let PixelBuffer = GetPixelBufferFrom(Image)
        let Width = CVPixelBufferGetWidth(PixelBuffer!)
        let Height = CVPixelBufferGetHeight(PixelBuffer!)
        
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
        let OutDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Width, height: Height, mipmapped: true)
        OutDesc.usage = [.shaderWrite, .shaderRead]
        let OutputTexture = ImageDevice!.makeTexture(descriptor: OutDesc)
        
        guard let CommandQ = CommandQueue,
            let CommandBuffer = CommandQ.makeCommandBuffer() else
        {
            print("Error creating Metal command queue in MPSLaplacian.")
            CVMetalTextureCacheFlush(TextureCache!, 0)
            return nil
        }
        
        let Shader = MPSImageLaplacian(device: MetalDevice!)
        Shader.bias = Float(ParameterManager.GetDouble(From: ID(), Field: .Bias, Default: 0.5))
        Shader.encode(commandBuffer: CommandBuffer, sourceTexture: InputTexture!, destinationTexture: OutputTexture!)
        CommandBuffer.commit()
        CommandBuffer.waitUntilCompleted()
        
        var ImageToReturn: UIImage? = nil
        let ciimage = CIImage(mtlTexture: OutputTexture!, options: nil)?.oriented(CGImagePropertyOrientation.downMirrored)
        let fcontext = CIContext(options: nil)
        let cgimage = fcontext.createCGImage(ciimage!, from: ciimage!.extent)
        ImageToReturn = UIImage(cgImage: cgimage!)
        LastUIImage = ImageToReturn
        
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
        return ImageToReturn
    }
    
    var ciContext: CIContext!
    
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
                print("Error converting UIImage to CIImage in MPSLaplacian.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in MPSLaplacian.Render(CIImage)")
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
        case .Bias:
            return (.DoubleType, 1.0 as Any?)
            
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
        return [.Bias,
                .RenderImageCount, .CumulativeImageRenderDuration, .RenderLiveCount, .CumulativeLiveRenderDuration]
    }
    
    func SettingsStoryboard() -> String?
    {
        return type(of: self).SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "LaplacianSettingsUI"
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
        Keywords.append("Filter: MPSImageLaplacian")
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
