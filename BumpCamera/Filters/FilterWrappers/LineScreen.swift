//
//  LineScreen.swift
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

class LineScreen: FilterParent, Renderer
{
    static let _ID: UUID = UUID(uuidString: "03d25ebe-1536-4088-9af6-150490262467")!
    
    func ID() -> UUID
    {
        return LineScreen._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Line Screen"
    
    var IconName: String = "LineScreenMerged"
    
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
        Reset("LineScreen.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CILineScreen")
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
        
        let SourceImage = CIImage(cvImageBuffer: PixelBuffer)
        Utility.print1("Image size=\(SourceImage.extent)")
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
            print("Allocation failure in LineScreen.")
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

        PrimaryFilter = CIFilter(name: "CILineScreen")
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
        
        if let Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
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
            return (FilterManager.InputTypes.DoubleType, 5.0 as Any?)
            
        case .Angle:
            return (FilterManager.InputTypes.DoubleType, 90.0 as Any?)
            
        case .MergeWithBackground:
            return (FilterManager.InputTypes.BoolType, true as Any?)
            
        case .AdjustInLandscape:
            return (FilterManager.InputTypes.BoolType, true as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return LineScreen.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.Width)
        Fields.append(.Angle)
        Fields.append(.AdjustInLandscape)
        Fields.append(.MergeWithBackground)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return LineScreen.SettingsStoryboard()
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
