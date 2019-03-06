//
//  GradientParser.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GradientParser
{
    private static let KnownColors: [String: UIColor] =
        [
            "white": UIColor.white,
            "black": UIColor.black,
            "red": UIColor.red,
            "green": UIColor.green,
            "blue": UIColor.blue,
            "cyan": UIColor.cyan,
            "magenta": UIColor.magenta,
            "yellow": UIColor.yellow,
            "orange": UIColor.orange,
            "brown": UIColor.brown,
            "gray": UIColor.gray,
            "lightgray": UIColor.lightGray,
            "darkgray": UIColor.darkGray,
            "indigo": UIColor(red: 63.0 / 255.0, green: 0.0, blue: 255.0, alpha: 1.0), //#3f00ff
            "violet": UIColor(red: 127 / 255.0, green: 0.0, blue: 255.0, alpha: 1.0), //#7f00ff
            "coral": UIColor(red: 1.0, green: 0.494, blue: 0.314, alpha: 1.0), //#ff7e50
            "gold": UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0), //#ffd700
            "mauve": UIColor(red: 0.718, green: 0.518, blue: 0.655, alpha: 1.0), //#b784a7
            "pastelbrown": UIColor(red: 0.514, green: 0.412, blue: 0.325, alpha: 1.0), //#836953
            "pistachio": UIColor(red: 0.576, green: 0.773, blue: 0.447, alpha: 1.0), //#93c572
            "tomato": UIColor(red: 1.0, green: 0.388, blue: 0.278, alpha: 1.0), //#ff6347
    ]
    
    /// Given a color value, return the color's name if known, hex value if not known.
    ///
    /// - Parameter Color: Color whose name is desired.
    /// - Returns: Name of the color or #-leading hex value.
    public static func NameFor(Color: UIColor) -> String
    {
        for (ColorName, ColorValue) in KnownColors
        {
            if ColorValue == Color
            {
                return ColorName
            }
        }
        let Red = Int(Color.r * 255.0)
        let Green = Int(Color.g * 255.0)
        let Blue = Int(Color.b * 255.0)
        let HexValue = "#" + String(format: "%02x", Red) + String(format: "%02x", Green) + String(format: "%02x", Blue)
        return HexValue
    }
    
    private static func ParseColor(_ Raw: String) -> UIColor
    {
        var Working = Raw.replacingOccurrences(of: "(", with: "")
        Working = Working.replacingOccurrences(of: ")", with: "")
        Working = Working.trimmingCharacters(in: CharacterSet.whitespaces).lowercased()
        if let KnownColor = KnownColors[Working]
        {
            return KnownColor
        }
        Working = Working.replacingOccurrences(of: "#", with: "")
        //What's left should be a six-digit hex number.
        if Working.count != 6
        {
            return UIColor.white
        }
        let rx = String(Working.prefix(2))
        Working.removeFirst(2)
        let gx = String(Working.prefix(2))
        Working.removeFirst(2)
        let bx = String(Working.prefix(2))
        let ri = Int(rx, radix: 16)!
        let gi = Int(gx, radix: 16)!
        let bi = Int(bx, radix: 16)!
        return UIColor(red: CGFloat(ri) / 255.0, green: CGFloat(gi) / 255.0, blue: CGFloat(bi) / 255.0, alpha: 1.0)
    }
    
    private static func ParseLocation(_ Raw: String) -> CGFloat
    {
        var Working = Raw.replacingOccurrences(of: "(", with: "")
        Working = Working.replacingOccurrences(of: ")", with: "")
        Working = Working.trimmingCharacters(in: CharacterSet.whitespaces)
        let Result = Double(Working)!
        return CGFloat(Result)
    }
    
    private static func ParseGradientStop(_ Stop: String) -> (UIColor, CGFloat)?
    {
        let Raw = Stop.trimmingCharacters(in: CharacterSet.whitespaces)
        let Parts = Raw.split(separator: "@")
        if Parts.count != 2
        {
            return nil
        }
        let ColorValue = String(Parts[0])
        let ColorLocation = String(Parts[1])
        return (ParseColor(ColorValue), ParseLocation(ColorLocation))
    }
    
    public static func ParseGradient(_ Raw: String) -> [(UIColor, CGFloat)]
    {
        var Results = [(UIColor, CGFloat)]()
        let Parts = Raw.split(separator: ",")
        for Part in Parts
        {
            if let (StopColor, StopLocation) = ParseGradientStop(String(Part))
            {
                Results.append((StopColor, StopLocation))
            }
        }
        return Results
    }
    
    public static func AssembleGradient(_ GradientData: [(UIColor, CGFloat)]) -> String
    {
        if GradientData.count < 1
        {
            return ""
        }
        var Result = ""
        for (ColorValue, ColorLocation) in GradientData
        {
            let FinalValue = NameFor(Color: ColorValue)
            let ColorStop = "(\(FinalValue))@(\(ColorLocation)),"
            Result = Result + ColorStop
        }
        Result.removeLast()
        return Result
    }
}
