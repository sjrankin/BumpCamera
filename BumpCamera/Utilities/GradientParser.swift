//
//  GradientParser.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Provides functions to parse gradient descriptions as well as to create gradient descriptions, as well as
/// other functions to help with gradients in general.
///
/// - Note:
///     Gradient descriptions are a series of comma-delimited color stops. Each color stop is in the format
///     `(color value)@(point)` where `color value` is either a hex value that describes a color, or a color
///     name in the KnownColors list. `point` is the relative location of the gradient stop to the other color
///     stops in the list. Orientation is not implied in color stop locations.
class GradientParser
{
    /// Dictionary of known colors (known as in the color name is known) and their associated color values.
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
            "purple": UIColor.purple,
            "indigo": UIColor(Hex: 0x3f00ff),
            "violet": UIColor(Hex: 0x7f00ff),
            "coral": UIColor(Hex: 0xff7e50),
            "gold": UIColor(Hex: 0xffd700),
            "mauve": UIColor(Hex: 0xb784a7),
            "pastelbrown": UIColor(Hex: 0x836953),
            "pistachio": UIColor(Hex: 0x93c572),
            "tomato": UIColor(Hex: 0xff6347),
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
    
    /// Parse a color. The expected format of the color is `(color value)` where `color value` is a color name in
    /// the known color list or a hex value that describes the color.
    ///
    /// - Parameter Raw: The raw string to parse as a color description.
    /// - Returns: UIColor created from the color description passed in `Raw`. UIColor.white is returned on error.
    private static func ParseColor(_ Raw: String) -> UIColor?
    {
        var Working = Raw.replacingOccurrences(of: "(", with: "")
        Working = Working.replacingOccurrences(of: ")", with: "")
        Working = Working.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        if let KnownColor = KnownColors[Working]
        {
            return KnownColor
        }
        Working = Working.replacingOccurrences(of: "#", with: "")
        //What's left should be a six-digit hex number.
        if Working.count != 6
        {
            return nil
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
    
    /// Parse a color stop's location. The expected format of the location is `(float)`.
    ///
    /// - Parameter Raw: The raw value to parse.
    /// - Returns: The color stop location.
    private static func ParseLocation(_ Raw: String) -> CGFloat
    {
        var Working = Raw.replacingOccurrences(of: "(", with: "")
        Working = Working.replacingOccurrences(of: ")", with: "")
        Working = Working.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let Result = Double(Working)!
        return CGFloat(Result)
    }
    
    /// Parse a color gradient stop. Expected format is `(color value)@(float)`.
    ///
    /// - Parameter Stop: Raw color stop in string form.
    /// - Returns: Tuple with the color stop's color and location. Nil return on error.
    private static func ParseGradientStop(_ Stop: String) -> (UIColor, CGFloat)?
    {
        let Raw = Stop.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let Parts = Raw.split(separator: "@")
        if Parts.count != 2
        {
            return nil
        }
        let ColorValue = String(Parts[0])
        let ColorLocation = String(Parts[1])
        if let FinalColor = ParseColor(ColorValue)
        {
            return (FinalColor, ParseLocation(ColorLocation))
        }
        return nil
    }
    
    /// Parse a full gradient description. Expected format is: `(color value)@(float),(color value)@(float)...'.
    ///
    /// - Parameter Raw: The list of color gradient stops in the format shown in the description.
    /// - Returns: List of tuples. Each tuple has the stop's color and location. The returned list is in the
    ///            same order as the raw list.
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
    
    /// Given a list of gradient color stops, return a string representation of it.
    ///
    /// - Parameter GradientData: List of gradient stop data, each entry a tuple with the gradient color stop's
    ///                           color and relative location.
    /// - Returns: String representation of the gradient.
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
    
    /// Creates and returns a CAGradientLayer with the gradient defined by the passed string
    /// (which uses this class' gradient definition).
    ///
    /// - Parameters:
    ///   - From: Describes the gradient to create.
    ///   - WithFrame: The frame of the layer.
    ///   - IsVertical: Determines if the gradient is drawn vertically or horizontally.
    ///   - ReverseColors: Determines if the colors in the gradient are reversed.
    /// - Returns: Gradient layer with the colors defined by `From`.
    public static func CreateGradientLayer(From: String, WithFrame: CGRect, IsVertical: Bool = true,
                                           ReverseColors: Bool = false) -> CAGradientLayer
    {
        var GradientStops = ParseGradient(From)
        GradientStops.sort{$0.1 < $1.1}
        if ReverseColors
        {
            var Scratch = [(UIColor, CGFloat)]()
            var Index = GradientStops.count - 1
            for Stop in GradientStops
            {
                let MovedColor = GradientStops[Index].0
                Scratch.append((MovedColor, Stop.1))
                Index = Index - 1
            }
            GradientStops = Scratch
        }
        let Layer = CAGradientLayer()
        Layer.frame = WithFrame
        if IsVertical
        {
            Layer.startPoint = CGPoint(x: 0.0, y: 0.0)
            Layer.endPoint = CGPoint(x: 0.0, y: 1.0)
        }
        else
        {
            Layer.startPoint = CGPoint(x: 0.0, y: 0.0)
            Layer.endPoint = CGPoint(x: 1.0, y: 0.0)
        }
        var Stops = [Any]()
        var Locations = [NSNumber]()
        for (Color, Location) in GradientStops
        {
            Stops.append(Color.cgColor as Any)
            let TheLocation = NSNumber(value: Float(Location))
            Locations.append(TheLocation)
        }
        Layer.colors = Stops
        Layer.locations = Locations
        return Layer
    }
    
    /// Creates and returns a UIImage with the gradient defined by the passed string
    /// (which uses this class' gradient definition).
    ///
    /// - Parameters:
    ///   - From: Describes the gradient to create.
    ///   - WithFrame: The frame of the layer (and resultant image).
    ///   - IsVertical: Determines if the gradient is drawn vertically or horizontally.
    ///   - ReverseColors: Determines if the colors in the gradient are reversed.
    /// - Returns: UIImage of the resultant gradient from `From`.
    public static func CreateGradientImage(From: String, WithFrame: CGRect, IsVertical: Bool = true,
                                           ReverseColors: Bool = false) -> UIImage
    {
        var GradientStops = ParseGradient(From)
        GradientStops.sort{$0.1 < $1.1}
        if ReverseColors
        {
            var Scratch = [(UIColor, CGFloat)]()
            var Index = GradientStops.count - 1
            for Stop in GradientStops
            {
                let MovedColor = GradientStops[Index].0
                Scratch.append((MovedColor, Stop.1))
                Index = Index - 1
            }
            GradientStops = Scratch
        }
        let Layer = CAGradientLayer()
        Layer.frame = WithFrame
        if IsVertical
        {
            Layer.startPoint = CGPoint(x: 0.0, y: 0.0)
            Layer.endPoint = CGPoint(x: 0.0, y: 1.0)
        }
        else
        {
            Layer.startPoint = CGPoint(x: 0.0, y: 0.0)
            Layer.endPoint = CGPoint(x: 1.0, y: 0.0)
        }
        var Stops = [Any]()
        var Locations = [NSNumber]()
        for (Color, Location) in GradientStops
        {
            Stops.append(Color.cgColor as Any)
            let TheLocation = NSNumber(value: Float(Location))
            Locations.append(TheLocation)
        }
        Layer.colors = Stops
        Layer.locations = Locations
        
        let View = UIView()
        View.frame = WithFrame
        View.bounds = WithFrame
        View.layer.addSublayer(Layer)
        UIGraphicsBeginImageContext(View.bounds.size)
        View.layer.render(in: UIGraphicsGetCurrentContext()!)
        let Image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Image!
//        return UIImage(View: View)
    }
}
