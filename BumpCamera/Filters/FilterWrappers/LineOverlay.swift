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
        case .InputContrast:
            return (FilterManager.InputTypes.DoubleType, 5.0 as Any?)
            
        case .InputThreshold:
            return (FilterManager.InputTypes.DoubleType, 0.0 as Any?)
            
        case .EdgeIntensity:
            return (FilterManager.InputTypes.DoubleType, 1.0 as Any?)
            
        case .MergeWithBackground:
            return (FilterManager.InputTypes.BoolType, true as Any?)
            
        case .NRSharpness:
            return (FilterManager.InputTypes.DoubleType, 0.71 as Any?)
            
        case .NRNoiseLevel:
            return (FilterManager.InputTypes.DoubleType, 0.07 as Any?)
            
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
    
    func FilterTarget() -> [FilterTargets]
    {
        return [.LiveView, .Video, .Still]
    }
}
