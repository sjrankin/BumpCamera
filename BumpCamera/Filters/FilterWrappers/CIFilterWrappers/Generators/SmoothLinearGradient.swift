//
//  SmoothLinearGradient.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage

class SmoothLinearGradient: FilterParent, Renderer
{
    static let _ID: UUID = UUID(uuidString: "fb699e7d-b887-4ac5-a3a5-f6e33abe7a45")!
    
    func ID() -> UUID
    {
        return SmoothLinearGradient._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    static func Title() -> String
    {
        return "Linear Gradient"
    }
    
    func Title() -> String
    {
        return SmoothLinearGradient.Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Linear Gradient"
    
    var IconName: String = "Linear Gradient"
    
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
        Reset("SmoothLinearGradient.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CISmoothLinearGradient")
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
        #if false
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
        
        let Color0 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.darkGray)
        let Color1 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.yellow)
        let Point0 = ParameterManager.GetVector(From: ID(), Field: .Point0, Default: CIVector(x: 0, y: 0))
        let Point1 = ParameterManager.GetVector(From: ID(), Field: .Point1, Default: CIVector(x: 200, y: 200))
        
        PrimaryFilter.setValue(Point0, forKey: "inputPoint0")
        PrimaryFilter.setValue(Point1, forKey: "inputPoint1")
        PrimaryFilter.setValue(CIColor(cgColor: Color0.cgColor), forKey: "inputColor0")
        PrimaryFilter.setValue(CIColor(cgColor: Color1.cgColor), forKey: "inputColor1")
        
        guard let FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
        var PixBuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &PixBuf)
        guard let OutPixBuf = PixBuf else
        {
            print("Allocation failure in SmoothLinearGradient.")
            return nil
        }
        
        Context.render(FilteredImage, to: OutPixBuf, bounds: FilteredImage.extent, colorSpace: ColorSpace)
        
        LiveRenderTime = CACurrentMediaTime() - Start
        ParameterManager.UpdateRenderAccumulator(NewValue: LiveRenderTime, ID: ID(), ForImage: false)
        return OutPixBuf
        #else
        return nil
        #endif
    }
    
    func InitializeForImage()
    {
    }
    
    func Render(Image: UIImage) -> UIImage?
    {
        #if false
        if let CImage = CIImage(image: Image)
        {
            if let Result = Render(Image: CImage)
            {
                LastCIImage = Result
                let Final = UIImage(ciImage: Result)
                LastUIImage = Final
                return Final
            }
            else
            {
                print("Error returned Render.")
                return nil
            }
        }
        else
        {
            print("Error converting UIImage to CIImage.")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        #if false
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        PrimaryFilter = CIFilter(name: "CISmoothLinearGradient")
        PrimaryFilter?.setDefaults()
        
        let Color0 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.darkGray)
        let Color1 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.yellow)
        let Point0 = ParameterManager.GetVector(From: ID(), Field: .Point0, Default: CIVector(x: 0, y: 0))
        let Point1 = ParameterManager.GetVector(From: ID(), Field: .Point1, Default: CIVector(x: 200, y: 200))
        
        PrimaryFilter?.setValue(Point0, forKey: "inputPoint0")
        PrimaryFilter?.setValue(Point1, forKey: "inputPoint1")
        PrimaryFilter?.setValue(CIColor(cgColor: Color0.cgColor), forKey: "inputColor0")
        PrimaryFilter?.setValue(CIColor(cgColor: Color1.cgColor), forKey: "inputColor1")
        
        if let Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            LastCIImage = Result
            ImageRenderTime = CACurrentMediaTime() - Start
            ParameterManager.UpdateRenderAccumulator(NewValue: ImageRenderTime, ID: ID(), ForImage: true)
            return Result
        }
        #endif
        return nil
    }
    
    func IsNormal(_ Vector: CIVector) -> Bool
    {
        if Vector.x > 1.0 || Vector.x < 0.0
        {
            return false
        }
        if Vector.y > 1.0 || Vector.y < 0.0
        {
            return false
        }
        return true
    }
    
    /// Returns the generated image. If the filter does not support generated images nil is returned.
    ///
    /// - Returns: Generated image on success, nil on failure.
    func Generate() -> CIImage?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        PrimaryFilter = CIFilter(name: "CISmoothLinearGradient")
        PrimaryFilter?.setDefaults()
        
        let IWidth = ParameterManager.GetInt(From: ID(), Field: .IWidth, Default: 200)
        let IHeight = ParameterManager.GetInt(From: ID(), Field: .IHeight, Default: 200)
        let Color0 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.darkGray)
        let Color1 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.yellow)
        var Point0 = ParameterManager.GetVector(From: ID(), Field: .Point0, Default: CIVector(x: 0, y: 0))
        if IsNormal(Point0)
        {
            Point0 = CIVector(x: CGFloat(IWidth) * Point0.x, y: CGFloat(IHeight) * Point0.y)
        }
        var Point1 = ParameterManager.GetVector(From: ID(), Field: .Point1, Default: CIVector(x: 200, y: 200))
        if IsNormal(Point1)
        {
            Point1 = CIVector(x: CGFloat(IWidth) * Point1.x, y: CGFloat(IHeight) * Point1.y)
        }
        
        PrimaryFilter?.setValue(Point0, forKey: "inputPoint0")
        PrimaryFilter?.setValue(Point1, forKey: "inputPoint1")
        PrimaryFilter?.setValue(CIColor(cgColor: Color0.cgColor), forKey: "inputColor0")
        PrimaryFilter?.setValue(CIColor(cgColor: Color1.cgColor), forKey: "inputColor1")
        
        //Need to crop the result of the linear gradient in order to set valid dimensions.
        SecondaryFilter = CIFilter(name: "CICrop")
        SecondaryFilter?.setDefaults()
        let CropTo = CIVector(x: 0.0, y: 0.0, z: CGFloat(IWidth), w: CGFloat(IHeight))
        SecondaryFilter?.setValue(CropTo, forKey: "inputRectangle")
        SecondaryFilter?.setValue(PrimaryFilter?.outputImage, forKey: kCIInputImageKey)
        
        if let Result = SecondaryFilter?.outputImage
        {
            LastCIImage = Result
            ImageRenderTime = CACurrentMediaTime() - Start
            ParameterManager.UpdateRenderAccumulator(NewValue: ImageRenderTime, ID: ID(), ForImage: true)
            return Result
        }

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
            return (.ColorType, UIColor.red as Any?)
            
        case .Color1:
            return (.ColorType, UIColor.yellow as Any?)
            
        case .Point0:
            return (.PointType, CGPoint(x: 0, y: 0) as Any?)
            
        case .Point1:
            return (.PointType, CGPoint(x: 200, y: 200) as Any?)
            
        case .RenderImageCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeImageRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .RenderLiveCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeLiveRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .IWidth:
            return (.IntType, 200 as Any?)
            
        case .IHeight:
            return (.IntType, 200 as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return SmoothLinearGradient.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.Color0)
        Fields.append(.Color1)
        Fields.append(.Point0)
        Fields.append(.Point1)
        Fields.append(.IWidth)
        Fields.append(.IHeight)
        Fields.append(.RenderImageCount)
        Fields.append(.CumulativeImageRenderDuration)
        Fields.append(.RenderLiveCount)
        Fields.append(.CumulativeLiveRenderDuration)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return SmoothLinearGradient.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "SmoothLinearGradientSettingsUI"
    }
    
    func IsSlow() -> Bool
    {
        return false
    }
    
    public static func FilterTarget() -> [FilterTargets]
    {
        return [.Still]
    }
    
    func FilterTarget() -> [FilterTargets]
    {
        return SmoothLinearGradient.FilterTarget()
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
        Keywords.append("Filter: CISmoothLinearGradient")
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
            return SmoothLinearGradient.FilterKernel
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
        return [FilterPorts.Output]
    }
    
    /// Describes the available ports for the filter.
    ///
    /// - Returns: Array of ports.
    func Ports() -> [FilterPorts]
    {
        return SmoothLinearGradient.Ports()
    }
}
