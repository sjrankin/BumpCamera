//
//  HueAdjust.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage

class HueAdjust: FilterParent, Renderer
{
    var _ID: UUID = UUID(uuidString: "dd8f30bf-e22b-4d8c-afa3-303c15eb1928")!
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
    
    var Description: String = "Hue Adjust"
    
    var IconName: String = "Hue Adjust"
    
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
            print("BufferPool nil in HueAdjust.")
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CIHueAdjust")
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
            print("BufferPool nil in HueAdjust.Render.")
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
        
        let AngleAsAny = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.Angle)
        if let Angle = AngleAsAny as? Double
        {
            PrimaryFilter.setValue(Float(Angle), forKey: kCIInputAngleKey)
        }
        
        guard let FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
        if BufferPool == nil
        {
            print("BufferPool nil in HueAdjust after initial OK check.")
            return nil
        }
        var PixBuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &PixBuf)
        guard let OutPixBuf = PixBuf else
        {
            print("Allocation failure in Hue Adjust.")
            return nil
        }
        
        Context.render(FilteredImage, to: OutPixBuf, bounds: FilteredImage.extent, colorSpace: ColorSpace)
        return OutPixBuf
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
        PrimaryFilter = CIFilter(name: "CIHueAdjust")
        PrimaryFilter?.setDefaults()
        PrimaryFilter?.setValue(Image, forKey: kCIInputImageKey)
        let AngleAsAny = ParameterManager.GetField(From: ID, Field: FilterManager.InputFields.Angle)
        if let Angle = AngleAsAny as? Double
        {
            PrimaryFilter?.setValue(Float(Angle), forKey: kCIInputAngleKey)
        }
        if let Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            #if true
            return Result
            #else
            let Rotated = RotateImage(Result)
            return Rotated
            #endif
        }
        return nil
    }
    
    #if false
    func Merge(_ Top: CIImage, _ Bottom: CIImage) -> CIImage?
    {
        return nil
    }
    #endif
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.Angle)
        return Fields
    }
    
    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    {
        switch Field
        {
        case .Angle:
            return (FilterManager.InputTypes.DoubleType, 0.5 as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func GetFieldLabel(ForField: FilterManager.InputFields) -> String?
    {
        return nil
    }
    
    func GetFieldDetails(ForField: FilterManager.InputFields) -> String?
    {
        return nil
    }
}
