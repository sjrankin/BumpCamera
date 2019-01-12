//
//  ExtensionMethods.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

extension UIImage
{
    public static func ConvertFrom(Raw: [UInt8]?, Width: Int, Height: Int) -> UIImage?
    {
        let IData = Data(bytes: Raw!, count: (Raw?.count)!)
        let Result = UIImage(data: IData)
        return Result
    }
    
    //https://stackoverflow.com/questions/33768066/get-pixel-data-as-array-from-uiimage-cgimage-in-swift
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
