//
//  UIImageExtensions.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import VideoToolbox
import simd

extension UIImage
{
    /// Create a UIImage from a pixel buffer.
    ///
    /// -SeeAlso:
    /// [How to turn a CVPixelBuffer into a UIImage](https://stackoverflow.com/questions/8072208/how-to-turn-a-cvpixelbuffer-into-a-uiimage)
    ///
    /// - Parameter PixelBuffer: The pixel buffer with the data to create an image.
    public convenience init?(PixelBuffer: CVPixelBuffer)
    {
        var CgImage: CGImage? = nil
        VTCreateCGImageFromCVPixelBuffer(PixelBuffer, options: nil, imageOut: &CgImage)
        if let Final = CgImage
        {
            self.init(cgImage: Final)
        }
        else
        {
            return nil
        }
    }
    
    /// Convert an array of UInt8 values into a UIImage.
    ///
    /// - Parameters:
    ///   - Raw: Array of UInt8 values that will make up the returned image.
    ///   - Width: Width of the image.
    ///   - Height: Height of the image.
    /// - Returns: UIImage created from the passed array on success, nil on error.
    public static func ConvertFrom(Raw: [UInt8]?, Width: Int, Height: Int) -> UIImage?
    {
        let IData = Data(bytes: Raw!, count: (Raw?.count)!)
        let Result = UIImage(data: IData)
        return Result
    }
    
    //https://stackoverflow.com/questions/33768066/get-pixel-data-as-array-from-uiimage-cgimage-in-swift
    /// Converts the pixels in the instance UIImage to an array of UInt8 values.
    ///
    /// - Returns: Array of UInt8 values created from the pixels of the instance. Nil on error.
    func Pixels() -> [UInt8]?
    {
        let Size = self.size
        let DataSize = size.width * size.height * 4
        var PixelData = [UInt8](repeating: 0, count: Int(DataSize))
        let ColorSpace = CGColorSpaceCreateDeviceRGB()
        let Context = CGContext(data: &PixelData, width: Int(Size.width), height: Int(Size.height),
                                bitsPerComponent: 8, bytesPerRow: 4 * Int(Size.width),
                                space: ColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let CGImage = self.cgImage else { return nil }
        Context?.draw(CGImage, in: CGRect(x: 0, y: 0, width: Size.width, height: Size.height))
        return PixelData
    }
}

