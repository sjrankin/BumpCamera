//
//  LineOverlay.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/17/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage

class LineOverlay: FilterParent, Renderer
{
    static let _ID: UUID = UUID(uuidString: "910d04a3-729d-4fdf-b19e-654904b0eeeb")!
    
    func ID() -> UUID
    {
        return LineOverlay._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    static func Title() -> String
    {
        return "Line Overlay"
    }
    
    func Title() -> String
    {
        return LineOverlay.Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Line Overlay"
    
    var IconName: String = ""
    
    var Initialized = false
    
    private var PrimaryFilter: CIFilter? = nil
    
    private var SecondaryFilter: CIFilter? = nil
    
    private var InvertFilter: CIFilter? = nil
    
    private var AlphaMaskFilter: CIFilter? = nil
    
    private var MergeSourceAtop: CIFilter? = nil
    
    private var Context: CIContext? = nil
    
    private var BufferPool: CVPixelBufferPool? = nil
    
    private var ColorSpace: CGColorSpace? = nil
    
    private(set) var OutputFormatDescription: CMFormatDescription? = nil
    
    private(set) var InputFormatDescription: CMFormatDescription? = nil
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    {
        Reset("LineOverlay.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CILineOverlay")
        InvertFilter = CIFilter(name: "CIColorInvert")
        AlphaMaskFilter = CIFilter(name: "CIMaskToAlpha")
        MergeSourceAtop = CIFilter(name: "CISourceAtopCompositing")
        Initialized = true
    }
    
    func Reset(_ CalledBy: String = "")
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        Context = nil
        PrimaryFilter = nil
        SecondaryFilter = nil
        InvertFilter = nil
        AlphaMaskFilter = nil
        MergeSourceAtop = nil
        ColorSpace = nil
        BufferPool = nil
        OutputFormatDescription = nil
        InputFormatDescription = nil
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
        guard let PrimaryFilter = PrimaryFilter,
            let Context = Context,
            Initialized else
        {
            print("Filter not initialized.")
            return nil
        }
        
        let Start = CACurrentMediaTime()
        let SourceImage = CIImage(cvImageBuffer: PixelBuffer)
        PrimaryFilter.setDefaults()
        PrimaryFilter.setValue(SourceImage, forKey: kCIInputImageKey)
        
        let DoMerge = ParameterManager.GetBool(From: ID(), Field: .MergeWithBackground, Default: true)
        PrimaryFilter.setValue(ParameterManager.GetDouble(From: ID(), Field: .EdgeIntensity, Default: 1.0), forKey: "inputEdgeIntensity")
        PrimaryFilter.setValue(ParameterManager.GetDouble(From: ID(), Field: .InputContrast, Default: 50.0), forKey: "inputContrast")
        PrimaryFilter.setValue(ParameterManager.GetDouble(From: ID(), Field: .InputThreshold, Default: 0.0), forKey: "inputThreshold")
        PrimaryFilter.setValue(ParameterManager.GetDouble(From: ID(), Field: .NRNoiseLevel, Default: 0.07), forKey: "inputNRNoiseLevel")
        PrimaryFilter.setValue(ParameterManager.GetDouble(From: ID(), Field: .NRSharpness, Default: 0.71), forKey: "inputNRSharpness")
        
        guard var FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
        if DoMerge
        {
            let Background = CIImage(cvImageBuffer: PixelBuffer)
            if let Merged = Merge(FilteredImage, Background)
            {
                FilteredImage = Merged
            }
            else
            {
                print("Error returned from merge operation.")
                return nil
            }
        }
        
        var PixBuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &PixBuf)
        guard let OutPixBuf = PixBuf else
        {
            print("Allocation failure in LineOverlay.")
            return nil
        }
        
        Context.render(FilteredImage, to: OutPixBuf, bounds: FilteredImage.extent, colorSpace: ColorSpace)
        
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
        return OutPixBuf
    }
    
    func InitializeForImage()
    {
    }
    
    func Render(Image: UIImage) -> UIImage?
    {
        if let CImage = CIImage(image: Image)
        {
            if let Result = Render(Image: CImage)
            {
                LastCIImage = Result
                var Final = UIImage(ciImage: Result)
                if let cgimg = Final.cgImage
                {
                    Final = UIImage(cgImage: cgimg)
                }
                LastUIImage = Final
                return Final
            }
            else
            {
                print("Render returned error.")
                return nil
            }
        }
        else
        {
            print("Error converting UIImage to CIImage.")
            return nil
        }
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}

        let Start = CACurrentMediaTime()
        PrimaryFilter = CIFilter(name: "CILineOverlay")
        PrimaryFilter?.setDefaults()
        PrimaryFilter?.setValue(Image, forKey: kCIInputImageKey)
        
        let DoMerge = ParameterManager.GetBool(From: ID(), Field: .MergeWithBackground, Default: true)
        PrimaryFilter?.setValue(ParameterManager.GetDouble(From: ID(), Field: .EdgeIntensity, Default: 1.0), forKey: "inputEdgeIntensity")
        PrimaryFilter?.setValue(ParameterManager.GetDouble(From: ID(), Field: .InputContrast, Default: 50.0), forKey: "inputContrast")
        PrimaryFilter?.setValue(ParameterManager.GetDouble(From: ID(), Field: .InputThreshold, Default: 0.0), forKey: "inputThreshold")
        PrimaryFilter?.setValue(ParameterManager.GetDouble(From: ID(), Field: .NRNoiseLevel, Default: 0.07), forKey: "inputNRNoiseLevel")
        PrimaryFilter?.setValue(ParameterManager.GetDouble(From: ID(), Field: .NRSharpness, Default: 0.71), forKey: "inputNRSharpness")
        
        if let Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            var Rotated = Result
            if DoMerge
            {
                Rotated = Merge(Rotated, Image)!
            }
            LastCIImage = Rotated
            ImageRenderTime = CACurrentMediaTime() - Start
            ParameterManager.UpdateRenderAccumulator(NewValue: ImageRenderTime, ID: ID(), ForImage: true)
            return Rotated
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
        case .InputContrast:
            return (.DoubleType, 5.0 as Any?)
            
        case .InputThreshold:
            return (.DoubleType, 0.0 as Any?)
            
        case .EdgeIntensity:
            return (.DoubleType, 1.0 as Any?)
            
        case .MergeWithBackground:
            return (.BoolType, true as Any?)
            
        case .NRSharpness:
            return (.DoubleType, 0.71 as Any?)
            
        case .NRNoiseLevel:
            return (.DoubleType, 0.07 as Any?)
            
        case .RenderImageCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeImageRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .RenderLiveCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeLiveRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return LineOverlay.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.InputContrast)
        Fields.append(.InputThreshold)
        Fields.append(.EdgeIntensity)
        Fields.append(.NRNoiseLevel)
        Fields.append(.NRSharpness)
        Fields.append(.MergeWithBackground)
        Fields.append(.RenderImageCount)
        Fields.append(.CumulativeImageRenderDuration)
        Fields.append(.RenderLiveCount)
        Fields.append(.CumulativeLiveRenderDuration)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return LineOverlay.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "LineOverlaySettingsUI"
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
        return LineOverlay.FilterTarget()
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
        Keywords.append("Filter: CILineOverlay")
        Keywords.append("FilterType: CIFilter")
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
            return LineOverlay.FilterKernel
        }
    }
    
    static var FilterKernel: FilterManager.FilterKernelTypes
    {
        get
        {
            return FilterManager.FilterKernelTypes.CIFilter
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
        return LineOverlay.Ports()
    }
}
