//
//  UIColorExtensions.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import simd

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
    
    /// Return the RGBA channels of the color.
    ///
    /// - Returns: Tuple of channel values in R, G, B, and A order.
    func AsRGBA() -> (CGFloat, CGFloat, CGFloat, CGFloat)
    {
        var Red: CGFloat = 0.0
        var Green: CGFloat = 0.0
        var Blue: CGFloat = 0.0
        var Alpha: CGFloat = 1.0
        self.getRed(&Red, green: &Green, blue: &Blue, alpha: &Alpha)
        return (Red, Green, Blue, Alpha)
    }
    
    func AsRGB() -> (CGFloat, CGFloat, CGFloat)
    {
        let (R, G, B, _) = AsRGBA()
        return (R, G, B)
    }
    
    /// Return the HSBA channels of the color.
    ///
    /// - Returns: Tuple of channel values in H, S, B, and A order.
    func AsHSBA() -> (CGFloat, CGFloat, CGFloat, CGFloat)
    {
        var Hue: CGFloat = 0.0
        var Saturation: CGFloat = 0.0
        var Brightness: CGFloat = 0.0
        var Alpha: CGFloat = 1.0
        self.getHue(&Hue, saturation: &Saturation, brightness: &Brightness, alpha: &Alpha)
        return (Hue, Saturation, Brightness, Alpha)
    }
    
    /// Change the alpha component of the color to the passed value.
    ///
    /// - Parameter To: The new alpha value. Internally clamped to 0.0 to 1.0
    /// - Returns: New color with the changed alpha.
    func ChangeAlpha(To: CGFloat) -> UIColor
    {
        let (Red, Green, Blue, _) = self.AsRGBA()
        var Final = To
        if Final < 0.0
        {
            Final = 0.0
        }
        if Final > 1.0
        {
            Final = 1.0
        }
        return UIColor(red: Red, green: Green, blue: Blue, alpha: Final)
    }
    
    func Alpha() -> CGFloat
    {
        let (_, _, _, A) = AsRGBA()
        return A
    }
    
    /// Determines whether the passed color is equal to the instance color. Alpha is not used for comparison. Channels
    /// are compared individually.
    ///
    /// - Parameter Other: The other color to compare to this one.
    /// - Returns: True if the colors are equal (not counting the alpha channel), false if not.
    func Equals(_ Other: UIColor) -> Bool
    {
        let (sR, sG, sB, _) = self.AsRGBA()
        let (oR, oG, oB, _) = Other.AsRGBA()
        return sR == oR && sG == oG && sB == oB
    }
    
    /// Determiens if the instance color is equal to the passed color.
    ///
    /// - Parameters:
    ///   - R: Other color red value.
    ///   - G: Other color green value.
    ///   - B: Other color blue value.
    /// - Returns: True if this color is the same as the passed color, false otherwise.
    func Equals(_ R: CGFloat, _ G: CGFloat, _ B: CGFloat) -> Bool
    {
        let (sR, sG, sB, _) = self.AsRGBA()
        return sR == R && sG == G && sB == B
    }
    
    /// Determines if the instance color is equal to the passed color.
    ///
    /// - Parameter Other: Tuple of (red, green, blue) values to compare against this color.
    /// - Returns: True if this color is the same as the passed color, false otherwise.
    func Equals(_ Other: (CGFloat, CGFloat, CGFloat)) -> Bool
    {
        return Equals(Other.0, Other.1, Other.2)
    }
    
    /// Return the color symbol for the instance color.
    func Symbol() -> Colors
    {
        if self.Alpha() == 0.0
        {
            return .Clear
        }
        for (Color, Value) in UIColor.ColorValues
        {
            if self.Equals(Value)
            {
                return Color
            }
        }
        return .Other
    }
    
    /// Table of color symbols to color values (excluding alpha).
    static let ColorValues: [Colors: (CGFloat, CGFloat, CGFloat)] =
    [
        .Orange: (1.0, 0.5, 0.0),
        .Black: (0.0, 0.0, 0.0),
        .Blue: (0.0, 0.0, 1.0),
        .Brown: (0.6, 0.4, 0.2),
        .Cyan: (0.0, 1.0, 1.0),
        .DarkGray: (0.33, 0.33, 0.33),
        .Gray: (0.5, 0.5, 0.5),
        .Green: (0.0, 1.0, 0.0),
        .LightGray: (0.66, 0.66, 0.66),
        .Magenta: (1.0, 0.0, 1.0),
        .Purple: (0.5, 0.0, 0.5),
        .Red: (1.0, 0.0, 0.0),
        .White: (1.0, 1.0, 1.0),
        .Yellow: (1.0, 1.0, 0.0)
    ]
    
    /// Color symbols.
    enum Colors: CaseIterable
    {
        case Clear
        case Brown
        case Black
        case White
        case Red
        case Green
        case Blue
        case Cyan
        case Magenta
        case Yellow
        case Gray
        case DarkGray
        case LightGray
        case Orange
        case Purple
        case Other
    }
}

