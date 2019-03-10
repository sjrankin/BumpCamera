//
//  MetalCheckerboard.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit

class MetalCheckerboard: FilterParent, Renderer
{
    required override init()
    {
        let DefaultLibrary = MetalDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "MetalCheckerboard")
        do
        {
            ComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
    }
    
    static func Title() -> String
    {
        return "Metal Checkerboard"
    }
    
    func Title() -> String
    {
        return type(of: self).Title()
    }
    
    static let _ID: UUID = UUID(uuidString: "574e1f98-a7e3-496a-8e29-801191db5c83")!
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    func ID() -> UUID
    {
        return type(of: self)._ID
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "MetalCheckerboard"
    
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
        #if true
        Initialized = true
        #else
        Reset("MetalCheckerboard.Initialize")
        (BufferPool, _, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in MetalCheckerboard.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        
        Initialized = true
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in MetalCheckerboard.")
        }
        else
        {
            TextureCache = MetalTextureCache
        }
        #endif
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
        #if true
        return nil
        #else
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        if !Initialized
        {
            fatalError("MetalCheckerboard not initialized at Render(CVPixelBuffer) call.")
        }
        
        let Start = CACurrentMediaTime()
        let C1 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.black)
        let C2 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.white)
        let C3 = ParameterManager.GetColor(From: ID(), Field: .Color2, Default: UIColor.black)
        let C4 = ParameterManager.GetColor(From: ID(), Field: .Color3, Default: UIColor.white)
        let BlockSize = ParameterManager.GetDouble(From: ID(), Field: .PatternBlockWidth, Default: 32.0)
 
        let Parameter = CheckerboardParameters(Q1Color: C1.ToFloat4(),
                                               Q2Color: C2.ToFloat4(),
                                               Q3Color: C3.ToFloat4(),
                                               Q4Color: C4.ToFloat4(),
                                               BlockSize: simd_float1(BlockSize))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<CheckerboardParameters>.size, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<CheckerboardParameters>.size)
        
        var NewPixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &NewPixelBuffer)
        guard let OutputBuffer = NewPixelBuffer else
        {
            print("Allocation failure for new pixel buffer pool in MetalCheckerboard.")
            return nil
        }
        
        guard let InputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: PixelBuffer, textureFormat: .bgra8Unorm),
            let OutputTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: OutputBuffer, textureFormat: .bgra8Unorm) else
        {
            print("Error creating textures in MetalCheckerboard.")
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
        
        CommandEncoder.label = "MetalCheckerboard Generator"
        CommandEncoder.setBuffer(ParameterBuffer, offset: 0, index: 0)
        CommandEncoder.setComputePipelineState(ComputePipelineState!)
        CommandEncoder.setTexture(InputTexture, index: 0)
        CommandEncoder.setTexture(OutputTexture, index: 1)
        
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
        #endif
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
        let KernelFunction = DefaultLibrary?.makeFunction(name: "MetalCheckerboard")
        do
        {
            ImageComputePipelineState = try MetalDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Unable to create pipeline state: \(error.localizedDescription)")
        }
        
        var MetalTextureCache: CVMetalTextureCache? = nil
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice!, nil, &MetalTextureCache) != kCVReturnSuccess
        {
            fatalError("Unable to allocation texture cache in MetalCheckerboard.")
        }
        else
        {
            TextureCache = MetalTextureCache
        }
        
        InitializedForImage = true
    }
    
    var InputParameterBuffer: MTLBuffer! = nil
    
    //http://flexmonkey.blogspot.com/2014/10/metal-kernel-functions-compute-shaders.html
    func Render(Image: UIImage) -> UIImage?
    {
        #if true
        return nil
        #else
        if !InitializedForImage
        {
            fatalError("Not initialized.")
        }
        
        let Start = CACurrentMediaTime()
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
            print("Error creating input texture in MetalCheckerboard.Render.")
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
        
        let C1 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.black)
        let C2 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.white)
        let C3 = ParameterManager.GetColor(From: ID(), Field: .Color2, Default: UIColor.black)
        let C4 = ParameterManager.GetColor(From: ID(), Field: .Color3, Default: UIColor.white)
        let BlockSize = ParameterManager.GetDouble(From: ID(), Field: .PatternBlockWidth, Default: 32.0)
        
        let Parameter = CheckerboardParameters(Q1Color: C1.ToFloat4(),
                                               Q2Color: C2.ToFloat4(),
                                               Q3Color: C3.ToFloat4(),
                                               Q4Color: C4.ToFloat4(),
                                               BlockSize: simd_float1(BlockSize))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<CheckerboardParameters>.size, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<CheckerboardParameters>.size)
        CommandEncoder?.setBuffer(InputParameterBuffer, offset: 0, index: 0)
        
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
        #endif
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        #if true
        return nil
        #else
        let UImage = UIImage(ciImage: Image)
        if let IFinal = Render(Image: UImage)
        {
            if let CFinal = IFinal.ciImage
            {
                LastCIImage = CFinal;
                return CFinal
            }
            else
            {
                print("Error converting UIImage to CIImage in MetalCheckerboard.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in MetalCheckerboard.Render(CIImage)")
            return nil
        }
        #endif
    }
    
    /// Returns the generated image. If the filter does not support generated images nil is returned.
    ///
    /// - Note: Call InitializeForImage on this instance to initialize for image generation.
    ///
    /// - Returns: Nil is always returned.
    func Generate() -> CIImage?
    {
        if !InitializedForImage
        {
            fatalError("Not initialized.")
        }
        
        let Start = CACurrentMediaTime()
        let IWidth = ParameterManager.GetInt(From: ID(), Field: .IWidth, Default: 512)
        let IHeight = ParameterManager.GetInt(From: ID(), Field: .IHeight, Default: 512)
        
        var DummyImage: UIImage!
        if let duImage = UIImage.MakeColorImage(SolidColor: UIColor.red, Size: CGSize(width: IWidth, height: IHeight))
        {
            DummyImage = duImage
        }
        else
        {
            print("Error returned by MakeColorImage.")
            return nil
        }
        
        var DummyTexture: MTLTexture!
        if let DummyBuffer = GetPixelBufferFrom(DummyImage)
        {
            DummyTexture = MakeTextureFromCVPixelBuffer(pixelBuffer: DummyBuffer, textureFormat: .bgra8Unorm)
        }
        else
        {
            print("Error returned by GetPixelBufferFrom")
            return nil
        }
        
        let TextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                         width: Int(IWidth), height: Int(IHeight), mipmapped: true)
        guard let Texture = ImageDevice?.makeTexture(descriptor: TextureDescriptor) else
        {
            print("Error creating input texture in MetalCheckerboard.Generate.")
            return nil
        }
        
        let ResultCount = 10
        let ResultsBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<ReturnBufferType>.stride * ResultCount, options: [])
        let Results = UnsafeBufferPointer<ReturnBufferType>(start: UnsafePointer(ResultsBuffer!.contents().assumingMemoryBound(to: ReturnBufferType.self)),
                                                            count: ResultCount)
        
        let Region = MTLRegionMake2D(0, 0, Int(IWidth), Int(IHeight))
        var RawData = [UInt8](repeating: 0, count: Int(IWidth * IHeight * 4))
        let IBytesPerRow = 4 * IWidth
        Texture.replace(region: Region, mipmapLevel: 0, withBytes: &RawData, bytesPerRow: IBytesPerRow)
        let OutputTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Texture.pixelFormat,
                                                                               width: Texture.width, height: Texture.height,
                                                                               mipmapped: true)
        OutputTextureDescriptor.usage = MTLTextureUsage.shaderWrite
        let OutputTexture = ImageDevice?.makeTexture(descriptor: OutputTextureDescriptor)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(DummyTexture, index: 0)
        CommandEncoder?.setTexture(OutputTexture, index: 1)
        
        let C1 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.black)
        let C2 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.white)
        let C3 = ParameterManager.GetColor(From: ID(), Field: .Color2, Default: UIColor.black)
        let C4 = ParameterManager.GetColor(From: ID(), Field: .Color3, Default: UIColor.white)
        let BlockSize = ParameterManager.GetDouble(From: ID(), Field: .PatternBlockWidth, Default: 32.0)
        
        let Parameter = CheckerboardParameters(Q1Color: C1.ToFloat4(),
                                               Q2Color: C2.ToFloat4(),
                                               Q3Color: C3.ToFloat4(),
                                               Q4Color: C4.ToFloat4(),
                                               BlockSize: simd_float1(BlockSize))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<CheckerboardParameters>.stride, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<CheckerboardParameters>.stride)
        
        CommandEncoder?.setBuffer(ParameterBuffer, offset: 0, index: 0)
        CommandEncoder?.setBuffer(ResultsBuffer, offset: 0, index: 1)
        
        let ThreadGroupCount  = MTLSizeMake(8, 8, 1)
        let ThreadGroups = MTLSizeMake(Texture.width / ThreadGroupCount.width,
                                       Texture.height / ThreadGroupCount.height,
                                       1)
        
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        
        CommandEncoder!.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder!.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        
        //Get the result of the generated image.
        let ImageSize = CGSize(width: Texture.width, height: Texture.height)
        let ImageByteCount = Int(ImageSize.width * ImageSize.height * 4)
        var ImageBytes = [UInt8](repeating: 0, count: ImageByteCount)
        let ORegion = MTLRegionMake2D(0, 0, Int(ImageSize.width), Int(ImageSize.height))
        OutputTexture?.getBytes(&ImageBytes, bytesPerRow: IBytesPerRow, from: ORegion, mipmapLevel: 0)
        
        let SizeOfUInt8 = UInt8.SizeOf()
        let Provider = CGDataProvider(data: NSData(bytes: &ImageBytes, length: ImageBytes.count * SizeOfUInt8))
        let OBitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        let RenderingIntent = CGColorRenderingIntent.defaultIntent
        let FinalImage = CGImage(width: Int(ImageSize.width), height: Int(ImageSize.height),
                                 bitsPerComponent: 8, bitsPerPixel: 32,
                                 bytesPerRow: IBytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: OBitmapInfo, provider: Provider!,
                                 decode: nil, shouldInterpolate: false, intent: RenderingIntent)
        LastUIImage = UIImage(cgImage: FinalImage!)
        
        #if DEBUG
        for V in Results
        {
            if V > 0
            {
                print("V=\(V)")
            }
        }
        #endif
        
        ImageRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: ImageRenderTime, ID: ID(), ForImage: true)
        let Final = CIImage(cgImage: FinalImage!)
        return Final
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
        case .Color0:
            return (.ColorType, UIColor.black as Any?)
            
        case .Color1:
            return (.ColorType, UIColor.white as Any?)
            
        case .Color2:
            return (.ColorType, UIColor.black as Any?)
            
        case .Color3:
            return (.ColorType, UIColor.white as Any?)
            
        case .IWidth:
            return (.IntType, 512 as Any?)
            
        case .IHeight:
            return (.IntType, 512 as Any?)
            
        case .PatternBlockWidth:
            return (.IntType, 64 as Any?)
            
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
        return [.Color0, .Color1, .Color2, .Color3, .PatternBlockWidth, .IWidth, .IHeight,
        .RenderImageCount, .CumulativeImageRenderDuration, .RenderLiveCount, .CumulativeLiveRenderDuration]
    }
    
    func SettingsStoryboard() -> String?
    {
        return type(of: self).SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "MetalCheckerboardGeneratorSettingsUI"
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
    ///   - Reset: If true, the cumulative render time is reset to 0.0 for the type of data being returned.
    /// - Returns: The number of seconds it took to render the for the type of data specified by ForImage.
    public func RenderTime(ForImage: Bool, Reset: Bool = false) -> Double
    {
        let Final = ForImage ? ImageRenderTime : LiveRenderTime
        if Reset
        {
            ParameterManager.ResetRenderAccumulator(ID: ID(), ForImage: ForImage)
        }
        return Final
    }
    
    /// Returns a list of strings intended to be used as key words in Exif data.
    ///
    /// - Returns: List of key words associated with the filter, including setting values.
    func ExifKeyWords() -> [String]
    {
        var Keywords = [String]()
        Keywords.append("Filter: GridGenerator")
        Keywords.append("FilterType: Checkerboard Generator")
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
        return [FilterPorts.Output]
    }
    
    /// Describes the available ports for the filter.
    ///
    /// - Returns: Array of ports.
    func Ports() -> [FilterPorts]
    {
        return type(of: self).Ports()
    }
}
