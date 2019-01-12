//
//  Pixelator.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class Pixelator
{
    /// Ways to pixelate images.
    ///
    /// - MeanColor: Use the mean color of the region.
    /// - BrightestColor: Use the brightest color of the region.
    /// - DarkestColor: use the darkest color of the region.
    /// - Darkest: Use the darkest luminance of the region.
    /// - Brightest: Use the brightest luminance of the region.
    /// - MeanGrayscale: Grayscale calculated via channel mean.
    /// - PerceptualGrayscale: Grayscale calculated with perceptual coefficients.
    enum PixelateMethods
    {
        case MeanColor
        case BrightestColor
        case DarkestColor
        case Darkest
        case Brightest
        case MeanGrayscale
        case PerceptualGrayscale
    }
    
    /// Resize the passed image to the passed size.
    ///
    /// - Notes: https://stackoverflow.com/questions/31314412/how-to-resize-image-in-swift
    ///
    /// - Parameters:
    ///   - Image: The image to resize.
    ///   - NewSize: The new image size.
    /// - Returns: New image based from the passed image with the new size.
    public static func Resize(_ Image: UIImage, NewSize: CGSize) -> UIImage
    {
        let Size = Image.size
        let WidthRatio = NewSize.width / Size.width
        let HeightRatio = NewSize.height / Size.height
        
        var ResizeSize: CGSize!
        if WidthRatio > HeightRatio
        {
            ResizeSize = CGSize(width: Size.width * HeightRatio, height: Size.height * HeightRatio)
        }
        else
        {
            ResizeSize = CGSize(width: Size.width * WidthRatio, height: Size.height * WidthRatio)
        }
        let Rect = CGRect(x: 0, y: 0, width: ResizeSize.width, height: ResizeSize.height)
        UIGraphicsBeginImageContextWithOptions(ResizeSize, false, 1.0)
        Image.draw(in: Rect)
        let Final = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Final!
    }
    
    public static func PrepareImage(_ Source: UIImage, NodeSize: Int) -> UIImage
    {
        return PrepareImage(Source, HorizontalNodeSize: NodeSize, VerticalNodeSize: NodeSize)
    }
    
    public static func PrepareImage(_ Source: UIImage, HorizontalNodeSize: Int, VerticalNodeSize: Int) -> UIImage
    {
        var WidthAdjustment: Int = 0
        let WidthDelta = Int(Source.size.width) % HorizontalNodeSize
        if WidthDelta != 0
        {
            WidthAdjustment = WidthDelta
        }
        var HeightAdjustment: Int = 0
        let HeightDelta = Int(Source.size.height) % VerticalNodeSize
        if HeightDelta != 0
        {
            HeightAdjustment = HeightDelta
        }
        if WidthAdjustment == 0 && HeightAdjustment == 0
        {
            return Source
        }
        let NewSize = CGSize(width: Source.size.width + CGFloat(WidthAdjustment),
                             height: Source.size.height + CGFloat(HeightAdjustment))
        return Resize(Source, NewSize: NewSize)
    }
    
    public static func Pixelate(_ Source: UIImage, NodeSize: Int, Method: PixelateMethods = .MeanColor) -> UIColor?
    {
        return Pixelate(Source, HorizontalNodeSize: NodeSize, VerticalNodeSize: NodeSize, Method: Method)
    }
    
    //https://sighack.com/post/averaging-rgb-colors-the-right-way
    public static func Pixelate(_ Source: UIImage, HorizontalNodeSize: Int, VerticalNodeSize: Int,
                                Method: PixelateMethods) -> UIColor?
    {
        if let Pixel = Source.Pixels()
        {
            let TotalBlocks = (Int(Source.size.width) / HorizontalNodeSize) * (Int(Source.size.height) / VerticalNodeSize)
            let BlockColors = [(Int, Int, Int, Int)](repeating: (0,0,0,0), count: TotalBlocks)
            let NewPixels = [UInt8](repeating: 0, count: Int(Pixel.count))
            
            for Row in 0 ..< Int(Source.size.height)
            {
                for Column in 0 ..< Int(Source.size.width)
                {
                    
                }
            }
        }
        return nil
    }
}
