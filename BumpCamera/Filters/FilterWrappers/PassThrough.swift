//
//  PassThrough.swift
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

class PassThrough: FilterParent, Renderer
{
    static let _ID: UUID = UUID(uuidString: "e18b32bf-e965-41c6-a1f5-4bb4ed6ba472")!
    
    public static func ID() -> UUID
    {
        return _ID
    }
    
    func ID() -> UUID
    {
        return PassThrough._ID
    }
    
    var InstanceID: UUID
    {
        return UUID()
    }
    
    var Description: String = "No Filter"
    
    var IconName: String = "PassThrough"
    
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
        Reset("PassThrough.Initialize")
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = nil
        Initialized = true
    }
    
    func Reset(_ CalledBy: String = "")
    { 
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
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
    {
        return PixelBuffer
    }
    
    func InitializeForImage()
    {
    }
    
    func Render(Image: UIImage) -> UIImage?
    {
        LastUIImage = Image
        return Image
    }
    
    func Render(Image: CIImage) -> CIImage?
    {
        LastCIImage = Image
        return Image
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
        return (FilterManager.InputTypes.NoType, nil)
    }
    
    func SupportedFields() -> [FilterManager.InputFields]
    {
        return PassThrough.SupportedFields()
    }
    
    public static func SupportedFields() -> [FilterManager.InputFields]
    {
        return [FilterManager.InputFields]()
    }
    
    func SettingsStoryboard() -> String?
    {
        return PassThrough.SettingsStoryboard()
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
}
