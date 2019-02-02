//
//  HSB.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage

class HSBAdjust: FilterParent, Renderer
{
    var _ID: UUID = UUID(uuidString: "ff3679e7-a415-4562-8032-e07f51a63621")!
    var ID: UUID
    {
        get
        {
            return _ID
        }
        set
        {
            _ID = newValue
        }
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "Color Adjust"
    
    var IconName: String = "Color Adjust"
    
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
        Reset("HueAdjust.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            print("BufferPool nil in HSBAdjust.")
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CIColorControls")
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
            print("BufferPool nil in HSBAdjust.")
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
        
        let SatAsAny = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.InputSaturation)
        if let Sat = SatAsAny as? Double
        {
            PrimaryFilter.setValue(Float(Sat), forKey: kCIInputSaturationKey)
        }
        let BriAsAny = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.InputBrightness)
        if let Bri = BriAsAny as? Double
        {
            PrimaryFilter.setValue(Float(Bri), forKey: kCIInputBrightnessKey)
        }
        let ConAsAny = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.InputCContrast)
        if let Con = ConAsAny as? Double
        {
            PrimaryFilter.setValue(Float(Con), forKey: kCIInputContrastKey)
        }
        
        guard let FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
        if BufferPool == nil
        {
            print("BufferPool nil in HSBAdjust after initial OK check.")
            return nil
        }
        var PixBuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &PixBuf)
        guard let OutPixBuf = PixBuf else
        {
            print("Allocation failure in HSB Adjust.")
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
                let Final = UIImage(ciImage: Result)
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
        #if false
        guard let PrimaryFilter = PrimaryFilter,
            Initialized else
        {
            print("Filter not initialized.")
            return nil
        }
        #endif
        PrimaryFilter = CIFilter(name: "CIColorControls")
        PrimaryFilter?.setDefaults()
        PrimaryFilter?.setValue(Image, forKey: kCIInputImageKey)
        
        let SatAsAny = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.InputSaturation)
        if let Sat = SatAsAny as? Double
        {
            PrimaryFilter?.setValue(Float(Sat), forKey: kCIInputSaturationKey)
        }
        let BriAsAny = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.InputBrightness)
        if let Bri = BriAsAny as? Double
        {
            PrimaryFilter?.setValue(Float(Bri), forKey: kCIInputBrightnessKey)
        }
        let ConAsAny = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.InputCContrast)
        if let Con = ConAsAny as? Double
        {
            PrimaryFilter?.setValue(Float(Con), forKey: kCIInputContrastKey)
        }
        
        if let Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            return Result
        }
        return nil
    }
    
    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    {
        switch Field
        {
        case .InputCContrast:
            return (FilterManager.InputTypes.DoubleType, 0.7 as Any?)
            
        case .InputBrightness:
            return (FilterManager.InputTypes.DoubleType, 0.2 as Any?)
            
        case .InputSaturation:
            return (FilterManager.InputTypes.DoubleType, 1.0 as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return HSBAdjust.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.InputCContrast)
        Fields.append(.InputBrightness)
        Fields.append(.InputSaturation)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return HSBAdjust.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "HSBFilterSettingsUI"
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
