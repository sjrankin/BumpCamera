//
//  ConvolutionEmboss.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import MetalKit

class ConvolutionEmboss: FilterParent, Renderer
{
    required override init()
    {
    }
    
    static let _ID: UUID = UUID(uuidString: "e0815998-faf5-4b6c-bd4b-f566def8a125")!
    
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
        return "ConvolutionEmboss"
    }
    
    func Title() -> String
    {
        return type(of: self).Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "ConvolutionEmboss"
    
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
        InputFormatDescription = FormatDescription
        Initialized = true
    }
    
    func Reset(_ CalledBy: String = "")
    {
    }
    
    func Reset()
    {
        Reset("")
    }
    
    var AccessLock = NSObject()
    
    var ParameterBuffer: MTLBuffer! = nil
    var PreviousDebug = ""
    
    func Render(PixelBuffer: CVPixelBuffer, AltSettings: FilterSettingsBlob) -> CVPixelBuffer?
    {
        if !Initialized
        {
            print("Initialize not called for ConvolveEmboss")
            return nil
        }
       let Convolve = Convolution()
        Convolve.Initialize(With: InputFormatDescription!, BufferCountHint: 3)
        return Convolve.Render(PixelBuffer: PixelBuffer, AltSettings: AltSettings)
    }
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        if !Initialized
        {
            print("Initialize not called.")
            return nil
        }
        let Blob = MakeFilterBlob(For: self)
        Blob.AddSetting(.ConvolutionBias, ParameterManager.GetDouble(From: ID(), Field: .ConvolutionBias, Default: 0.0))
        Blob.AddSetting(.ConvolutionFactor, ParameterManager.GetDouble(From: ID(), Field: .ConvolutionFactor, Default: 1.0))
        Blob.AddSetting(.ConvolutionWidth, ParameterManager.GetInt(From: ID(), Field: .ConvolutionWidth, Default: 3))
        Blob.AddSetting(.ConvolutionHeight, ParameterManager.GetInt(From: ID(), Field: .ConvolutionHeight, Default: 3))
        Blob.AddSetting(.ConvolutionKernel, ParameterManager.GetString(From: ID(), Field: .ConvolutionKernel, Default: ""))
        let Convolve = Convolution()
        Convolve.Initialize(With: InputFormatDescription!, BufferCountHint: 3)
        return Convolve.Render(PixelBuffer: PixelBuffer, AltSettings: Blob)
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
        InitializedForImage = true
    }
    
    //http://flexmonkey.blogspot.com/2014/10/metal-kernel-functions-compute-shaders.html
    func Render(Image: UIImage, AltSettings: FilterSettingsBlob) -> UIImage?
    {
       if !InitializedForImage
       {
        print("InitializeForImage not called.")
        return nil
        }
        let Convolve = Convolution()
        Convolve.InitializeForImage()
        return Convolve.Render(Image: Image, AltSettings: AltSettings)
    }
    
    func Render(Image: UIImage) -> UIImage?
    {
        if !InitializedForImage
        {
            print("InitializeForImage not called.")
            return nil
        }
        let Blob = MakeFilterBlob(For: self)
        Blob.AddSetting(.ConvolutionBias, ParameterManager.GetDouble(From: ID(), Field: .ConvolutionBias, Default: 0.0))
        Blob.AddSetting(.ConvolutionFactor, ParameterManager.GetDouble(From: ID(), Field: .ConvolutionFactor, Default: 1.0))
        Blob.AddSetting(.ConvolutionWidth, ParameterManager.GetInt(From: ID(), Field: .ConvolutionWidth, Default: 3))
        Blob.AddSetting(.ConvolutionHeight, ParameterManager.GetInt(From: ID(), Field: .ConvolutionHeight, Default: 3))
        Blob.AddSetting(.ConvolutionKernel, ParameterManager.GetString(From: ID(), Field: .ConvolutionKernel, Default: ""))
        let Convolve = Convolution()
        Convolve.InitializeForImage()
        return Convolve.Render(Image: Image, AltSettings: Blob)
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
                print("Error converting UIImage to CIImage in Convolution.Render(CIImage)")
                return nil
            }
        }
        else
        {
            print("Error returned from Render(UIImage) in Convolution.Render(CIImage)")
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
        case .ConvolutionFactor:
            return (.DoubleType, 1.0 as Any?)
            
        case .ConvolutionBias:
            return (.DoubleType, 0.0 as Any?)
            
        case .ConvolutionWidth:
            return (.IntType, 3 as Any?)
            
        case .ConvolutionHeight:
            return (.IntType, 3 as Any?)
            
        case .ConvolutionKernel:
            return (.StringType, "" as Any?)
            
        case .CurrentKernelIndex:
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
            return (.NoType, nil)
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return type(of: self).SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        return [.ConvolutionWidth, .ConvolutionHeight, .ConvolutionKernel, .CurrentKernelIndex,
                .ConvolutionBias, .ConvolutionFactor,
                .RenderImageCount, .CumulativeImageRenderDuration, .RenderLiveCount, .CumulativeLiveRenderDuration]
    }
    
    func SettingsStoryboard() -> String?
    {
        return type(of: self).SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "ConvolutionEmbossSettingsUI"
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
        Keywords.append("Filter: ConvolutionEmboss")
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

