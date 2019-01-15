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

class LineScreen: Renderer
{
    var _ID: UUID = UUID(uuidString: "03d25ebe-1536-4088-9af6-150490262467")!
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
    
    var Description: String = "Line Screen"
    
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
        Reset()
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
    
    func Reset()
    {
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
        if let Parameters = Parameters
        {
            if let Angle = Parameters.Angle
            {
                PrimaryFilter.setValue(Angle, forKey: kCIInputAngleKey)
            }
            if let Width = Parameters.Width
            {
                PrimaryFilter.setValue(Width, forKey: kCIInputWidthKey)
            }
            if let Center = Parameters.Center
            {
                let CVCenter = CIVector(x: Center.x, y: Center.y)
                PrimaryFilter.setValue(CVCenter, forKey: kCIInputCenterKey)
            }
        }
        
        guard var FilteredImage = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage else
        {
            print("CIFilter failed to render image.")
            return nil
        }
        
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
        if let Parameters = Parameters
        {
            if let Angle = Parameters.Angle
            {
                PrimaryFilter.setValue(Angle, forKey: kCIInputAngleKey)
            }
            if let Width = Parameters.Width
            {
                PrimaryFilter.setValue(Width, forKey: kCIInputWidthKey)
            }
            if let Center = Parameters.Center
            {
                let CVCenter = CIVector(x: Center.x, y: Center.y)
                PrimaryFilter.setValue(CVCenter, forKey: kCIInputCenterKey)
            }
        }
        
        if let Result = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage
        {
            var DoMerge = false
            if let MergeImages = Parameters?.MergeWithBackground
            {
                DoMerge = MergeImages
            }
            var Rotated = RotateImage(Result)
            if DoMerge
            {
                Rotated = Merge(Rotated, Image)!
            }
            return Rotated
        }
        return nil
    }
    
    func Merge(_ Top: CIImage, _ Bottom: CIImage) -> CIImage?
    {
        var FinalTop: CIImage? = nil
        InvertFilter?.setDefaults()
        AlphaMaskFilter?.setDefaults()
        
        InvertFilter?.setValue(Top, forKey: kCIInputImageKey)
        if let TopResult = InvertFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            AlphaMaskFilter?.setValue(TopResult, forKey: kCIInputImageKey)
            if let MaskResult = AlphaMaskFilter?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                InvertFilter?.setValue(MaskResult, forKey: kCIInputImageKey)
                if let InvertedAgain = InvertFilter?.value(forKey: kCIOutputImageKey) as? CIImage
                {
                    FinalTop = InvertedAgain
                }
                else
                {
                    print("Error returned by second call to inversion filter.")
                    return nil
                }
            }
            else
            {
                print("Error returned by alpha mask filter.")
                return nil
            }
        }
        else
        {
            print("Error return by call to inversion filter.")
            return nil
        }
        
        MergeSourceAtop?.setDefaults()
        MergeSourceAtop?.setValue(FinalTop, forKey: kCIInputImageKey)
        MergeSourceAtop?.setValue(Bottom, forKey: kCIInputBackgroundImageKey)
        if let Merged = MergeSourceAtop?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            return Merged
        }
        else
        {
            print("Error returned by call to image merge filter.")
            return nil
        }
    }
}
