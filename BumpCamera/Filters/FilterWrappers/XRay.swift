//
//  XRay.swift
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

class XRay: FilterParent, Renderer
{
    static let _ID: UUID = UUID(uuidString: "47d5ac1d-7878-4623-b3df-55559b9d7087")!
    
    func ID() -> UUID
    {
        return XRay._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "X-Ray"
    
    var IconName: String = "X-Ray"
    
    var Initialized = false
    
    private var PrimaryFilter: CIFilter? = nil
    
    private var SecondaryFilter: CIFilter? = nil
    
    private var Context: CIContext? = nil
    
    private var BufferPool: CVPixelBufferPool? = nil
    
    private var ColorSpace: CGColorSpace? = nil
    
    private(set) var OutputFormatDescription: CMFormatDescription? = nil
    
    private(set) var InputFormatDescription: CMFormatDescription? = nil
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    {
        Reset("XRay.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in XRay.Initialize.")
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CIXRay")
        Initialized = true
    }
    
    func Reset(_ CalledBy: String = "")
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        Context = nil
        PrimaryFilter = nil
        ColorSpace = nil
        //print("Setting BufferPool to nil in xray, called by \(CalledBy).")
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
        if BufferPool == nil
        {
            print("BufferPool nil in XRay.Render.")
            return nil
        }
        guard let PrimaryFilter = PrimaryFilter,
            let Context = Context,
            Initialized else
        {
            print("Filter not initialized.")
            return nil
        }
        
        let SourceImage = CIImage(cvImageBuffer: PixelBuffer)
        PrimaryFilter.setDefaults()
        PrimaryFilter.setValue(SourceImage, forKey: kCIInputImageKey)
        
        guard let FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
        if BufferPool == nil
        {
            print("BufferPool nil in xray after initial OK check.")
        }
        var PixBuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &PixBuf)
        guard let OutPixBuf = PixBuf else
        {
            print("Allocation failure in X-Ray.")
            return nil
        }
        
        Context.render(FilteredImage, to: OutPixBuf, bounds: FilteredImage.extent, colorSpace: ColorSpace)
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
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        
        PrimaryFilter = CIFilter(name: "CIXRay")
        PrimaryFilter?.setDefaults()
        PrimaryFilter?.setValue(Image, forKey: kCIInputImageKey)
        if let Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            #if true
            LastCIImage = Result
            return Result
            #else
            let Rotated = RotateImage(Result)
            return Rotated
            #endif
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
        case .RenderImageCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeImageRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        case .RenderLiveCount:
            return (.IntType, 0 as Any?)
            
        case .CumulativeLiveRenderDuration:
            return (.DoubleType, 0.0 as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered.")
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return XRay.SupportedFields()
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
        return XRay.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "NoParametersSettingsUI"
    }
    
    func IsSlow() -> Bool
    {
        return false
    }
    
    func FilterTarget() -> [FilterTargets]
    {
        return [.LiveView, .Video, .Still]
    }
    
    private var ImageRenderStart: Double = 0.0
    private var LiveRenderStart: Double = 0.0
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
        Keywords.append("Filter: CIEdgeWork")
        Keywords.append("FilterType: CIXRay")
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
            return FilterManager.FilterKernelTypes.CIFilter
        }
    }
}
