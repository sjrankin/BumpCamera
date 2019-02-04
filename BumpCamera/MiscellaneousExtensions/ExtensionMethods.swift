//
//  ExtensionMethods.swift
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
    //https://stackoverflow.com/questions/8072208/how-to-turn-a-cvpixelbuffer-into-a-uiimage
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

extension UIColor
{
    /// Convert an instance of a UIColor to a SIMD float4 structure.
    ///
    /// - Returns: SIMD float4 equivalent of the instance color.
    func ToFloat4() -> simd_float4
    {
        var FVals = [Float]()
        var Red: CGFloat = 0.0
        var Green: CGFloat = 0.0
        var Blue: CGFloat = 0.0
        var Alpha: CGFloat = 1.0
        self.getRed(&Red, green: &Green, blue: &Blue, alpha: &Alpha)
        FVals.append(Float(Red))
        FVals.append(Float(Green))
        FVals.append(Float(Blue))
        FVals.append(Float(Alpha))
        let Result = simd_float4(FVals)
        return Result
    }
    
    /// Convert a SIMD float4 structure into a UIColor.
    ///
    /// - Parameter Float4: The SIMD float4 structure whose values will be converted into a UIColor.
    /// - Returns: UIColor equivalent of the passed SIMD float4 set of values.
    static func From(Float4: simd_float4) -> UIColor
    {
        let NewColor = UIColor(red: CGFloat(Float4.w), green: CGFloat(Float4.x),
                               blue: CGFloat(Float4.y), alpha: CGFloat(Float4.z))
        return NewColor
    }
}
