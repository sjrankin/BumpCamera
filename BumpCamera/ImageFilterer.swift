//
//  ImageFilterer.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import AVFoundation

class ImageFilterer
{
    #if false
    public static func Initialize(WithDescription: CMFormatDescription, HintSize: Int)
    {
        CiContext = CIContext()
        CreateBufferPool(From: WithDescription, BufferCountHint: HintSize)
    }
    
    private static func CreateBufferPool(From: CMFormatDescription, BufferCountHint: Int) ->
        (BufferPool: CVPixelBufferPool?, ColorSpace: CGColorSpace?, FormatDescription: CMFormatDescription?)
    {
        let InputSubType = CMFormatDescriptionGetMediaSubType(From)
        if InputSubType != kCVPixelFormatType_32BGRA
        {
            print("Invalid pixel buffer type \(InputSubType)")
            return (nil, nil, nil)
        }
        
        let InputSize = CMVideoFormatDescriptionGetDimensions(From)
        var PixelBufferAttrs: [String: Any] =
        [
            kCVPixelBufferPixelFormatTypeKey as String: UInt(InputSubType),
            kCVPixelBufferWidthKey as String: Int(InputSize.width),
            kCVPixelBufferHeightKey as String: Int(InputSize.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        var GColorSpace = CGColorSpaceCreateDeviceRGB()
        if let FromEx = CMFormatDescriptionGetExtensions(From) as Dictionary?
        {
            let ColorPrimaries = FromEx[kCVImageBufferColorPrimariesKey]
            if let ColorPrimaries = ColorPrimaries
            {
                var ColorSpaceProps: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: ColorPrimaries]
                if let YCbCrMatrix = FromEx[kCVImageBufferYCbCrMatrixKey]
                {
                    ColorSpaceProps[kCVImageBufferYCbCrMatrixKey as String] = YCbCrMatrix
                }
                if let XferFunc = FromEx[kCVImageBufferTransferFunctionKey]
                {
                    ColorSpaceProps[kCVImageBufferTransferFunctionKey as String] = XferFunc
                }
                PixelBufferAttrs[kCVBufferPropagatedAttachmentsKey as String] = ColorSpaceProps
            }
            if let CVColorSpace = FromEx[kCVImageBufferCGColorSpaceKey]
            {
                GColorSpace = CVColorSpace as! CGColorSpace
            }
            else
            {
                if (ColorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String)
                {
                    GColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
                }
            }
        }
        
        let PoolAttrs = [kCVPixelBufferPoolMinimumBufferCountKey as String: BufferCountHint]
        var CVPixBufPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, PoolAttrs as NSDictionary?,
                                PixelBufferAttrs as NSDictionary?,
                                &CVPixBufPool)
        guard let BufferPool = CVPixBufPool else
        {
            print("Allocation failure - could not allocate pixel buffer pool.")
            return (nil, nil, nil)
        }
        
        PreAllocateBuffers(Pool: BufferPool, AllocationThreshold: BufferCountHint)
        
        var PixelBuffer: CVPixelBuffer?
        var OutFormatDesc: CMFormatDescription?
        let AuxAttrs = [kCVPixelBufferPoolAllocationThresholdKey as String: BufferCountHint] as NSDictionary
        CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, BufferPool, AuxAttrs, &PixelBuffer)
        if let PixelBuffer = PixelBuffer
        {
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: PixelBuffer, formatDescriptionOut: &OutFormatDesc)
        }
        PixelBuffer = nil
        
        return(BufferPool, GColorSpace, OutFormatDesc)
    }
    
    private static func PreAllocateBuffers(Pool: CVPixelBufferPool, AllocationThreshold: Int)
    {
        var PixelBuffers = [CVPixelBuffer]()
        var Error: CVReturn = kCVReturnSuccess
        let AuxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: AllocationThreshold] as NSDictionary
        var PixelBuffer: CVPixelBuffer?
        while Error == kCVReturnSuccess
        {
            Error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, Pool, AuxAttributes, &PixelBuffer)
            if let PixelBuffer = PixelBuffer
            {
                PixelBuffers.append(PixelBuffer)
            }
            PixelBuffer = nil
        }
        PixelBuffers.removeAll()
    }
    
    private static var CiContext: CIContext? = nil
    
    private static var OutputColorSpace: CGColorSpace? = nil
    
    private static var OutputPixelBufferPool: CVPixelBufferPool?
    
    public static func Noir(_ Source: CVPixelBuffer) -> CVPixelBuffer?
    {
        let SourceImage = CIImage(cvImageBuffer: Source)
        let FilteredImage = Noir(SourceImage)
        var PixBuf: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, OutputPixelBufferPool!, &PixBuf)
        guard let OutputPixelBuffer = PixBuf else
        {
            print("Allocation failure")
            return nil
        }

        CiContext!.render(FilteredImage!, to: OutputPixelBuffer, bounds: FilteredImage!.extent, colorSpace: OutputColorSpace!)
        return OutputPixelBuffer
    }
    
    public static func Noir(_ Source: CIImage) -> CIImage?
    {
        return nil
    }
    #endif
    
    /// Run the Noir filter (stylized grayscale) on the passed image.
    ///
    /// - Parameter Source: The image to process.
    /// - Returns: Image run with the noir filter. Rotated appropriately.
    public static func Noir(_ Source: UIImage) -> UIImage?
    {
        let NoirFilter = CIFilter(name: "CIPhotoEffectNoir")
        NoirFilter?.setDefaults()
        if let CImage = CIImage(image: Source)
        {
            NoirFilter?.setValue(CImage, forKey: kCIInputImageKey)
            if let Result = NoirFilter?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                let Rotated = RotateImage(Result)
                let Final = UIImage(ciImage: Rotated)
                return Final
            }
        }
        return nil
    }
    
    public static func DotScreen(_ Source: UIImage, Center: CGPoint? = nil, Angle: Double? = nil, Width: Double? = nil, Merged: Bool = false) -> UIImage?
    {
        let Dots = CIFilter(name: "CIDotScreen")
        Dots?.setDefaults()
        if let Center = Center
        {
            //Reverse x and y because for some reason, iOS rotates images, making a real mess of things.
            let CV = CIVector(x: Center.y, y: Center.x)
            Dots?.setValue(CV, forKey: kCIInputCenterKey)
        }
        if let Width = Width
        {
            Dots?.setValue(Width, forKey: kCIInputWidthKey)
        }
        if let Angle = Angle
        {
            Dots?.setValue(Angle, forKey: kCIInputAngleKey)
        }
        if let CImage = CIImage(image: Source)
        {
            Dots?.setValue(CImage, forKey: kCIInputImageKey)
            if let Result = Dots?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                let Rotated = RotateImage(Result)
                var Final = UIImage(ciImage: Rotated)
                if Merged
                {
                    var ISource = CIImage(image: Source)
                    ISource = RotateImage(ISource!)
                    Final = Merge(Rotated, ISource!)
                }
                return Final
            }
        }
        return nil
    }
    
    public static func HatchedScreen(_ Source: UIImage, Center: CGPoint? = nil, Angle: Double? = nil, Width: Double? = nil, Merged: Bool = false) -> UIImage?
    {
        let Hatched = CIFilter(name: "CIHatchedScreen")
        Hatched?.setDefaults()
        if let Center = Center
        {
            //Reverse x and y because for some reason, iOS rotates images, making a real mess of things.
            let CV = CIVector(x: Center.y, y: Center.x)
            Hatched?.setValue(CV, forKey: kCIInputCenterKey)
        }
        if let Width = Width
        {
            Hatched?.setValue(Width, forKey: kCIInputWidthKey)
        }
        if let Angle = Angle
        {
            Hatched?.setValue(Angle, forKey: kCIInputAngleKey)
        }
        if let CImage = CIImage(image: Source)
        {
            Hatched?.setValue(CImage, forKey: kCIInputImageKey)
            if let Result = Hatched?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                let Rotated = RotateImage(Result)
                var Final = UIImage(ciImage: Rotated)
                if Merged
                {
                    var ISource = CIImage(image: Source)
                    ISource = RotateImage(ISource!)
                    Final = Merge(Rotated, ISource!)
                }
                return Final
            }
        }
        return nil
    }
    
    /// Merge the two passed images into one image. The operation used for merging the images is SourceAtop. Working on the assumption
    /// the Top image is black and white, the colors of the Top image are inverted. Then, the Top image is run through the MaskToAlpha
    /// filter (which changes white to transparent), then re-inverted (which leaves the transparent areas alone). The result is merged
    /// with the Bottom image.
    ///
    /// - Parameters:
    ///   - Top: The image on the top. Assumed to have some transparent areas (but it's not necessary that they do).
    ///   - Bottom: The background image. Assumed to not have any transparent areas (but it may).
    /// - Returns: Image resulting from the merger of the Top and Bottom images.
    private static func Merge(_ Top: CIImage, _ Bottom: CIImage) -> UIImage
    {
        var FinalTop: CIImage? = nil
        
        let Invert = CIFilter(name: "CIColorInvert")
        Invert?.setDefaults()
        Invert?.setValue(Top, forKey: kCIInputImageKey)
        if let TopResult = Invert?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            let ToAlpha = CIFilter(name: "CIMaskToAlpha")
            ToAlpha?.setDefaults()
            ToAlpha?.setValue(TopResult, forKey: kCIInputImageKey)
            if let MaskResult = ToAlpha?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                Invert?.setValue(MaskResult, forKey: kCIInputImageKey)
                if let InvertedAgain = Invert?.value(forKey: kCIOutputImageKey) as? CIImage
                {
                    FinalTop = InvertedAgain
                }
                else
                {
                    fatalError("Error re-inverting image.")
                }
            }
            else
            {
                fatalError("Error getting result from alpha mask operation.")
            }
        }
        else
        {
            fatalError("Error getting output from inversion operation.")
        }
        
        let Compose = CIFilter(name: "CISourceAtopCompositing")
        Compose?.setDefaults()
        Compose?.setValue(FinalTop, forKey: kCIInputImageKey)
        Compose?.setValue(Bottom, forKey: kCIInputBackgroundImageKey)
        if let ComposeResult = Compose?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            let Final = UIImage(ciImage: ComposeResult)
            return Final
        }
        else
        {
            fatalError("Error getting output of composition operation.")
        }
    }
    
    public static func RoundLines(_ Source: UIImage, Center: CGPoint, Width: Double? = nil, Merged: Bool = false) -> UIImage?
    {
        let Round = CIFilter(name: "CICircularScreen")
        Round?.setDefaults()
        //Reverse x and y because for some reason, iOS rotates images, making a real mess of things.
        let CV = CIVector(x: Center.y, y: Center.x)
        if let Width = Width
        {
            Round?.setValue(Width, forKey: kCIInputWidthKey)
        }
        Round?.setValue(CV, forKey: kCIInputCenterKey)
        if let CImage = CIImage(image: Source)
        {
            Round?.setValue(CImage, forKey: kCIInputImageKey)
            if let Result = Round?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                let Rotated = RotateImage(Result)
                var Final = UIImage(ciImage: Rotated)
                if Merged
                {
                    var ISource = CIImage(image: Source)
                    ISource = RotateImage(ISource!)
                    Final = Merge(Rotated, ISource!)
                }
                return Final
            }
        }
        return nil
    }
    
    public static func PrintOrientation(_ Current: UIDeviceOrientation)
    {
        switch Current
        {
        case .faceDown:
            print("Face down")
            
        case .faceUp:
            print("Face up")
            
        case .landscapeLeft:
                print ("Landscape left")
            
        case .landscapeRight:
            print("Landscape right")
            
        case .portrait:
            print("Portrait")
            
        case .portraitUpsideDown:
            print("Portrait upside down")
            
        case .unknown:
            print("Unknown")
        }
    }
    
    public static func VPrintOrientation(_ Current: AVCaptureVideoOrientation)
    {
        switch Current
        {
        case AVCaptureVideoOrientation.landscapeRight:
            print("Landscape right")
            
        case AVCaptureVideoOrientation.landscapeLeft:
            print("Landscape left")
            
        case AVCaptureVideoOrientation.portrait:
            print("Portrait")
            
        case AVCaptureVideoOrientation.portraitUpsideDown:
            print("Portrait upside down")
            
        default:
            print("Other")
        }
    }
    
    public static func TVLines(_ Source: UIImage, Center: CGPoint? = nil, Angle: Double? = nil, Width: Double? = nil,
                               Merged: Bool = false, AdjustAngleIfInLandscape: Bool = true) -> UIImage?
    {
        let TV = CIFilter(name: "CILineScreen")
        TV?.setDefaults()
        if let Center = Center
        {
            //Reverse x and y because for some reason, iOS rotates images, making a real mess of things.
            let CV = CIVector(x: Center.y, y: Center.x)
            TV?.setValue(CV, forKey: kCIInputCenterKey)
        }
        var FinalAngle = 0.0
        if let Angle = Angle
        {
            FinalAngle = Angle
        }
        if AdjustAngleIfInLandscape
        {
            let Rad90: Double = 90.0 * Double.pi / 180.0
            //PrintOrientation(UIDevice.current.orientation)
            if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight
            {
                print("Adjusting angle from \(FinalAngle) to \(FinalAngle + Rad90)")
                FinalAngle = FinalAngle + Rad90
            }
        }
        TV?.setValue(FinalAngle, forKey: kCIInputAngleKey)
        if let Width = Width
        {
            TV?.setValue(Width, forKey: kCIInputWidthKey)
        }
        if let CImage = CIImage(image: Source)
        {
            TV?.setValue(CImage, forKey: kCIInputImageKey)
            if let Result = TV?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                let Rotated = RotateImage(Result)
                var Final = UIImage(ciImage: Rotated)
                if Merged
                {
                    var ISource = CIImage(image: Source)
                    ISource = RotateImage(ISource!)
                    Final = Merge(Rotated, ISource!)
                }
                return Final
            }
        }
        return nil
    }
    
    public static func TVRound(_ Source: UIImage, Center: CGPoint, Angle: Double? = nil, Width: Double? = nil) -> UIImage?
    {
        let TV = CIFilter(name: "CILineScreen")
        TV?.setDefaults()
        
        if let Angle = Angle
        {
            TV?.setValue(Angle, forKey: kCIInputAngleKey)
        }
        if let Width = Width
        {
            TV?.setValue(Width, forKey: kCIInputWidthKey)
        }
        if let CImage = CIImage(image: Source)
        {
            TV?.setValue(CImage, forKey: kCIInputImageKey)
            if let Result = TV?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                let Round = CIFilter(name: "CICircularScreen")
                Round?.setDefaults()
                //Reverse x and y because for some reason, iOS rotates images, making a real mess of things.
                let CV = CIVector(x: Center.y, y: Center.x)
                Round?.setValue(CV, forKey: kCIInputCenterKey)
                if let Width = Width
                {
                    Round?.setValue(Width, forKey: kCIInputWidthKey)
                }
                if let Angle = Angle
                {
                    Round?.setValue(Angle, forKey: kCIInputAngleKey)
                }
                Round?.setValue(Result, forKey: kCIInputImageKey)
                if let RResult = Round?.value(forKey: kCIOutputImageKey) as? CIImage
                {
                    let Rotated = RotateImage(RResult)
                    let Final = UIImage(ciImage: Rotated)
                    return Final
                }
            }
        }
        return nil
    }
    
    public static func CMYKMask(_ Source: UIImage, Center: CGPoint? = nil, Angle: Double? = nil, Width: Double? = nil) -> UIImage?
    {
        let CMYK = CIFilter(name: "CICMYKHalftone")
        CMYK?.setDefaults()
        if let Center = Center
        {
            //Reverse x and y because for some reason, iOS rotates images, making a real mess of things.
            let CV = CIVector(x: Center.y, y: Center.x)
            CMYK?.setValue(CV, forKey: kCIInputCenterKey)
        }
        if let Angle = Angle
        {
            CMYK?.setValue(Angle, forKey: kCIInputAngleKey)
        }
        if let Width = Width
        {
            CMYK?.setValue(Width, forKey: kCIInputWidthKey)
        }
        if let CImage = CIImage(image: Source)
        {
            CMYK?.setValue(CImage, forKey: kCIInputImageKey)
            if let Result = CMYK?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                let Rotated = RotateImage(Result)
                let Final = UIImage(ciImage: Rotated)
                return Final
            }
        }
        return nil
    }
    
    public static func ColorBlocks(_ Source: UIImage, NodeWidth: Double) -> UIImage?
    {
        let Pixel = CIFilter(name: "CIPixellate")
        Pixel?.setDefaults()
        Pixel?.setValue(NodeWidth, forKey: kCIInputScaleKey)
        if let CImage = CIImage(image: Source)
        {
            Pixel?.setValue(CImage, forKey: kCIInputImageKey)
            if let Result = Pixel?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                let Rotated = RotateImage(Result)
                let Final = UIImage(ciImage: Rotated)
                return Final
            }
        }
        return nil
    }
    
    /// Images are rotated when they shouldn't be so we have to rotate them back.
    ///
    /// - Parameter Image: The image to rotate.
    /// - Returns: Properly oriented image.
    private static func RotateImage(_ Image: CIImage) -> CIImage
    {
        return Image.oriented(CGImagePropertyOrientation.right)
    }
}
