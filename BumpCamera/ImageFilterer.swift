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

class ImageFilterer
{
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
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight
        {
            FinalAngle = FinalAngle + 90.0
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
