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
        
        let SourceImage = CIImage(cvImageBuffer: PixelBuffer)
        PrimaryFilter.setDefaults()
        PrimaryFilter.setValue(SourceImage, forKey: kCIInputImageKey)
        var DoMerge = false
        let AngleAsAny = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Angle)
        if let Angle = AngleAsAny as? Double
        {
            PrimaryFilter.setValue(Angle, forKey: kCIInputAngleKey)
        }
        let WidthAsAny = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Width)
        if let Width = WidthAsAny as? Double
        {
            PrimaryFilter.setValue(Width, forKey: kCIInputWidthKey)
        }
        let CenterAsAny = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Center)
        if let Center = CenterAsAny as? CGPoint
        {
            let CVCenter = CIVector(x: Center.x, y: Center.y)
            PrimaryFilter.setValue(CVCenter, forKey: kCIInputCenterKey)
        }
        let MergeAsAny = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.MergeWithBackground)
        if let MergeImages = MergeAsAny as? Bool
        {
            DoMerge = MergeImages
        }
        
        guard let FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
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

        PrimaryFilter = CIFilter(name: "CILineScreen")
        SecondaryFilter = CIFilter(name: "CICircularScreen")
        PrimaryFilter?.setDefaults()
        PrimaryFilter?.setValue(Image, forKey: kCIInputImageKey)
        let AngleAsAny = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Angle)
        if let Angle = AngleAsAny as? Double
        {
            PrimaryFilter?.setValue(Angle, forKey: kCIInputAngleKey)
        }
        let WidthAsAny = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Width)
        if let Width = WidthAsAny as? Double
        {
            PrimaryFilter?.setValue(Width, forKey: kCIInputWidthKey)
        }
        let CenterAsAny = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.Center)
        if let Center = CenterAsAny as? CGPoint
        {
            let CVCenter = CIVector(x: Center.x, y: Center.y)
            PrimaryFilter?.setValue(CVCenter, forKey: kCIInputCenterKey)
        }
        var DoMerge = false
        let MergeAsAny = ParameterManager.GetField(From: ID(), Field: FilterManager.InputFields.MergeWithBackground)
        if let MergeImages = MergeAsAny as? Bool
        {
            DoMerge = MergeImages
        }
        
        if var Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            SecondaryFilter?.setValue(Result, forKey: kCIInputImageKey)
            Result = (SecondaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage)!
            #if true
            var Rotated = Result
            #else
            var Rotated = RotateImage(Result)
            #endif
            if DoMerge
            {
                Rotated = Merge(Rotated, Image)!
            }
            LastCIImage = Rotated
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
            
        case .Center:
            return (.PointType, CGPoint(x: 0.0, y: 0.0) as Any?)
            
        case .CenterInImage:
            return (.BoolType, true as Any?)
            
        case .MergeWithBackground:
            return (.BoolType, true as Any?)
            
        case .AdjustInLandscape:
            return (.BoolType, true as Any?)
            
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
        Fields.append(.Center)
        Fields.append(.CenterInImage)
        Fields.append(.AdjustInLandscape)
        Fields.append(.MergeWithBackground)
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
}
