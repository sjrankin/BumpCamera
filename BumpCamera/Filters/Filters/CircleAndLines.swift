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

class CircleAndLines: Renderer
{
    var _ID: UUID = UUID(uuidString: "0c84fc21-e06a-4b49-ae0e-90594abeeb4a")!
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
    
    var Description: String = "Circular and Linear Screen"
    
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
        SecondaryFilter = CIFilter(name: "CICircularScreen")
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
        if let Parameters = Parameters
        {
            if let Angle = Parameters.Angle
            {
                PrimaryFilter.setValue(Angle, forKey: kCIInputAngleKey)
                SecondaryFilter.setValue(Angle, forKey: kCIInputAngleKey)
            }
            if let Width = Parameters.Width
            {
                PrimaryFilter.setValue(Width, forKey: kCIInputWidthKey)
                SecondaryFilter.setValue(Width, forKey: kCIInputWidthKey)
            }
            if let Center = Parameters.Center
            {
                let CVCenter = CIVector(x: Center.y, y: Center.x)
                SecondaryFilter.setValue(CVCenter, forKey: kCIInputCenterKey)
            }
            if let MergeImages = Parameters.MergeWithBackground
            {
                DoMerge = MergeImages
            }
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
            let SecondaryFilter = SecondaryFilter,
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
                let CVCenter = CIVector(x: Center.y, y: Center.x)
                SecondaryFilter.setValue(CVCenter, forKey: kCIInputCenterKey)
            }
        }
        
        if var Result = PrimaryFilter.value(forKey: kCIOutputImageKey) as? CIImage
        {
            SecondaryFilter.setValue(Result, forKey: kCIInputImageKey)
            Result = (SecondaryFilter.value(forKey: kCIOutputImageKey) as? CIImage)!
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
