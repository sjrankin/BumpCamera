//
//  CircleAndLines.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage

class CircleAndLines: FilterParent, Renderer 
{
    static let _ID: UUID = UUID(uuidString: "0c84fc21-e06a-4b49-ae0e-90594abeeb4a")!
    
    func ID() -> UUID
    {
        return CircleAndLines._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    static func Title() -> String
    {
        return "Circle & Lines"
    }
    
    func Title() -> String
    {
        return CircleAndLines.Title()
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Circular and Linear Screen"
    
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
        Reset("CircleAndLines.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CILineScreen")
        SecondaryFilter = CIFilter(name: "CICircularScreen")
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
    
    //Primary filter is lines, secondary is circles
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        guard let PrimaryFilter = PrimaryFilter,
            let SecondaryFilter = SecondaryFilter,
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
        
        let Angle = ParameterManager.GetDouble(From: ID(), Field: .Angle, Default: 90.0)
        PrimaryFilter.setValue(Angle, forKey: kCIInputAngleKey)
        
        let Width = ParameterManager.GetDouble(From: ID(), Field: .Width, Default: 2.0)
        PrimaryFilter.setValue(Width, forKey: kCIInputWidthKey)
        
        let BufferWidth = CVPixelBufferGetWidth(PixelBuffer)
        let BufferHeight = CVPixelBufferGetHeight(PixelBuffer)
        let CenterX = BufferWidth / 2
        let CenterY = BufferHeight / 2
        let CenterVector = CIVector(x: CGFloat(CenterX), y: CGFloat(CenterY))
        PrimaryFilter.setValue(CenterVector, forKey: kCIInputCenterKey)
        
        guard let FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
        SecondaryFilter.setValue(Width, forKey: kCIInputWidthKey)
        SecondaryFilter.setValue(CenterVector, forKey: kCIInputCenterKey)
        SecondaryFilter.setValue(FilteredImage, forKey: kCIInputImageKey)
        
        guard var FilteredAgain = SecondaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter (again) failed to render image.")
            return nil
        }
        
        let Background = CIImage(cvImageBuffer: PixelBuffer)
        if DoMerge
        {
            if let Merged = Merge(FilteredAgain, Background)
            {
                FilteredAgain = Merged
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
            print("Allocation failure in CircularScreen.")
            return nil
        }
        
        Context.render(FilteredAgain, to: OutPixBuf, bounds: FilteredImage.extent, colorSpace: ColorSpace)
        
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

        let Start = CACurrentMediaTime()
        PrimaryFilter = CIFilter(name: "CILineScreen")
        SecondaryFilter = CIFilter(name: "CICircularScreen")
        PrimaryFilter?.setDefaults()
        PrimaryFilter?.setValue(Image, forKey: kCIInputImageKey)

        let DoMerge = ParameterManager.GetBool(From: ID(), Field: .MergeWithBackground, Default: true)
        
        let Angle = ParameterManager.GetDouble(From: ID(), Field: .Angle, Default: 90.0)
        PrimaryFilter?.setValue(Angle, forKey: kCIInputAngleKey)
        
        let Width = ParameterManager.GetDouble(From: ID(), Field: .Width, Default: 2.0)
        PrimaryFilter?.setValue(Width, forKey: kCIInputWidthKey)
        
        let BufferWidth = Image.extent.width
        let BufferHeight = Image.extent.height
        let CenterX = BufferWidth / 2
        let CenterY = BufferHeight / 2
        let CenterVector = CIVector(x: CGFloat(CenterX), y: CGFloat(CenterY))
        PrimaryFilter?.setValue(CenterVector, forKey: kCIInputCenterKey)
        
        if var Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            SecondaryFilter?.setValue(Width, forKey: kCIInputWidthKey)
            SecondaryFilter?.setValue(CenterVector, forKey: kCIInputCenterKey)
            SecondaryFilter?.setValue(Result, forKey: kCIInputImageKey)
            Result = (SecondaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage)!
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
        case .Width:
            return (.DoubleType, 5.0 as Any?)
            
        case .Angle:
            return (.DoubleType, 0.0 as Any?)
            
        case .MergeWithBackground:
            return (.BoolType, true as Any?)
            
        case .AdjustInLandscape:
            return (.BoolType, true as Any?)
            
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
        return CircleAndLines.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.Width)
        Fields.append(.Angle)
        Fields.append(.AdjustInLandscape)
        Fields.append(.MergeWithBackground)
        Fields.append(.RenderImageCount)
        Fields.append(.CumulativeImageRenderDuration)
        Fields.append(.RenderLiveCount)
        Fields.append(.CumulativeLiveRenderDuration)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return CircleAndLines.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "HalftoneSettingsUI"
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
        Keywords.append("Filter: CILineScreen")
        Keywords.append("Filter: CICircularScreen")
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
            return CircleAndLines.FilterKernel
        }
    }
    
    static var FilterKernel: FilterManager.FilterKernelTypes
    {
        get
        {
            return FilterManager.FilterKernelTypes.Metal
        }
    }
}
