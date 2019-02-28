//
//  CheckerboardGenerator.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage

class CheckerboardGenerator: FilterParent, Renderer
{
    static let _ID: UUID = UUID(uuidString: "3ce47bfb-30e6-4d24-b5f9-8f10fa2c564c")!
    
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
        return "Checkerboard"
    }
    
    func Title() -> String
    {
        return type(of: self).Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Checkerboard"
    
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
        Reset("CheckerboardGenerator.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CICheckerboardGenerator")
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
        return nil
    }
    
    func InitializeForImage()
    {
    }
    
    func Render(Image: UIImage) -> UIImage?
    {
        return nil
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        return nil
    }
    
    /// Returns the generated image. If the filter does not support generated images nil is returned.
    ///
    /// - Returns: Generated image on success, nil on failure.
    func Generate() -> CIImage?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        let Start = CACurrentMediaTime()
        PrimaryFilter = CIFilter(name: "CICheckerboardGenerator")
        PrimaryFilter?.setDefaults()
        
        let IWidth = ParameterManager.GetInt(From: ID(), Field: .IWidth, Default: 1024)
        let IHeight = ParameterManager.GetInt(From: ID(), Field: .IHeight, Default: 1024)
        //let Center = CIVector(x: CGFloat(IWidth) / 2.0, y: CGFloat(IHeight) / 2.0)
        let Center = CIVector(x: 0, y: 0)
        let Color0 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.black)
        let Color1 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.white)
        let BWidth = ParameterManager.GetDouble(From: ID(), Field: .PatternBlockWidth, Default: 80.0)
        let Sharpness = ParameterManager.GetDouble(From: ID(), Field: .Sharpness, Default: 1.0)

        PrimaryFilter?.setValue(Sharpness, forKey: kCIInputSharpnessKey)
        PrimaryFilter?.setValue(BWidth, forKey: kCIInputWidthKey)
        PrimaryFilter?.setValue(Center, forKey: kCIInputCenterKey)
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
        case .PatternBlockWidth:
            return (.DoubleType, 80.0 as Any?)
            
        case .Sharpness:
            return (.DoubleType, 1.0 as Any?)
            
        case .Color0:
            return (.ColorType, UIColor.black as Any?)
            
        case .Color1:
            return (.ColorType, UIColor.white as Any?)
            
        case .RenderImageCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeImageRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .RenderLiveCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeLiveRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .IWidth:
            return (.IntType, 1024 as Any?)
            
        case .IHeight:
            return (.IntType, 1024 as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return type(of: self).SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.PatternBlockWidth)
        Fields.append(.Sharpness)
        Fields.append(.Color0)
        Fields.append(.Color1)
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
        return type(of: self).SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "CheckerboardGeneratorSettingsUI"
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
        Keywords.append("Filter: CICheckerboardGenerator")
        Keywords.append("FilterType: CIFiltter")
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
        return type(of: self).Ports()
    }
}
