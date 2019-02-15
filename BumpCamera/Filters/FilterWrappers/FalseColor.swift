//
//  FalseColor.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/12/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage

class FalseColor: FilterParent, Renderer
{
    static let _ID: UUID = UUID(uuidString: "d8ae3fb2-e3a1-46a3-87e0-9215437b16a7")!
    
    func ID() -> UUID
    {
        return FalseColor._ID
    }
    
    static func ID() -> UUID
    {
        return _ID
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "False Color"
    
    var IconName: String = "False color"
    
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
        Reset("DotScreen.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CIFalseColor")
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
        
        let Color0 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.darkGray)
        let Color1 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.yellow)
        
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
            print("Allocation failure in DotScreen.")
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
        
        PrimaryFilter = CIFilter(name: "CIFalseColor")
        PrimaryFilter?.setDefaults()
        PrimaryFilter?.setValue(Image, forKey: kCIInputImageKey)
        
        let Color0 = ParameterManager.GetColor(From: ID(), Field: .Color0, Default: UIColor.darkGray)
        let Color1 = ParameterManager.GetColor(From: ID(), Field: .Color1, Default: UIColor.yellow)
        
        PrimaryFilter?.setValue(CIColor(cgColor: Color0.cgColor), forKey: "inputColor0")
        PrimaryFilter?.setValue(CIColor(cgColor: Color1.cgColor), forKey: "inputColor1")
        
        if let Result = PrimaryFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            LastCIImage = Result
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
            
        default:
            fatalError("Unexpected field \(Field) encountered in DefaultFieldValue.")
        }
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return FalseColor.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        var Fields = [FilterManager.InputFields]()
        Fields.append(.Color0)
        Fields.append(.Color1)
        return Fields
    }
    
    func SettingsStoryboard() -> String?
    {
        return FalseColor.SettingsStoryboard()
    }
    
    public static func SettingsStoryboard() -> String?
    {
        return "FalseColorSettingsUI"
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
