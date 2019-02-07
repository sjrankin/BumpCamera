//
//  CMYKHalftone.swift
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

class CMYKHalftone: FilterParent, Renderer
{
    static let _ID: UUID = UUID(uuidString: "13c40f19-3d54-492c-92bc-2680f4cf2a2f")!
    
    func ID() -> UUID
    {
        return CMYKHalftone._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "CMYK Halftone"
    
    var IconName: String = "CMYKHalftone"
    
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
        Reset("CMYKHalftone.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CICMYKHalftone")
        Initialized = true
    }
    
    func Reset(_ CalledBy: String = "")
    {
        objc_sync_enter(AccessLock)
        defer{objc_sync_exit(AccessLock)}
        Context = nil
        PrimaryFilter = nil
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
        
        guard let FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
        var PixBuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &PixBuf)
        guard let OutPixBuf = PixBuf else
        {
            print("Allocation failure in CircularScreen.")
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

        PrimaryFilter = CIFilter(name: "CICMYKHalftone")
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
        case .Width:
            return (.DoubleType, 5.0 as Any?)
            
        case .Angle:
            return (.DoubleType, 0.0 as Any?)
            
        case .Center:
            return (.PointType, CGPoint(x: 0.0, y: 0.0) as Any?)
            
        case .MergeWithBackground:
            return (.BoolType, true as Any?)
            
        case .CenterInImage:
            return (.BoolType, true as Any?)
            
        case .AdjustInLandscape:
            return (.BoolType, true as Any?)
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return CMYKHalftone.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.Width)
        Fields.append(.Angle)
        Fields.append(.Center)
        Fields.append(.MergeWithBackground)
        Fields.append(.AdjustInLandscape)
        Fields.append(.CenterInImage)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return CMYKHalftone.SettingsStoryboard()
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
