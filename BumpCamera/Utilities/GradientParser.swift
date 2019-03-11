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
            "pink": UIColor(Hex: 0xffc0cb),
            "pastelyellow": UIColor(Hex: 0xfdfd96),
            "saffron": UIColor(Hex: 0xf4c430),
            "magicmint": UIColor(Hex: 0xaaf0d1),
            "yellowprocess": UIColor(Hex: 0xffef00),
            "thistle": UIColor(Hex: 0xd8bfd8),
            "honeydew": UIColor(Hex: 0xf0fff0),
            "lavender": UIColor(Hex: 0xe6e6fa),
            "mustard": UIColor(Hex: 0xffdb58),
            "babyblue": UIColor(Hex: 0x89cff0),
            "chartreuse": UIColor(Hex: 0xdfff00),
            "atomictangerine": UIColor(Hex: 0xff9966),
            "daffodil": UIColor(Hex: 0xffff31),
            "mistyrose": UIColor(Hex: 0xffe4e1),
            "greenpastel": UIColor(Hex: 0xbaed91),
            "pastelpink": UIColor(Hex: 0xffd1dc)
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
    
    /// Handle a hue-based color. The expected format of the color is `[hue {, sat {, bri}}]` where hue is a normalized value
    /// that determines the hue of the color, optional sat is the saturation, and optional bri is the brightness. If brightness
    /// is desired, saturation must also be specified.
    ///
    /// - Note: This class cues from the color bracket - hue colors use square brackets.
    ///
    /// - Parameter Raw: String to parse.
    /// - Returns: UIColor created from the raw hue string.
    private static func ParseHueValue(_ Raw: String) -> UIColor?
    {
        var Working = Raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        Working = Working.replacingOccurrences(of: "[", with: "")
        Working = Working.replacingOccurrences(of: "]", with: "")
        let Parts = Working.split(separator: ",")
        var HueValue = 0.0
        var SaturationValue = 1.0
        var BrightnessValue = 1.0
        switch Parts.count
        {
        case 0:
            //Probably will occur only if Raw is empty.
            return nil
            
        case 1:
            //Hue only.
            if let HueOK = Double(String(Parts[0]))
            {
                HueValue = HueOK.Clamp(0.0, 1.0)
            }
            else
            {
                return nil
            }
            
        case 2:
            //Hue and saturation.
            if let HueOK = Double(String(Parts[0]))
            {
                HueValue = HueOK.Clamp(0.0, 1.0)
            }
            else
            {
                return nil
            }
            if let SatOK = Double(String(Parts[1]))
            {
                SaturationValue = SatOK.Clamp(0.0, 1.0)
            }
            else
            {
                return nil
            }
            
        case 3:
            //Hue, saturation, and brightness
            if let HueOK = Double(String(Parts[0]))
            {
                HueValue = HueOK.Clamp(0.0, 1.0)
            }
            else
            {
                return nil
            }
            if let SatOK = Double(String(Parts[1]))
            {
                SaturationValue = SatOK.Clamp(0.0, 1.0)
            }
            else
            {
                return nil
            }
            if let BriOK = Double(String(Parts[2]))
            {
                BrightnessValue = BriOK.Clamp(0.0, 1.0)
            }
            else
            {
                return nil
            }
            
        default:
            return nil
        }
        
        return UIColor(hue: CGFloat(HueValue), saturation: CGFloat(SaturationValue), brightness: CGFloat(BrightnessValue), alpha: 1.0)
    }
    
    /// Parse a color. The expected format of the color is `(color value)` where `color value` is a color name in
    /// the known color list or a hex value that describes the color.
    ///
    /// - Parameter Raw: The raw string to parse as a color description.
    /// - Returns: UIColor created from the color description passed in `Raw`. UIColor.white is returned on error.
    private static func ParseColor(_ Raw: String) -> UIColor?
    {
        var Working = Raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        if Working.first == "["
        {
            return ParseHueValue(Working)
        }
        Working = Working.replacingOccurrences(of: "(", with: "")
        Working = Working.replacingOccurrences(of: ")", with: "")
        
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
    
    /// Insert the passed gradient stop into the full gradient. The returned result will have the gradient
    /// in location order.
    ///
    /// - Parameters:
    ///   - Into: The full gradient where the gradient stop will be placed.
    ///   - Color: The color of the gradient stop to insert.
    ///   - Location: The location of the gradient stop to insert.
    /// - Returns: New full gradient with the newly inserted gradient stop.
    public static func InsertGradientStop(Into: String, _ Color: UIColor, _ Location: CGFloat) -> String
    {
        var Parts = ParseGradient(Into)
        Parts.append((Color, Location))
        Parts.sort{$0.1 < $1.1}
        return AssembleGradient(Parts)
    }
    
    /// Removes the gradient stop at the specified index.
    ///
    /// - Parameters:
    ///   - Gradients: Source gradient description.
    ///   - AtIndex: The index of the gradient stop to remove.
    /// - Returns: New gradient with the specified gradient stop removed on success, nil on failure/error (most
    ///            likely due to invalid index specified).
    public static func RemoveGradientStop(_ Gradients: String, AtIndex: Int) -> String?
    {
        if AtIndex < 0
        {
            return nil
        }
        var Parts = ParseGradient(Gradients)
        if AtIndex > Parts.count - 1
        {
            return nil
        }
        Parts.remove(at: AtIndex)
        return AssembleGradient(Parts)
    }
    
    /// Removes all gradient stops at the specified location.
    ///
    /// - Parameters:
    ///   - Gradients: Source gradient description.
    ///   - AtLocation: The location at which to remove gradient stops.
    /// - Returns: Gradient with all gradient stops at the specified location removed. If no gradient stops were
    ///            found at the specified location, the gradient is returned unchanged.
    public static func RemoveGradientStop(_ Gradients: String, AtLocation: CGFloat) -> String
    {
        var Parts = ParseGradient(Gradients)
        Parts.removeAll(where: {$0.1 == AtLocation})
        return AssembleGradient(Parts)
    }
    
    /// Reverse the color locations in the gradient. The locations remain unchanged but the colors are moved.
    ///
    /// - Parameter Gradients: Source gradient description.
    /// - Returns: New gradient description with inverted color locations.
    public static func ReverseColorLocations(_ Gradients: String) -> String
    {
        var Parts = ParseGradient(Gradients)
        if Parts.count < 1
        {
            return ""
        }
        var NewList = [(UIColor, CGFloat)]()
        for Index in 0 ..< Parts.count
        {
            let Color = Parts[Index].0
            let Where = Parts[(Parts.count - 1) - Index].1
            NewList.append((Color, Where))
        }
        NewList.sort{$0.1 < $1.1}
        return AssembleGradient(NewList)
    }
    
    /// Add a gradient stop to the end of the passed gradient description.
    ///
    /// - Parameters:
    ///   - Gradients: Source gradient description.
    ///   - Color: Color of the gradient stop to add.
    ///   - Location: Location of the gradient stop to add.
    /// - Returns: New gradient description. Depending on the value of `Location`, the appended gradient stop may end up
    ///            elsewhere in the gradient (eg, not at the end).
    public static func AddGradientStop(_ Gradients: String, Color: UIColor, Location: CGFloat) -> String
    {
        var Parts = ParseGradient(Gradients)
        Parts.append((Color, Location))
        return AssembleGradient(Parts)
    }
    
    /// Insert a new gradient stop at the specified location in the passed gradient.
    ///
    /// - Parameters:
    ///   - Gradients: Source gradient description.
    ///   - Index: Where to insert the new gradient.
    ///   - Color: Color of the gradient stop to add.
    ///   - Location: Location of the gradient stop to add.
    /// - Returns: New gradient description. The gradient stop may be moved depending on its `Location` value.
    public static func InsertGradientStop(_ Gradients: String, Index: Int, Color: UIColor, Location: CGFloat) -> String
    {
        var Parts = ParseGradient(Gradients)
        Parts.append((Color, Location))
        let Index1 = Index
        let Index2 = Parts.count - 1
        let Final = SwapGradientStops(AssembleGradient(Parts), Index1: Index1, Index2: Index2)
        return Final!
    }
    
    /// Sort the passed gradient by gradient stop location.
    ///
    /// - Parameter Gradients: Source description of the gradient.
    /// - Returns: Sorted gradient description.
    public static func SortGradient(_ Gradients: String) -> String
    {
        var Parts = ParseGradient(Gradients)
        Parts.sort{$0.1 < $1.1}
        return AssembleGradient(Parts)
    }
    
    /// Swap two gradients in the passed gradient description. If Index1 is the same as Index2, the original gradient is returned.
    /// The gradient will be sorted on location order before being returned.
    ///
    /// - Parameters:
    ///   - Gradients: Source gradient description.
    ///   - Index1: Index of first item to swap.
    ///   - Index2: Index of second item to swap.
    /// - Returns: New gradient description with swapped gradients. Nil on error (most likely due to an index out of range).
    public static func SwapGradientStops(_ Gradients: String, Index1: Int, Index2: Int) -> String?
    {
        var Parts = ParseGradient(Gradients)
        if Index1 < 0
        {
            return nil
        }
        if Index2 < 0
        {
            return nil
        }
        if Index2 < Index1
        {
            return nil
        }
        if Index1 == Index2
        {
            return Gradients
        }
        if Index1 > Index2
        {
            return nil
        }
        if Index2 > Parts.count - 1
        {
            return nil
        }
        
        let (Color1, Stop1) = (GradientStop(From: Gradients, At: Index1))!
        let (Color2, Stop2) = (GradientStop(From: Gradients, At: Index2))!
        
        var NewGradient = ReplaceGradientStop(Gradients, Color: Color1, Location: Stop2, AtIndex: Index1)
        NewGradient = ReplaceGradientStop(NewGradient!, Color: Color2, Location: Stop1, AtIndex: Index2)
        Parts = ParseGradient(NewGradient!)
        Parts.sort{$0.1 < $1.1}
        return AssembleGradient(Parts)
    }
    
    /// Replace an existing gradient stop in the passed gradient with a new gradient stop.
    ///
    /// - Parameters:
    ///   - Gradients: Source gradient description.
    ///   - Color: The new gradient stop color.
    ///   - Location: The new gradient stop location.
    ///   - AtIndex: Determines the gradient stop that will be replaced.
    /// - Returns: New gradient description with the edited gradient stop. On error, nil is returned.
    public static func ReplaceGradientStop(_ Gradients: String, Color: UIColor, Location: CGFloat, AtIndex: Int) -> String?
    {
        
        var Parts = ParseGradient(Gradients)
        if AtIndex < 0
        {
            return nil
        }
        if AtIndex > Parts.count - 1
        {
            return nil
        }
        Parts[AtIndex] = (Color, Location)
        return AssembleGradient(Parts)
    }
    
    /// Return the gradient stop at the specified index in the passed gradient description.
    ///
    /// - Parameters:
    ///   - From: Source gradient description.
    ///   - At: Indicates the position in the gradient description of the gradient stop to return.
    /// - Returns: Tuple of the color and location of the specified gradient stop on success, nil on failure.
    public static func GradientStop(From: String, At: Int) -> (UIColor, CGFloat)?
    {
        let Parts = ParseGradient(From)
        if At < 0
        {
            return nil
        }
        if At > Parts.count - 1
        {
            return nil
        }
        return Parts[At]
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
    
    /// Holds previously-generated gradient sets.
    private static var CachedGradients = [String: [UIColor]]()
    
    /// Clear the gradient cache.
    public static func ClearGradientCache()
    {
        CachedGradients.removeAll()
    }
    
    /// Resolve the passed gradient description into a list of 256 colors.
    ///
    /// - Note:
    ///    - If the description does not contain a color at (0.0) or at (1.0), an implicit color will be
    ///      added at each missing end. See `GenerateGradient` for more information.
    ///    - Provided the description is not changed between calls, resolved gradients are cached for
    ///      improving performance.
    ///
    /// - Parameter Description: The gradient description.
    /// - Returns: List of 256 colors based on the gradient description.
    public static func ResolveGradient(_ Description: String) -> [UIColor]
    {
        if let CachedColors = CachedGradients[Description]
        {
            return CachedColors
        }
        let Generated = GenerateGradient(From: Description, Range: 256)
        CachedGradients[Description] = Generated
        return Generated
    }
    
    /// Resolve a gradient of 256 colors from `Color1` to `Color2`. `Color1` starts at (0.0) and
    /// `Color2` starts at (1.0).
    ///
    /// - Parameters:
    ///   - Color1: First color of the gradient.
    ///   - Color2: Second color of the gradient.
    /// - Returns: List of 256 colors from `Color1` to `Color2`.
    public static func ResolveGradient(Color1: UIColor, Color2: UIColor) -> [UIColor]
    {
        return GenerateGradient(From: Color1, To: Color2, Range: 256)
    }
    
    /// Generate a list of colors with `Range` colors from the passed gradient description.
    ///
    /// - Parameters:
    ///   - From: The gradient description used to create the list of colors.
    ///   - Range: Determines the number of colors in the list.
    ///   - ImplicitFirstColor: If the description does not contain a color stop at (0.0), this color will be
    ///                         used as the initial color.
    ///   - ImplicitLastColor: If the description does not contain a color stop at (1.0), this color will be
    ///                        used as the terminal color.
    /// - Returns: List of colors created from the description. This list may be empty if the description does
    ///            not resolve to any colors or if `Range` is less than 1. If `Range` is 1, the returned list
    ///            will consist of only the sole color in the gradient (regardless of its location).
    public static func GenerateGradient(From: String, Range: Int, ImplicitFirstColor: UIColor = UIColor.black,
                                        ImplicitLastColor: UIColor = UIColor.black) -> [UIColor]
    {
        var Results = [UIColor]()
        if Range < 1
        {
            return Results
        }
        let Raw = ParseGradient(From)
        if Raw.count < 1
        {
            return Results
        }
        if Raw.count == 1
        {
            for _ in 0 ..< Range
            {
                Results.append(Raw[0].0)
            }
            return Results
        }
        var Working = [(UIColor, Double)]()
        var FoundFirst = false
        var FoundLast = false
        for (Color, Percent) in Raw
        {
            if Percent == 0.0
            {
                FoundFirst = true
            }
            if Percent == 1.0
            {
                FoundLast = true
            }
            Working.append((Color, Double(Percent) * Double(Range)))
        }
        if !FoundFirst
        {
            Working.insert((ImplicitLastColor, 0.0), at: 0)
        }
        if !FoundLast
        {
            Working.append((ImplicitLastColor, Double(Range)))
        }
        
        for Index in 0 ..< Range
        {
            let ColorRange = GetRangeDefinedColors(Index, Working)
            let ImpliedColor = CreateImpliedColor(ColorRange)
            Results.append(ImpliedColor)
        }
        
        return Results
    }
    
    /// Generate a list of colors with in the specified range of colors.
    ///
    /// - Parameters:
    ///   - From: Starting color (position set to (0.0)).
    ///   - To: Ending color (position set to (1.0)).
    ///   - Range: Number of colors to return.
    /// - Returns: List of colors from `From` to `To`.
    public static func GenerateGradient(From: UIColor, To: UIColor, Range: Int) -> [UIColor]
    {
        var Results = [UIColor]()
        var Working = [(UIColor, Double)]()
        Working.append((From, 0.0))
        Working.append((To, 1.0))
        for Index in 0 ..< Range
        {
            let ColorRange = GetRangeDefinedColors(Index, Working)
            let ImpliedColor = CreateImpliedColor(ColorRange)
            Results.append(ImpliedColor)
        }
        
        return Results
    }
    
    /// Given two colors and value indicating a percent somewhere in between them, return the color a the
    /// percent.
    ///
    /// - Parameter Segment: Tuple with the low color, high color, and the percent in between them.
    /// - Returns: Color derived from the two passed colors and location between them.
    private static func CreateImpliedColor(_ Segment: (UIColor, UIColor, Double)) -> UIColor
    {
        let LowR = Segment.0.r * CGFloat(1.0 - Segment.2)
        let LowG = Segment.0.g * CGFloat(1.0 - Segment.2)
        let LowB = Segment.0.b * CGFloat(1.0 - Segment.2)
        let HighR = Segment.1.r * CGFloat(Segment.2)
        let HighG = Segment.1.g * CGFloat(Segment.2)
        let HighB = Segment.1.b * CGFloat(Segment.2)
        return UIColor(red: LowR + HighR, green: LowG + HighG, blue: LowB + HighB, alpha: 1.0)
    }
    
    /// Given a location, return the two colors that define the segment where the location is, as well as the
    /// percent between the two ccolors for the location.
    ///
    /// - Parameters:
    ///   - Index: Location of the point that defines which colors to return.
    ///   - ColorList: List of colors and points for the colors.
    /// - Returns: Tuple with the low color, high color, and percent `Index` is in between them.
    private static func GetRangeDefinedColors(_ Index: Int, _ ColorList: [(UIColor, Double)]) -> (UIColor, UIColor, Double)
    {
        let DIndex = Double(Index)
        //Need the - 1 for count value because we use index value + 1 in the loop
        for ColorIndex in 0 ..< ColorList.count - 1
        {
            if DIndex >= ColorList[ColorIndex].1 && DIndex <= ColorList[ColorIndex + 1].1
            {
                let LowColor = ColorList[ColorIndex].0
                let HighColor = ColorList[ColorIndex + 1].0
                let Range = ColorList[ColorIndex + 1].1 - ColorList[ColorIndex].1
                let AdjustedLocation = DIndex - ColorList[ColorIndex].1
                let Percent = AdjustedLocation / Range
                return (LowColor, HighColor, Percent)
            }
        }
        //We should be at the end segment.
        let LowColor = ColorList[ColorList.count - 2].0
        let HighColor = ColorList[ColorList.count - 1].0
        let Range = ColorList.last!.1 - ColorList[ColorList.count - 2].1
        let AdjustedLocation = DIndex - ColorList[ColorList.count - 2].1
        let Percent = AdjustedLocation / Range
        return (LowColor, HighColor, Percent)
    }
    
    // MARK: Predefined gradients.
    
    /// Predefined white to red gradient.
    static let WhiteRedGradient = "(White)@(0.0),(Red)@(1.0)"
    
    /// Predefined white to green gradient.
    static let WhiteGreenGradient = "(White)@(0.0),(Green)@(1.0)"
    
    /// Predefined white to blue gradient.
    static let WhiteBlueGradient = "(White)@(0.0),(Blue)@(1.0)"
    
    /// Predefined white to cyan gradient.
    static let WhiteCyanGradient = "(White)@(0.0),(Cyan)@(1.0)"
    
    /// Predefined white to magenta gradient.
    static let WhiteMagentaGradient = "(White)@(0.0),(Magenta)@(1.0)"
    
    /// Predefined white to yellow gradient.
    static let WhiteYellowGradient = "(White)@(0.0),(Yellow)@(1.0)"
    
    /// Predefined whte to black gradient.
    static let WhiteBlackGradient = "(White)@(0.0),(Black)@(1.0)"
    
    /// Predefined red to black gradient.
    static let RedBlackGradient = "(Red)@(0.0),(Black)@(1.0)"
    
    /// Predefined green to black gradient.
    static let GreenBlackGradient = "(Green)@(0.0),(Black)@(1.0)"
    
    /// Predefined blue to black gradient.
    static let BlueBlackGradient = "(Blue)@(0.0),(Black)@(1.0)"
    
    /// Predefined cyan to black gradient.
    static let CyanBlackGradient = "(Cyan)@(0.0),(Black)@(1.0)"
    
    /// Predefined magenta to black gradient.
    static let MagentaBlackGradient = "(Magenta)@(0.0),(Black)@(1.0)"
    
    /// Predefined yellow to black gradient.
    static let YellowBlackGradient = "(Yellow)@(0.0),(Black)@(1.0)"
    
    /// Predefined cyan to blue gradient.
    static let CyanBlueGradient = "(Cyan)@(0.0),(Blue)@(1.0)"
    
    /// Predefined cyan to blue to black gradient.
    static let CyanBlueBlackGradient = "(Cyan)@(0.0),(Blue)@(0.8),(Black)@(1.0)"
    
    /// Predefined red to orange gradient.
    static let RedOrangeGradient = "(Red)@(0.0),(Orange)@(1.0)"
    
    /// Predefined yellow to red gradient.
    static let YellowRedGradient = "(Yellow)@(0.0),(Red)@(1.0)"
    
    /// Predefined pistachio to green gradient.
    static let PistachioGreenGradient = "(Pistachio)@(0.0),(Green)@(1.0)"
    
    /// Predefined pistachio to black gradient.
    static let PistachioBlackGradient = "(Pistachio)@(0.0),(Black)@(1.0)"
    
    /// Predefined tomato to red gradient.
    static let TomatoRedGradient = "(Tomato)@(0.0),(Red)@(1.0)"
    
    /// Predefined tomato to black gradient.
    static let TomatoBlackGradient = "(Tomato)@(0.0),(Black)@(1.0)"
    
    /// Predefined RGB gradient.
    static let RGBGradient = "(Red)@(0.0),(Green)@(0.5),(Blue)@(1.0)"
    
    /// Predefined CMYK gradient.
    static let CMYKGradient = "(Cyan)@(0.0),(Magenta)@(0.33),(Yellow)@(0.66),(Black)@(1.0)"
    
    /// Predefined metallic gradient.
    static let MetallicGradient = "(White)@(0.0),(DarkGray)@(0.25),(White)@(0.5),(DarkGray)@(0.75),(White)@(1.0)"
    
    /// Predefined hue gradient with steps every 0.1.
    static let HueGradient = "[0.0]@(0.0),[0.1]@(0.1),[0.2]@(0.2),[0.3]@(0.3),[0.4]@(0.4),[0.5]@(0.5),[0.6]@(0.6),[0.7]@(0.7),[0.8]@(0.8),[0.9]@(0.9),[1.0]@(1.0)"
    
    /// Predefined rainbow gradient (following the ROYGBIV model).
    static let RainbowGradient = "(Red)@(0.0),(Orange)@(0.18),(Yellow)@(0.36),(Green)@(0.52),(Blue)@(0.68),(Indigo)@(0.84),(Violet)@(1.0)"
    
    /// Predefined pastel gradient 1.
    static let PastelGradient1 = "(Daffodil)@(0.0),(Gold)@(0.25),(Mustard)@(0.4),(Pink)@(0.6),(AtomicTangerine)@(0.75),(Coral)@(1.0)"
}
