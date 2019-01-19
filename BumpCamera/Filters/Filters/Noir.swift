//
//  Noir.swift
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

class Noir: Renderer
{
    var _ID: UUID = UUID(uuidString: "7215048f-15ea-46a1-8b11-a03e104a568d")!
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
    
    var IconName: String = "Noir"
    
    var Description: String = "Noir"
    
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
        Reset()
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = CIFilter(name: "CIPhotoEffectNoir")
        Initialized = true
    }
    
    func Reset()
    {
        Context = nil
        PrimaryFilter = nil
        ColorSpace = nil
        BufferPool = nil
        OutputFormatDescription = nil
        InputFormatDescription = nil
        Initialized = false
    }
    
    func Render(PixelBuffer: CVPixelBuffer, Parameters: RenderPacket? = nil) -> CVPixelBuffer?
    {
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
        
        var PixBuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, BufferPool!, &PixBuf)
        guard let OutPixBuf = PixBuf else
        {
            print("Allocation failure in.")
            return nil
        }
        
        Context.render(FilteredImage, to: OutPixBuf, bounds: FilteredImage.extent, colorSpace: ColorSpace)
        return OutPixBuf
    }
    
    func Render(Image: UIImage, Parameters: RenderPacket? = nil) -> UIImage?
    {
        if let CImage = CIImage(image: Image)
        {
            if let Result = Render(Image: CImage, Parameters: Parameters)
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
    
    func Render(Image: CIImage, Parameters: RenderPacket? = nil) -> CIImage?
    {
        guard let PrimaryFilter = PrimaryFilter,
            Initialized else
        {
            print("Filter not initialized.")
            return nil
        }
        PrimaryFilter.setDefaults()
        PrimaryFilter.setValue(Image, forKey: kCIInputImageKey)
        
        if let Result = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage
        {
            let Rotated = RotateImage(Result)
            return Rotated
        }
        return nil
    }
    
    func Merge(_ Top: CIImage, _ Bottom: CIImage) -> CIImage?
    {
        return nil
    }
    
    func GetDefaultPacket() -> RenderPacket
    {
        return RenderPacket(ID: _ID)
    }
}
