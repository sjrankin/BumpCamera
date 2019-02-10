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
        
        let FinalCommand = ParameterManager.GetInt(From: ID(), Field: .Command, Default: 0)
        let RMul = ParameterManager.GetDouble(From: ID(), Field: .RAdjustment, Default: 0.3)
        let GMul = ParameterManager.GetDouble(From: ID(), Field: .GAdjustment, Default: 0.5)
        let BMul = ParameterManager.GetDouble(From: ID(), Field: .BAdjustment, Default: 0.2)
        let Parameter = GrayscaleParameters(Command: simd_int1(FinalCommand), RMultiplier: simd_float1(RMul),
                                            GMultiplier: simd_float1(GMul), BMultiplier: simd_float1(BMul))
        let Parameters = [Parameter]
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<GrayscaleParameters>.size, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<GrayscaleParameters>.size)
        
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
        ParameterBuffer = MetalDevice!.makeBuffer(length: MemoryLayout<GrayscaleParameters>.size, options: [])
        memcpy(ParameterBuffer.contents(), Parameters, MemoryLayout<GrayscaleParameters>.size)
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
            
        case .ByParameters:
            return "Enter values below to multiply against the red, green, and blue channels. Values must add up to 1.0 or no action will be taken."
        }
    }
    
    public static func GrayscaleTypesInOrder() -> [GrayscaleTypes]
    {
        return [.Mean, .Luma, .Desaturation, .BT601, .BT709, .MaxDecomposition, .MinDecomposition,
                .Red, .Green, .Blue, .Cyan, .Magenta, .Yellow, .Hue, .Saturation, .Brightness, .ByParameters]
    }
    
    public static func GetGrayscaleTypeFromCommandIndex(_ Index: Int) -> GrayscaleTypes
    {
        return GrayscaleTypes(rawValue: Index)!
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
    case ByParameters = 100
}
