//
//  Utility.swift
//  BarcodeTest (adapted from Visualizer Clock)
//
//  Created by Stuart Rankin on 8/14/18.
//  Copyright © 2018, 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import SystemConfiguration

class Utility
{
    /// For accessing user-set settings.
    static let _Settings = UserDefaults.standard
    
    /// Returns the physical size of the passed string.
    ///
    /// - Parameters:
    ///   - TheString: The string to measure.
    ///   - TheFont: The font to apply to the string that results in the returned size.
    /// - Returns: Size of the string in screen units.
    public static func StringSize(_ TheString: String, _ TheFont: UIFont) -> CGSize
    {
        let FontAttrs = [NSAttributedString.Key.font: TheFont]
        let TheSize = (TheString as NSString).size(withAttributes: FontAttrs)
        return TheSize
    }
    
    /// Return the width of the string.
    ///
    /// - Parameters:
    ///   - TheString: The string to measure.
    ///   - TheFont: The font that will be used to render the string.
    /// - Returns: Width of the string.
    public static func StringWidth(TheString: String, TheFont: UIFont) -> CGFloat
    {
        let FontAttrs = [NSAttributedString.Key.font: TheFont]
        let TextWidth = (TheString as NSString).size(withAttributes: FontAttrs)
        return TextWidth.width
    }
    
    /// Return the height of the string.
    ///
    /// - Parameters:
    ///   - TheString: The string to measure.
    ///   - TheFont: The font that will be used to render the string.
    /// - Returns: Height of the string.
    public static func StringHeight(TheString: String, TheFont: UIFont) -> CGFloat
    {
        let FontAttrs = [NSAttributedString.Key.font: TheFont]
        let TextHeight = (TheString as NSString).size(withAttributes: FontAttrs)
        return TextHeight.height
    }
    
    //https://stackoverflow.com/questions/1324379/how-to-calculate-the-width-of-a-text-string-of-a-specific-font-and-font-size
    /// Return the width of the string.
    ///
    /// - Parameters:
    ///   - TheString: The string to measure.
    ///   - FontName: The font the string will be rendered in.
    ///   - FontSize: The size of the font.
    /// - Returns: The width of the string.
    public static func StringWidth(TheString: String, FontName: String, FontSize: CGFloat) -> CGFloat
    {
        if let TheFont = UIFont(name: FontName, size: FontSize)
        {
            let FontAttrs = [NSAttributedString.Key.font: TheFont]
            let TextWidth = (TheString as NSString).size(withAttributes: FontAttrs)
            return TextWidth.width
        }
        return 0.0
    }
    
    /// Return the height of the string.
    ///
    /// - Parameters:
    ///   - TheString: The string to measure.
    ///   - FontName: The font the string will be rendered in.
    ///   - FontSize: The size of the font.
    /// - Returns: The height of the string.
    public static func StringHeight(TheString: String, FontName: String, FontSize: CGFloat) -> CGFloat
    {
        if let TheFont = UIFont(name: FontName, size: FontSize)
        {
            let FontAttrs = [NSAttributedString.Key.font: TheFont]
            let TextHeight = (TheString as NSString).size(withAttributes: FontAttrs)
            return TextHeight.height
        }
        return 0.0
    }
    
    /// Given a string, a font, and a constraining size, return the size of the largest font that will fit in the
    /// constraint.
    /// - Parameters:
    ///   - HorizontalConstraint: Constraint - the returned font size will ensure the string will fit into this horizontal constraint.
    ///   - TheString: The string to fit into the constraint.
    ///   - FontName: The name of the font to draw the text.
    ///   - Margin: Extra value to subtrct from the HorizontalConstraint.
    /// - Returns: Font size to use with the specified font and text.
    public static func RecommendedFontSize(HorizontalConstraint: CGFloat, TheString: String, FontName: String, MinimumFontSize: CGFloat = 12.0,
                                           Margin: CGFloat = 40.0) -> CGFloat
    {
        let ConstraintWithMargin = HorizontalConstraint - Margin
        var LastGoodSize: CGFloat = 0.0
        for Scratch in 1...500
        {
            let TextWidth = StringWidth(TheString: TheString, FontName: FontName, FontSize: CGFloat(Scratch))
            if (TextWidth > ConstraintWithMargin)
            {
                return LastGoodSize
            }
            LastGoodSize = CGFloat(Scratch)
        }
        return MinimumFontSize
    }
    
    /// Given a font, print certain font metrics to the debug console.
    ///
    /// - Parameters:
    ///   - Name: Name of the font. Used to print to the debug console, not to create a new instance.
    ///   - Font: The font whose metrics will be printed.
    public static func PrintFontMetrics(Name: String, Font: UIFont)
    {
        print("Font: \(Name)")
        print("  Ascender: \(Font.ascender)")
        print("  Descender: \(Font.descender)")
        print("  xHeight: \(Font.xHeight)")
        print("  LineHeight: \(Font.lineHeight)")
    }
    
    /// Returns the sum of the font's ascender and descender.
    ///
    /// - Parameters:
    ///   - FontName: Font name.
    ///   - FontSize: Font size.
    /// - Returns: Sum of the font's ascender and descender values.
    public static func GetFontSpaces(FontName: String, FontSize: CGFloat) -> CGFloat
    {
        let TheFont = UIFont(name: FontName, size: FontSize)
        let Spaces = (TheFont?.ascender)! + (TheFont?.descender)!
        if LastFontName != FontName
        {
            LastFontName = FontName
            //PrintFontMetrics(Name: FontName, Font: TheFont!)
            //print("  Spaces: \(Spaces)")
        }
        return Spaces
    }
    
    private static var LastFontName = ""
    
    /// Given a string, a font, and a constraining rectangle, return the size of the largest font that will fit
    /// in the constraint. Both the horizontal and vertical constraints must be satisfied.
    ///
    /// - Parameters:
    ///   - HorizontalConstraint: Constraint - the returned font size will ensure the string will fit into this horizontal constraint.
    ///   - VerticalConstraint: Constraint - the returned font size will ensure the string will fit into this vertical constraint.
    ///   - TheString: The string to fit into the constraint.
    ///   - FontName: The name of the font to draw the text.
    ///   - MinimumFontSize: Minimum acceptable font size.
    ///   - MaximumFontSize: Maximum acceptable font size.
    ///   - HorizontalMargin: Horizontal margin that can be treated as a keep-out zone.
    ///   - VerticalMargin: Vertical margin that can be treated as a keep-out zone.
    /// - Returns: Font size to use with the passed constraints. If no size can be calculated, the MinimumFontSize is returned.
    public static func RecommendedFontSize(HorizontalConstraint: CGFloat, VerticalConstraint: CGFloat, TheString: String,
                                           FontName: String, MinimumFontSize: CGFloat = 12.0, MaximumFontSize: CGFloat = 400.0,
                                           HorizontalMargin: CGFloat = 40.0, VerticalMargin: CGFloat = 20.0) -> CGFloat
    {
        let FinalFontName = FontName
        let HConstraint = HorizontalConstraint - HorizontalMargin
        let VConstraint = VerticalConstraint - VerticalMargin
        var LastGoodSize: CGFloat = 0.0
        //            for Scratch in Int(MinimumFontSize) ... Int(MaximumFontSize)
        for Scratch in 1 ... 500
        {
            let Spaces = GetFontSpaces(FontName: FinalFontName, FontSize: CGFloat(Scratch))
            //print("Spaces = \(Spaces)")
            let TextWidth = StringWidth(TheString: TheString, FontName: FinalFontName, FontSize: CGFloat(Scratch))
            let TextHeight = StringHeight(TheString: TheString, FontName: FinalFontName, FontSize: CGFloat(Scratch)) - Spaces
            if TextWidth > HConstraint || TextHeight > VConstraint
            {
                #if false
                if TextWidth > HConstraint
                {
                    print("Too wide.")
                }
                if TextHeight > VConstraint
                {
                    print("Too tall.")
                }
                #endif
                if LastGoodSize > MaximumFontSize
                {
                    LastGoodSize = MaximumFontSize
                }
                return LastGoodSize
            }
            LastGoodSize = CGFloat(Scratch)
        }
        return MinimumFontSize
    }
    
    /// Truncate a double value to the number of places.
    ///
    /// - Parameters:
    ///   - Value: Value to truncate.
    ///   - ToPlaces: Where to truncate the value.
    /// - Returns: Truncated double value.
    public static func Truncate(_ Value: Double, ToPlaces: Int) -> Double
    {
        let D: Decimal = 10.0
        let X = pow(D, ToPlaces)
        let X1: Double = Double(truncating: X as NSNumber)
        let Working: Int = Int(Value * X1)
        let Final: Double = Double(Working) / X1
        return Final
    }
    
    /// Round a double value to the specified number of places.
    ///
    /// - Parameters:
    ///   - Value: Value to round.
    ///   - ToPlaces: Number of places to round to.
    /// - Returns: Rounded value.
    public static func Round(_ Value: Double, ToPlaces: Int) -> Double
    {
        let D: Decimal = 10.0
        let X = pow(D, ToPlaces + 1)
        let X1: Double = Double(truncating: X as NSNumber)
        var Working: Int = Int(Value * X1)
        let Last = Working % 10
        Working = Working / 10
        if Last >= 5
        {
            Working = Working + 1
        }
        let Final: Double = Double(Working) / (X1 / 10.0)
        return Final
    }
    
    public static func Round(_ Value: CGFloat, ToPlaces: Int) -> CGFloat
    {
        let D: Decimal = 10.0
        let X = pow(D, ToPlaces + 1)
        let X1: CGFloat = CGFloat(truncating: X as NSNumber)
        var Working: Int = Int(Value * X1)
        let Last = Working % 10
        Working = Working / 10
        if Last >= 5
        {
            Working = Working + 1
        }
        let Final: CGFloat = CGFloat(Working) / (X1 / 10.0)
        return Final
    }
    
    public static func Round(_ Value: Float, ToPlaces: Int) -> Float
    {
        let D: Decimal = 10.0
        let X = pow(D, ToPlaces + 1)
        let X1: Float = Float(truncating: X as NSNumber)
        var Working: Int = Int(Value * X1)
        let Last = Working % 10
        Working = Working / 10
        if Last >= 5
        {
            Working = Working + 1
        }
        let Final: Float = Float(Working) / (X1 / 10.0)
        return Final
    }
    
    /// Convert the passed string into a Date structure. String must be in the format of:
    /// yyyy-mm-dd hh:mm:ss
    ///
    /// - Parameter Raw: The string to convert.
    /// - Returns: Date equivalent of the string. nil on error.
    public static func MakeDateFrom(_ Raw: String) -> Date?
    {
        var Components = DateComponents()
        let Parts = Raw.split(separator: " ")
        if Parts.count != 2
        {
            return nil
        }
        
        let DatePart = String(Parts[0])
        let DateParts = DatePart.split(separator: "-")
        Components.year = Int(String(DateParts[0]))
        Components.month = Int(String(DateParts[1]))
        Components.day = Int(String(DateParts[2]))
        
        let TimePart = String(Parts[1])
        let TimeParts = TimePart.split(separator: ":")
        Components.hour = Int(String(TimeParts[0]))
        Components.minute = Int(String(TimeParts[1]))
        if TimeParts.count > 2
        {
            Components.second = Int(String(TimeParts[2]))
        }
        else
        {
            Components.second = 0
        }
        
        let Cal = Calendar.current
        return Cal.date(from: Components)
    }
    
    /// Given a Date structure, return a pretty string with the time.
    ///
    /// - Parameters:
    ///   - TheDate: The date structure whose time will be returned in a string.
    ///   - IncludeSeconds: If true, the number of seconds will be included in the string.
    /// - Returns: String representation of the time.
    public static func MakeTimeString(TheDate: Date, IncludeSeconds: Bool = true) -> String
    {
        let Cal = Calendar.current
        let Hour = Cal.component(.hour, from: TheDate)
        var HourString = String(describing: Hour)
        if Hour < 10
        {
            HourString = "0" + HourString
        }
        let Minute = Cal.component(.minute, from: TheDate)
        var MinuteString = String(describing: Minute)
        if Minute < 10
        {
            MinuteString = "0" + MinuteString
        }
        let Second = Cal.component(.second, from: TheDate)
        var Result = HourString + ":" + MinuteString
        if IncludeSeconds
        {
            var SecondString = String(describing: Second)
            if Second < 10
            {
                SecondString = "0" + SecondString
            }
            Result = Result + ":" + SecondString
        }
        return Result
    }
    
    public static func MakeTimeStamp(FromDate: Date, TimeSeparator: String = ":") -> String
    {
        let Cal = Calendar.current
        let Year = Cal.component(.year, from: FromDate)
        let Month = Cal.component(.month, from: FromDate)
        let MonthName = ["Zero", "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][Month]
        let Day = Cal.component(.day, from: FromDate)
        let DatePart = "\(Year)-\(MonthName)-\(Day) "
        let Hour = Cal.component(.hour, from: FromDate)
        var HourString = String(describing: Hour)
        if Hour < 10
        {
            HourString = "0" + HourString
        }
        let Minute = Cal.component(.minute, from: FromDate)
        var MinuteString = String(describing: Minute)
        if Minute < 10
        {
            MinuteString = "0" + MinuteString
        }
        let Second = Cal.component(.second, from: FromDate)
        var Result = HourString + TimeSeparator + MinuteString
        var SecondString = String(describing: Second)
        if Second < 10
        {
            SecondString = "0" + SecondString
        }
        Result = Result + TimeSeparator + SecondString
        return DatePart + Result
    }
    
    /// Convert an integer into a string and pad left with the specified number of zeroes.
    ///
    /// - Parameters:
    ///   - Value: Value to convert to a string.
    ///   - Count: Number of zeroes to pad left.
    /// - Returns: Value converted to a string then padded left with the specified number of zero characters.
    public static func PadLeft(Value: Int, Count: Int) -> String
    {
        var z = String(describing: Value)
        if z.count < Count
        {
            while z.count < Count
            {
                z = "0" + z
            }
        }
        return z
    }
    
    /// Given a Date structure, return the date.
    ///
    /// - Parameter Raw: Date structure to convert.
    /// - Returns: Date portion of the date as a string.
    public static func MakeDateStringFrom(_ Raw: Date) -> String
    {
        let Cal = Calendar.current
        let Year = Cal.component(.year, from: Raw)
        let Month = Cal.component(.month, from: Raw)
        let Day  = Cal.component(.day, from: Raw)
        let DatePart = "\(PadLeft(Value: Year, Count: 4))-\(PadLeft(Value: Month, Count: 2))-\(PadLeft(Value: Day, Count: 2))"
        return DatePart
    }
    
    /// Given a date structure, return a date in the formate day month year{, weekday}.
    ///
    /// - Parameters:
    ///   - Raw: Date structure to convert.
    ///   - AddDay: If true, the day of week is appended to the date.
    /// - Returns: Date portion of the date as a string.
    public static func MakeDateString(_ Raw: Date, AddDay: Bool = true) -> String
    {
        let Cal = Calendar.current
        let Year = Cal.component(.year, from: Raw)
        let Month = Cal.component(.month, from: Raw)
        let Day  = Cal.component(.day, from: Raw)
        var Final = "\(Day) \(EnglishMonths[Month - 1]) \(Year)"
        if AddDay
        {
            let DayOfWeek = Cal.component(.weekday, from: Raw)
            let WeekDay = EnglishWeekDays[DayOfWeek - 1]
            Final = Final + ", \(WeekDay)"
        }
        return Final
    }
    
    /// List of full English month names.
    public static let EnglishMonths = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    /// List of full English weekday names.
    public static let EnglishWeekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    /// Returns a random color. Colors are constructed in the HSB color space. Random values are assigned based on the entire
    /// valid range for each component.
    ///
    /// - Returns: Random color.
    public static func NaiveRandomColor() -> UIColor
    {
        let Hue = CGFloat(Double.random(in: 0.0 ... 360.0))
        let Saturation = CGFloat(Double.random(in: 0.0 ... 1.0))
        let Brightness = CGFloat(Double.random(in: 0.0 ... 1.0))
        return UIColor(hue: Hue / 360.0, saturation: Saturation, brightness: Brightness, alpha: 1.0)
    }
    
    /// Force the test value to conform to the passed range.
    ///
    /// - Parameters:
    ///   - TestValue: The value to force to the passed range.
    ///   - ValidRange: Range to compare against the test value.
    /// - Returns: If the test value falls in the ValidRange, the test value is returned. Otherwise, the test
    ///            value is clamped to the range and returned.
    public static func ForceToValidRange(_ TestValue: Int, ValidRange: ClosedRange<Int>) -> Int
    {
        if ValidRange.lowerBound > TestValue
        {
            return ValidRange.lowerBound
        }
        if ValidRange.upperBound < TestValue
        {
            return ValidRange.upperBound
        }
        return TestValue
    }
    
    /// Determines if the range to test falls within the specified high and low values.
    ///
    /// - Parameters:
    ///   - TestRange: Range to test.
    ///   - LowValue: Lowest legal value for the range.
    ///   - HighValue: Highest legal value for the range.
    /// - Returns: True if the range to test falls within the specified range, false if not.
    public static func ValidRange(_ TestRange: ClosedRange<Double>, LowValue: Double, HighValue: Double) -> Bool
    {
        if TestRange.lowerBound < LowValue
        {
            return false
        }
        if TestRange.upperBound > HighValue
        {
            return false
        }
        return true
    }
    
    /// Determines if the range to test falls within the specified high and low values.
    ///
    /// - Parameters:
    ///   - TestRange: Range to test.
    ///   - LowValue: Lowest legal value for the range.
    ///   - HighValue: Highest legal value for the range.
    /// - Returns: True if the range to test falls within the specified range, false if not.
    public static func ValidRange(_ TestRange: ClosedRange<Int>, LowValue: Int, HighValue: Int) -> Bool
    {
        if TestRange.lowerBound < LowValue
        {
            return false
        }
        if TestRange.upperBound > HighValue
        {
            return false
        }
        return true
    }
    
    /// Returns a random color. Colors are constructed in the HSB color space. Random values will fall into the supplied
    /// ranges for each component.
    ///
    /// - Parameters:
    ///   - HueRange: Range of hue values. Range must be no greater than 0.0 to 360.0.
    ///   - SaturationRange: Range of saturation values. Range must be no greater than 0.0 to 1.0.
    ///   - BrightnessRange: Range of brightness values. Range must be no greater than 0.0 to 1.0
    /// - Returns: Random color. Nil return if any range is invalid for the color component it is to be applied to.
    public static func RandomColor(HueRange: ClosedRange<Double>, SaturationRange: ClosedRange<Double>, BrightnessRange: ClosedRange<Double>) -> UIColor?
    {
        if !ValidRange(HueRange, LowValue: 0.0, HighValue: 360.0)
        {
            return nil
        }
        if !ValidRange(SaturationRange, LowValue: 0.0, HighValue: 1.0)
        {
            return nil
        }
        if !ValidRange(BrightnessRange, LowValue: 0.0, HighValue: 1.0)
        {
            return nil
        }
        let Hue = CGFloat(Double.random(in: HueRange))
        let Saturation = CGFloat(Double.random(in: SaturationRange))
        let Brightness = CGFloat(Double.random(in: BrightnessRange))
        return UIColor(hue: Hue / 360.0, saturation: Saturation, brightness: Brightness, alpha: 1.0)
    }
    
    /// Returns a random color. Colors are constructed in the HSB color space. Random values will fall into the supplied
    /// ranges for each component.
    ///
    /// - Parameters:
    ///   - HueRange: Range of hue values. Range must be no greater than 0.0 to 360.0.
    ///   - Saturation: Saturation value of the returned color. Must be in the range 0.0 to 1.0.
    ///   - Brightness: Brightness value of the returned color. Must be in the range 0.0 to 1.0.
    /// - Returns: Random color. Nil return if any range is invalid for the color component it is to be applied to.
    public static func RandomColor(HueRange: ClosedRange<Double>, Saturation: CGFloat, Brightness: CGFloat) -> UIColor?
    {
        if !ValidRange(HueRange, LowValue: 0.0, HighValue: 360.0)
        {
            return nil
        }
        if Saturation < 0.0 || Saturation > 1.0
        {
            return nil
        }
        if Brightness < 0.0 || Brightness > 1.0
        {
            return nil
        }
        let Hue = CGFloat(Double.random(in: HueRange))
        return UIColor(hue: Hue / 360.0, saturation: Saturation, brightness: Brightness, alpha: 1.0)
    }
    
    /// Returns a random color. Colors are constructed in the RGB color space. Random values will fall into the supplied
    /// ranges for each component.
    ///
    /// - Parameters:
    ///   - RedRange: Range of hue values. Range must be no greater than 0 to 255.
    ///   - GreenRange: Range of saturation values. Range must be no greater than 0 to 255.
    ///   - BlueRange: Range of brightness values. Range must be no greater than 0 to 255.
    /// - Returns: Random color. Nil return if any range is invalid for the color component it is to be applied to.
    public static func RandomColor(RedRange: ClosedRange<Int>, GreenRange: ClosedRange<Int>, BlueRange: ClosedRange<Int>) -> UIColor?
    {
        if !ValidRange(RedRange, LowValue: 0, HighValue: 255)
        {
            return nil
        }
        if !ValidRange(GreenRange, LowValue: 0, HighValue: 255)
        {
            return nil
        }
        if !ValidRange(BlueRange, LowValue: 0, HighValue: 255)
        {
            return nil
        }
        let FinalRed: CGFloat = CGFloat(Int.random(in: RedRange)) / 255.0
        let FinalGreen: CGFloat = CGFloat(Int.random(in: GreenRange)) / 255.0
        let FinalBlue: CGFloat = CGFloat(Int.random(in: BlueRange)) / 255.0
        return UIColor(red: FinalRed, green: FinalGreen, blue: FinalBlue, alpha: 1.0)
    }
    
    /// Return the source color darkened by the supplied multiplier.
    ///
    /// - Parameters:
    ///   - Source: The source color to darken.
    ///   - PercentMultiplier: How to darken the source color.
    /// - Returns: Darkened source color.
    public static func DarkerColor(_ Source: UIColor, PercentMultiplier: CGFloat = 0.8) -> UIColor
    {
        let (H, S, B) = Utility.GetHSB(SourceColor: Source)
        var NewB = B * PercentMultiplier
        if NewB < 0.0
        {
            NewB = 0.0
        }
        let Final = UIColor(hue: H, saturation: S, brightness: NewB, alpha: 1.0)
        return Final
    }
    
    /// Return the source color brightened by the supplied multiplier.
    ///
    /// - Parameters:
    ///   - Source: The source color to brighten.
    ///   - PercentMultiplier: How to brighten the source color.
    /// - Returns: Brightened source color.
    public static func BrighterColor(_ Source: UIColor, PercentMultiplier: CGFloat = 1.2) -> UIColor
    {
        let (H, S, B) = Utility.GetHSB(SourceColor: Source)
        var NewB = B * PercentMultiplier
        if NewB > 1.0
        {
            NewB = 1.0
        }
        let Final = UIColor(hue: H, saturation: S, brightness: NewB, alpha: 1.0)
        return Final
    }
    
    /// Convert a color to a string with the contents of the color as a hexidecimal number. The channels are in
    /// ARGB order with A appearing only if IncludeAlpha is true.
    ///
    /// - Parameters:
    ///   - Color: The color to convert.
    ///   - IncludeAlpha: Determines if alpha is included in the result.
    ///   - Prefix: Prefix for the returned string.
    /// - Returns: String representation of a hex value of the passed color.
    public static func ToHexString(_ Color: UIColor, IncludeAlpha: Bool = false, Prefix: String = "#") -> String
    {
        var ColorString = Prefix
        var Value = 0
        if IncludeAlpha
        {
            Value = AsIntARGB(Color)
        }
        else
        {
            Value = AsIntRGB(Color)
        }
        ColorString = ColorString + String(Value, radix: 16, uppercase: false)
        //print("Converted \(ColorToString(Color, AsRGB: true)) to \(ColorString)")
        return ColorString
    }
    
    /// Convert a color to a human-readable string.
    ///
    /// - Parameters:
    ///   - Color: The color to convert.
    ///   - AsRGB: If true, ARGB is returned. If false, HSB is returned.
    ///   - DeNormalize: If true, color values are denomalized. If false, normalized color values are returned.
    /// - Returns: String value of the passed color.
    public static func ColorToString(_ Color: UIColor, AsRGB: Bool = true, DeNormalize: Bool = true) -> String
    {
        if AsRGB
        {
            let (A, R, G, B) = GetARGB(SourceColor: Color)
            if DeNormalize
            {
                let DNA: Int = Int(Round(A * 255.0, ToPlaces: 0))
                let DNR: Int = Int(Round(R * 255.0, ToPlaces: 0))
                let DNG: Int = Int(Round(G * 255.0, ToPlaces: 0))
                let DNB: Int = Int(Round(B * 255.0, ToPlaces: 0))
                return "(\(DNA), \(DNR), \(DNG), \(DNB))"
            }
            else
            {
                return "(\(Round(A, ToPlaces: 3)), \(Round(R, ToPlaces: 3)), \(Round(G, ToPlaces: 3)), \(Round(B, ToPlaces: 3)))"
            }
        }
        else
        {
            let (H, S, B) = GetHSB(SourceColor: Color)
            if DeNormalize
            {
                let DNH = Round(H * 360.0, ToPlaces: 1)
                let DNS = Round(S, ToPlaces: 3)
                let DNB = Round(B, ToPlaces: 3)
                return "(\(DNH), \(DNS), \(DNB))"
            }
            else
            {
                return "(\(Round(H, ToPlaces: 3)), \(Round(S, ToPlaces: 3)), \(Round(B, ToPlaces: 3)))"
            }
        }
    }
    
    /// Convert a string representation of a color (in hex format) to a color. For 24- or 32-bit colors.
    ///
    /// - Parameter HexString: The string representation of a color (in hex format).
    /// - Returns: Actual color. Nil on error or otherwise unable to convert.
    public static func FromHex2(HexString: String) -> UIColor?
    {
        if HexString.count < 1
        {
            return nil
        }
        var Working = HexString.trimmingCharacters(in:. whitespacesAndNewlines)
        Working = Working.replacingOccurrences(of: "#", with: "")
        Working = Working.replacingOccurrences(of: "0x", with: "")
        Working = Working.replacingOccurrences(of: "0X", with: "")
        if Working.count == 6 || Working.count == 8
        {
        }
        else
        {
            print("Unable to convert \(HexString) to a color.")
            return nil
        }
        
        var NewColor: UIColor!
        if Working.count == 8
        {
            let LowA = Working.index(Working.startIndex, offsetBy: 0)
            let HighA = Working.index(Working.startIndex, offsetBy: 1)
            let a = Working[LowA...HighA]
            let Alpha = Int(String(describing: a), radix: 16)
            
            let LowR = Working.index(Working.startIndex, offsetBy: 2)
            let HighR = Working.index(Working.startIndex, offsetBy: 3)
            let r = Working[LowR...HighR]
            let Red = Int(String(describing: r), radix: 16)
            
            let LowG = Working.index(Working.startIndex, offsetBy: 4)
            let HighG = Working.index(Working.startIndex, offsetBy: 5)
            let g = Working[LowG...HighG]
            let Green = Int(String(describing: g), radix: 16)
            
            let LowB = Working.index(Working.startIndex, offsetBy: 6)
            let HighB = Working.index(Working.startIndex, offsetBy: 7)
            let b = Working[LowB...HighB]
            let Blue = Int(String(describing: b), radix: 16)
            
            let FAlpha = CGFloat(Alpha!) / 100.0
            let FRed = CGFloat(Red!) / 255.0
            let FGreen = CGFloat(Green!) / 255.0
            let FBlue = CGFloat(Blue!) / 255.0
            
            NewColor = UIColor.init(red: FRed, green: FGreen, blue: FBlue, alpha: FAlpha)
        }
        else
        {
            let LowR = Working.index(Working.startIndex, offsetBy: 0)
            let HighR = Working.index(Working.startIndex, offsetBy: 1)
            let r = Working[LowR...HighR]
            let Red = Int(String(describing: r), radix: 16)
            
            let LowG = Working.index(Working.startIndex, offsetBy: 2)
            let HighG = Working.index(Working.startIndex, offsetBy: 3)
            let g = Working[LowG...HighG]
            let Green = Int(String(describing: g), radix: 16)
            
            let LowB = Working.index(Working.startIndex, offsetBy: 4)
            let HighB = Working.index(Working.startIndex, offsetBy: 5)
            let b = Working[LowB...HighB]
            let Blue = Int(String(describing: b), radix: 16)
            
            let FRed = CGFloat(Red!) / 255.0
            let FGreen = CGFloat(Green!) / 255.0
            let FBlue = CGFloat(Blue!) / 255.0
            
            NewColor = UIColor.init(red: FRed, green: FGreen, blue: FBlue, alpha: 1.0)
        }
        return NewColor
    }
    
    /// Split the passed string into component parts. Each component part must be separated by a comma.
    ///
    /// - Parameter Combined: String to split and clean.
    /// - Returns: Component parts of the passed string.
    public static func GetListComponents(_ Combined: String) -> [String]?
    {
        if Combined.isEmpty
        {
            return nil
        }
        let Parts = Combined.split(separator: ",")
        var PartsList: [String] = [String]()
        for Part in Parts
        {
            var SomePart: String = String(Part)
            SomePart = SomePart.trimmingCharacters(in: .whitespacesAndNewlines)
            PartsList.append(SomePart)
        }
        return PartsList
    }
    
    /// Attempts to parse a string into a UIColor. Valid strings are:
    /// 1 RGB components in the form aa,rr,gg,bb or rr,gg,bb where all parts are in the range 0 to 255.
    /// 2 HSB components in the form hh,ss,bb where hh is in the range 0.0 to 360.0, and ss and bb in the range 0.0 to 1.0.
    /// 3 24-bit value in the form {prefix}xxxxxx where {prefix} is either 0x (case insensitive) or # and must be present.
    /// 4 32-bit value (if MayHaveAlpha is true) in the form {prefix}xxxxxxxx where {prefix} is either 0x (case insensitive) or # and must be present.
    ///
    /// - Parameters:
    ///   - Raw: String representation of the color.
    ///   - IsRGB: Interpret numbers as RGB. If false, numbers are interpreted as HSB.
    ///   - MayHaveAlpha: If true, the raw value may (or may not) have an alpha component.
    ///   - MaxAlpha: Maximum value for alpha (for ARGB).
    /// - Returns: The parsed color on success, nil on failure.
    public static func TryParse(_ Raw: String, IsRGB: Bool = true, MayHaveAlpha: Bool = true, MaxAlpha: CGFloat = 100.0) -> UIColor?
    {
        if Raw.isEmpty
        {
            return nil
        }
        let stemp = Raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if stemp.isEmpty
        {
            return nil
        }
        if stemp.prefix(1) == "#" || stemp.prefix(2).lowercased() == "0x"
        {
            //Found a hex value.
            return FromHex2(HexString: stemp)
        }
        if stemp.range(of: ",") != nil
        {
            //Contains commas, so probably rgb or hsb.
            let Parts = GetListComponents(stemp)
            if Parts == nil
            {
                return nil
            }
            if (Parts?.count)! < 3 || (Parts?.count)! > 4
            {
                return nil
            }
            if (Parts?.count)! == 4 && !IsRGB
            {
                //Too many parts for HSB.
                return nil
            }
            if IsRGB
            {
                //Assume the parts are in R, G, and B, or A, R, G, and B order.
                var Alpha: CGFloat = 1.0
                var Red: CGFloat = 0.0
                var Green: CGFloat = 0.0
                var Blue: CGFloat = 0.0
                if (Parts?.count)! == 3
                {
                    let RedS = String(Parts![0])
                    let GreenS = String(Parts![1])
                    let BlueS = String(Parts![2])
                    Red = StringToCGFloat(RedS) / 255.0
                    if Red > 1.0
                    {
                        return nil
                    }
                    Green = StringToCGFloat(GreenS) / 255.0
                    if Green > 1.0
                    {
                        return nil
                    }
                    Blue = StringToCGFloat(BlueS) / 255.0
                    if Blue > 1.0
                    {
                        return nil
                    }
                }
                else
                {
                    let AlphaS = String(Parts![0])
                    let RedS = String(Parts![1])
                    let GreenS = String(Parts![2])
                    let BlueS = String(Parts![3])
                    let Divisor = MaxAlpha <= 0.0 ? 100.0 : MaxAlpha
                    Alpha = StringToCGFloat(AlphaS) / Divisor
                    if Alpha > 1.0
                    {
                        return nil
                    }
                    Red = StringToCGFloat(RedS) / 255.0
                    if Red > 1.0
                    {
                        return nil
                    }
                    Green = StringToCGFloat(GreenS) / 255.0
                    if Green > 1.0
                    {
                        return nil
                    }
                    Blue = StringToCGFloat(BlueS) / 255.0
                    if Blue > 1.0
                    {
                        return nil
                    }
                }
                let Final = UIColor(red: Red, green: Green, blue: Blue, alpha: Alpha)
                return Final
            }
            else
            {
                //Assume the parts are in H, S, and B order.
                let HueS = String(Parts![0])
                let SatS = String(Parts![1])
                let BriS = String(Parts![2])
                let Hue = StringToCGFloat(HueS)
                let Sat = StringToCGFloat(SatS)
                let Bri = StringToCGFloat(BriS)
                let Final = UIColor(hue: Hue, saturation: Sat, brightness: Bri, alpha: 1.0)
                return Final
            }
        }
        return nil
    }
    
    /// Convert a string of a CGFloat into an actual CGFloat.
    ///
    /// - Parameters:
    ///   - Raw: String to convert.
    ///   - Default: Default value to return on error.
    /// - Returns: CGFloat value of the passed string on success, the default value on error.
    public static func StringToCGFloat(_ Raw: String, Default: CGFloat = 0.0) -> CGFloat
    {
        if Raw.isEmpty
        {
            return Default
        }
        guard let Value = NumberFormatter().number(from: Raw) else
        {
            return Default
        }
        return CGFloat(truncating: Value)
    }
    
    /// Converts the passed color to a tuple of RGB values (as integers).
    ///
    /// - Parameter Source: Source color to convert.
    /// - Returns: Tuple in the order (Red, Green, Blue) with each value an integer.
    public static func GetRGB(_ Source: UIColor) -> (Int, Int, Int)
    {
        let (_, R, G, B) = GetARGB(SourceColor: Source)
        let iR = Int(255.0 * R)
        let iG = Int(255.0 * G)
        let iB = Int(255.0 * B)
        return (iR, iG, iB)
    }
    
    /// Converts the passed color to a tuple of CGFloats, one per channel (but not including alpha).
    ///
    /// - Parameter Source: Source color to convert.
    /// - Returns: Tuple in the order (Red, Green, Blue) with all values as CGFloats in the range 0.0 to 1.0.
    public static func GetNormalizedRGB(_ Source: UIColor) -> (CGFloat, CGFloat, CGFloat)
    {
        let (_, R, G, B) = GetARGB(SourceColor: Source)
        return (R, G, B)
    }
    
    /// Converts the passed color to a tuple of RGBA values (as integers).
    ///
    /// - Parameter Source: Source color to convert.
    /// - Returns: Tuple in the order (Red, Green, Blue, Alpha) with each value an integer.
    public static func GetRGBA(_ Source: UIColor) -> (Int, Int, Int, Int)
    {
        let (A, R, G, B) = GetARGB(SourceColor: Source)
        let iR = Int(255.0 * R)
        let iG = Int(255.0 * G)
        let iB = Int(255.0 * B)
        let iA = Int(255.0 * A)
        return (iR, iG, iB, iA)
    }
    
    /// Converts the passed color to an integer. alpha, red, green, and blue channels are used.
    ///
    /// - Parameter Source: Source color to convert.
    /// - Returns: Color converted to an integer.
    public static func AsIntARGB(_ Source: UIColor) -> Int
    {
        let (A, R, G, B) = GetARGB(SourceColor: Source)
        let iA = Int(255.0 * A)
        let iR = Int(255.0 * R)
        let iG = Int(255.0 * G)
        let iB = Int(255.0 * B)
        let Final = Int((iA << 24) | (iR << 16) | (iG << 8) | (iB))
        return Final
    }
    
    /// Converts the passed color to an integer. red, green, and blue channels are used.
    ///
    /// - Parameter Source: Source color to convert.
    /// - Returns: Color converted to an integer.
    public static func AsIntRGB(_ Source: UIColor) -> Int
    {
        let (_, R, G, B) = GetARGB(SourceColor: Source)
        let iR = Int(255.0 * R)
        let iG = Int(255.0 * G)
        let iB = Int(255.0 * B)
        let Final = Int((iR << 16) | (iG << 8) | (iB))
        return Final
    }
    
    /// Given a UIColor, return the alpha red, green, and blue component parts.
    /// - Parameter SourceColor: The color whose component parts will be returned.
    /// - Returns: Tuple in the order: Alpha, Red, Green, Blue.
    public static func GetARGB(SourceColor: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat)
    {
        let Red = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        Red.initialize(to: 0.0)
        let Green = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        Green.initialize(to: 0.0)
        let Blue = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        Blue.initialize(to: 0.0)
        let Alpha = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        Alpha.initialize(to: 0.0)
        
        SourceColor.getRed(Red, green: Green, blue: Blue, alpha: Alpha)
        
        let FinalRed = Red.move()
        let FinalGreen = Green.move()
        let FinalBlue = Blue.move()
        let FinalAlpha = Alpha.move()
        
        //Clean up.
        Red.deallocate()
        Green.deallocate()
        Blue.deallocate()
        Alpha.deallocate()
        
        return (FinalAlpha, FinalRed, FinalGreen, FinalBlue)
    }
    
    /// Given a UIColor, return the hue, saturation, and brightness equivalent values.
    /// - Parameter SourceColor: The color whose hue, saturation, and brightness will be returned.
    /// - Returns: Tuple in the order: hue, saturation, brightness.
    public static func GetHSB(SourceColor: UIColor) -> (CGFloat, CGFloat, CGFloat)
    {
        let Hue = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        Hue.initialize(to: 0.0)
        let Saturation = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        Saturation.initialize(to: 0.0)
        let Brightness = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        Brightness.initialize(to: 0.0)
        let UnusedAlpha = UnsafeMutablePointer<CGFloat>.allocate(capacity: 1)
        UnusedAlpha.initialize(to: 0.0)
        
        SourceColor.getHue(Hue, saturation: Saturation, brightness: Brightness, alpha: UnusedAlpha)
        
        let FinalHue = Hue.move()
        let FinalSaturation = Saturation.move()
        let FinalBrightness = Brightness.move()
        let _ = UnusedAlpha.move()
        
        //Clean up.
        Hue.deallocate()
        Saturation.deallocate()
        Brightness.deallocate()
        UnusedAlpha.deallocate()
        
        return (FinalHue, FinalSaturation, FinalBrightness)
    }
    
    /// Edit an HSB color - substitutes the existing hue value for a new one.
    ///
    /// - Parameters:
    ///   - Source: Color to edit.
    ///   - NewHue: Replacement hue value.
    /// - Returns: Color with the new hue.
    public static func EditHSBColor(_ Source: UIColor, NewHue: CGFloat) -> UIColor
    {
        let (_, S, B) = GetHSB(SourceColor: Source)
        return UIColor(hue: NewHue, saturation: S, brightness: B, alpha: 1.0)
    }
    
    public static func EditHSBColor(_ Source: UIColor, NewSaturation: CGFloat) -> UIColor
    {
        let (H, _, B) = GetHSB(SourceColor: Source)
        return UIColor(hue: H, saturation: NewSaturation, brightness: B, alpha: 1.0)
    }
    
    public static func EditHSBColor(_ Source: UIColor, NewBrightness: CGFloat) -> UIColor
    {
        let (H, S, _) = GetHSB(SourceColor: Source)
        return UIColor(hue: H, saturation: S, brightness: NewBrightness, alpha: 1.0)
    }
    
    public static func EditeHSBColor(_ Source: UIColor, HueOffset: CGFloat) -> UIColor
    {
        let (H, S, B) = GetHSB(SourceColor: Source)
        var NewH = H + HueOffset
        NewH = abs(fmod(NewH, 1.0))
        return UIColor(hue: NewH, saturation: S, brightness: B, alpha: 1.0)
    }
    
    public static func EditHSBColor(_ Source: UIColor, BrightnessMultiplier: CGFloat) -> UIColor
    {
        let (H, S, B) = GetHSB(SourceColor: Source)
        var NewB = B * BrightnessMultiplier
        if NewB < 0.0
        {
            NewB = 0.0
        }
        if NewB > 1.0
        {
            NewB = 1.0
        }
        return UIColor(hue: H, saturation: S, brightness: NewB, alpha: 1.0)
    }
    
    /// Return the string representation of the passed color, in HSB color space. Returned value is encapsulated in "(" and ")" and
    /// is in the order hue, saturation, brightness, with alpha as the last term if IncludeAlpha is true.
    ///
    /// - Parameters:
    ///   - Color: The color to convert to a string.
    ///   - IncludeAlpha: If true, the alpha level is included as the last term.
    ///   - DenormalizeHue: If true, hue is denormalized (eg, converted from a range of 0.0 to 1.0 to 0.0 to 360.0).
    ///   - Precision: Precision value to use for rounding.
    /// - Returns: String representation of the passed color.
    public static func PrintHSBColor(_ Color: UIColor, IncludeAlpha: Bool = false, DenormalizeHue: Bool = true, Precision: Int = 2) -> String
    {
        let (H, S, B) = GetHSB(SourceColor: Color)
        let (A, _, _, _) = GetARGB(SourceColor: Color)
        var Final = "("
        var Hue = DenormalizeHue ? H * 360.0 : H
        Hue = DenormalizeHue ? Round(Hue, ToPlaces: 0) : Round(Hue, ToPlaces: Precision)
        Final = Final + "\(Hue), \(Round(S, ToPlaces: Precision)), \(Round(B, ToPlaces: Precision))"
        if IncludeAlpha
        {
            Final = Final + ", \(Round(A, ToPlaces: Precision))"
        }
        Final = Final + ")"
        return Final
    }
    
    public static func PrintGrayscaleColor(_ Color: UIColor, IncludeAlpha: Bool = false) -> String
    {
        let (_, _, White) = GetHSB(SourceColor: Color)
        let (A, _, _, _) = GetARGB(SourceColor: Color)
        var Final = "("
        Final = Final + "\(Round(White, ToPlaces: 3))"
        if IncludeAlpha
        {
            Final = Final + ",\(Round(A, ToPlaces: 3))"
        }
        Final = Final + ")"
        return Final
    }
    
    public static func MakeHSBColor(BaseHue: CGFloat, HueAdder: CGFloat, Saturation: CGFloat, Brightness: CGFloat, Alpha: CGFloat = 1.0) -> UIColor
    {
        let Scratch: CGFloat = BaseHue + HueAdder
        let FinalHue = fmod(Scratch, 1.0)
        return UIColor(hue: FinalHue, saturation: Saturation, brightness: Brightness, alpha: Alpha)
    }
    
    public static func MakeHSBColor(BaseColor: UIColor, HueAdder: CGFloat, Saturation: CGFloat, Brightness: CGFloat, Alpha: CGFloat = 1.0) -> UIColor
    {
        let (BaseHue, _, _) = GetHSB(SourceColor: BaseColor)
        return MakeHSBColor(BaseHue: BaseHue, HueAdder: HueAdder, Saturation: Saturation, Brightness: Brightness, Alpha: Alpha)
    }
    
    public static func MakeHSBColor(BaseColor: UIColor, HueAdder: CGFloat, ColorToVary: UIColor, IgnoreInvisibleColors: Bool = true) -> UIColor
    {
        if IgnoreInvisibleColors
        {
            if ColorToVary == UIColor.black
            {
                print("Skipping variations on black.")
                return ColorToVary
            }
        }
        print("ColorToVary: \(PrintHSBColor(ColorToVary))")
        //print("VariantColor: \(PrintHSBColor(ColorToVary)), BaseColor: \(PrintHSBColor(BaseColor)), HueAdder: \(HueAdder)")
        print("HueAdder: \(HueAdder)")
        let (_, S, B) = GetHSB(SourceColor: ColorToVary)
        let NewColor = MakeHSBColor(BaseColor: BaseColor, HueAdder: HueAdder, Saturation: S, Brightness: B)
        //print("NewColor: \(PrintHSBColor(NewColor))")
        return NewColor
    }
    
    public static func MakeHSBColorFrom(BaseColor: UIColor, WithVariance: CGFloat) -> UIColor
    {
        let (H, S, B) = GetHSB(SourceColor: BaseColor)
        let Scratch: CGFloat = H + WithVariance
        let FinalHue = fmod(Scratch, 1.0)
        return UIColor(hue: FinalHue, saturation: S, brightness: B, alpha: 1.0)
    }
    
    public static func MakeSimpleTime(FromHour: Int, FromMinute: Int) -> String
    {
        var Final = String(FromHour) + ":"
        var Minute = String(FromMinute)
        if FromMinute < 10
        {
            Minute = "0" + Minute
        }
        Final = Final + ":" + Minute
        return Final
    }
    
    public static func MakeSimpleTime(FromDate: Date) -> String
    {
        let Cal = Calendar.current
        let Hour = Cal.component(.hour, from: FromDate)
        let Minute = Cal.component(.minute, from: FromDate)
        let Final = "\(Hour):" + String(Minute < 10 ? "0\(Minute)" : "\(Minute)")
        return Final
    }
    
    public static func TimeFromMidnight(FromSeconds: Int) -> (Int, Int)
    {
        let Hours = FromSeconds / (60 * 60)
        let Minutes = FromSeconds % (60 * 60)
        return (Hours, Minutes)
    }
    
    public static func MakeTime(FromSeconds: Int) -> Date
    {
        let (Hours, Minutes) = TimeFromMidnight(FromSeconds: FromSeconds)
        var Components = DateComponents()
        Components.hour = Hours
        Components.minute = Minutes
        Components.timeZone = TimeZone.current
        let Cal = Calendar.current
        return Cal.date(from: Components)!
    }
    
    /// Returns the duration between two dates in seconds.
    ///
    /// - Parameters:
    ///   - Start: Start date.
    ///   - End: End date.
    /// - Returns: Number of seconds between the starting and ending date.
    public static func DurationBetween(Start: Date, End: Date) -> Int
    {
        let Cal = Calendar.current
        let Components = Cal.dateComponents([.second], from: Start, to: End)
        return abs(Components.second!)
    }
    
    /// Adds the specified number of seconds to a date and returns a new date.
    ///
    /// - Parameters:
    ///   - Start: Start date.
    ///   - Duration: Number of seconds to add to the start date.
    /// - Returns: Start date plus the duration/number of seconds.
    public static func TimeWithOffset(Start: Date, Duration: Int) -> Date
    {
        let Cal = Calendar.current
        let NewDate: Date = Cal.date(byAdding: .second, value: Duration, to: Start)!
        return NewDate
    }
    
    public static func AddDayTo(_ Original: Date) -> Date
    {
        let Cal = Calendar.current
        let NewDate: Date = Cal.date(byAdding: .day, value: 1, to: Original)!
        return NewDate
    }
    
    /// Determines if a date is in specified range of dates.
    ///
    /// - Parameters:
    ///   - Start: Start of the range of dates.
    ///   - Duration: Duration of the range in seconds.
    ///   - TestFor: Date to test to determine range inclusion.
    /// - Returns: True if the test for date is in the range, false if not.
    public static func InRange(Start: Date, Duration: Int, TestFor: Date) -> Bool
    {
        let End = TimeWithOffset(Start: Start, Duration: Duration)
        return (Start ... End).contains(TestFor)
    }
    
    /// Take a simple string time (in the form: hh:mm) and return a date structure.
    ///
    /// - Parameters:
    ///   - Raw: The raw date string to convert.
    ///   - PopulateDate: If true, the date is added to the time.
    /// - Returns: Date structure with the specified time.
    public static func SimpleStringToDate(_ Raw: String, PopulateDate: Bool = true) -> Date?
    {
        let Parts = Raw.split(separator: ":")
        if Parts.count != 2
        {
            return nil
        }
        let HourS = String(Parts[0])
        let MinuteS = String(Parts[1])
        let Now = Date()
        let Cal = Calendar.current
        var Components = DateComponents()
        Components.hour = Int(HourS)
        Components.minute = Int(MinuteS)
        Components.year = Cal.component(.year, from: Now)
        Components.month = Cal.component(.month, from: Now)
        Components.day = Cal.component(.day, from: Now)
        return Cal.date(from: Components)
    }
    
    public enum DateParts
    {
        case DateOnly
        case TimeOnly
        case TimeAndDate
        case DateAndTime
    }
    
    public static let MonthNames =
        [
            ("Jan", "January"),
            ("Feb", "February"),
            ("Mar", "March"),
            ("Apr", "April"),
            ("May", "May"),
            ("Jun", "June"),
            ("Jul", "July"),
            ("Aug", "August"),
            ("Sep", "September"),
            ("Oct", "October"),
            ("Nov", "November"),
            ("Dec", "December")
    ]
    
    public static var Weekdays =
        [
            ("Sun", "Sunday"),
            ("Mon", "Monday"),
            ("Tue", "Tuesday"),
            ("Wed", "Wednesday"),
            ("Thu", "Thursday"),
            ("Fri", "Friday"),
            ("Sat", "Saturday")
    ]
    
    public static func DateToString(_ Now: Date, Parts: DateParts = DateParts.TimeOnly,
                                    IncludeSeconds: Bool = true, DateIncludesWeekday: Bool = false,
                                    SeparateWithComma: Bool = false, PrefixWeekday: Bool = true) -> String
    {
        let Cal = Calendar.current
        var DatePart = ""
        var TimePart = ""
        let Year = Cal.component(.year, from: Now)
        let Month = MonthNames[Cal.component(.month, from: Now) - 1].0
        let Day = Cal.component(.day, from: Now)
        DatePart = String(Day) + "-" + String(Month) + "-" + String(Year)
        if DateIncludesWeekday
        {
            let WDay = Cal.component(.weekday, from: Now)
            let WDayName = Weekdays[WDay - 1].0
            if PrefixWeekday
            {
                DatePart = WDayName + "-" + DatePart
            }
            else
            {
                DatePart = DatePart + "-" + WDayName
            }
        }
        let Hour = Cal.component(.hour, from: Now)
        let Minute = Cal.component(.minute, from: Now)
        let Second = Cal.component(.second, from: Now)
        let MinuteS = String(Minute < 10 ? "0\(Minute)" : String(Minute))
        if IncludeSeconds
        {
            let SecondS = String(Second < 10 ? "0\(Second)" : String(Second))
            TimePart = String(Hour) + ":" + MinuteS + ":" + SecondS
        }
        else
        {
            TimePart = String(Hour) + ":" + MinuteS
        }
        
        let Separator = SeparateWithComma ? ", " : " "
        switch Parts
        {
        case DateParts.DateOnly:
            return DatePart
            
        case DateParts.TimeOnly:
            return TimePart
            
        case DateParts.TimeAndDate:
            return TimePart + Separator + DatePart
            
        case DateParts.DateAndTime:
            return DatePart + Separator + TimePart
        }
    }
    
    private static let RotationMap =
        [
            0: 0.0,
            1: 1.0,
            2: 0.7,
            3: 0.35,
            4: 0.01
    ]
    
    public static func GetButtonRotationDuration(FromIndex: Int) -> Double
    {
        switch FromIndex
        {
        case 0:
            return RotationMap[0]!
            
        case 1:
            return RotationMap[1]!
            
        case 2:
            return RotationMap[2]!
            
        case 3:
            return RotationMap[3]!
            
        case 4:
            return RotationMap[4]!
            
        default:
            return RotationMap[0]!
        }
    }
    
    public static func GetButtonRotationIndex(FromDuration: Double) -> Int
    {
        switch FromDuration
        {
        case 0.0:
            return 0
            
        case 1.5:
            return 1
            
        case 0.8:
            return 2
            
        case 0.35:
            return 3
            
        case 0.01:
            return 4
            
        default:
            return 0
        }
    }
    
    /// Thin wrapper around the print statement. If the DEBUG flag is false, no action occurs
    /// when this function is called.
    ///
    /// - Parameter Message: Message to print to the debug console.
    public static func dprint(_ Message: String)
    {
        #if DEBUG
        print(Message)
        #endif
    }
    
    private static var Printed = [String]()
    
    public static func print1(_ Message: String)
    {
        #if DEBUG
        if Printed.contains(Message)
        {
            return
        }
        Printed.append(Message)
        print(Message)
        #endif
    }
    
    public static func remove1(_ Message: String)
    {
        #if DEBUG
        if let Index = Printed.firstIndex(of: Message)
        {
            Printed.remove(at: Index)
        }
        #endif
    }
    
    /// Return the device class of the device we're running on. Device classes are based on screen size only.
    ///
    /// - Returns: Device class of the system.
    public static func Model() -> DeviceClasses
    {
        let ScreenHeight = Int(UIScreen.main.nativeBounds.height)
        let ScreenWidth = Int(UIScreen.main.nativeBounds.width)
        print("Looking for \(ScreenWidth)x\(ScreenHeight)")
        for (DeviceClass, (Width, Height)) in ScreenSizes
        {
            if Width == ScreenWidth && Height == ScreenHeight
            {
                return DeviceClass
            }
        }
        return DeviceClasses.Unknown
    }
    
    /// Map between device class and screen size.
    private static let ScreenSizes =
        [
            DeviceClasses.iPhoneSE: (640, 1136),
            DeviceClasses.iPhone6Plus: (1080, 1920),
            DeviceClasses.iPhone8: (750, 1334),
            DeviceClasses.iPhone8Plus: (1242, 2208),
            DeviceClasses.iPhoneX: (1125, 2436),
            DeviceClasses.iPhoneXR: (828, 1792),
            DeviceClasses.iPhoneXSMax: (1242, 2688),
            DeviceClasses.iPad: (1536, 2048),
            DeviceClasses.iPadPro10: (1668, 2224),
            DeviceClasses.iPadPro12: (2048, 2732)
    ]
    
    /// Given a device class, return its screen size.
    ///
    /// - Parameter ForDeviceClass: Device class whose screen size will be returned.
    /// - Returns: Screen size (tuple in the format (width, height)) of the device class. (0, 0) is returned if the device class is not found.
    ///            (0, 0) is returned if ForDeviceClass is DeviceClasses.Unknown
    public static func ScreenSize(ForDeviceClass: DeviceClasses) -> (Int, Int)
    {
        if ForDeviceClass == .Unknown
        {
            return (0, 0)
        }
        if let (Width, Height) = ScreenSizes[ForDeviceClass]
        {
            return (Width, Height)
        }
        return (0, 0)
    }
    
    /// Device classes segregated solely by screen size in pixels.
    /// http://iosres.com/
    ///
    /// - Unknown: Unknown device class.
    /// - iPhone SE: iPhone SE, iPhone 5s
    /// - iPhone8: iPhone 6, iPhone 7, iPhone 8, iPhone SE, iPhone {N}s
    /// - iPhone6Plus: iPhone 6s+
    /// - iPhone8Plus: iPhone 7+, iPhone 8+, iPhone {N}s+
    /// - iPhoneX: iPhone X, iPhone XS
    /// - iPhoneXR: iPhone XR
    /// - iPhoneXSMax: iPhoneXS Max
    /// - iPad: iPad Mini 2, iPad Mini 3, iPad Mini 4, iPad 3, iPad 4, iPad Air, iPad Air 2, 9.7-inch iPad Pro
    /// - iPadPro10: iPad Pro 10.5 inch
    /// - iPadPro12: iPad Pro 12.9 inch
    public enum DeviceClasses
    {
        case Unknown
        case iPhoneSE
        case iPhone6Plus
        case iPhone8
        case iPhone8Plus
        case iPhoneX
        case iPhoneXR
        case iPhoneXSMax
        case iPad
        case iPadPro10
        case iPadPro12
    }
    
    /// Returns the name of the device (assigned by the user) on which we're running.
    ///
    /// - Returns: Device name assigned by the user.
    public static func GetUserDeviceName() -> String
    {
        return UIDevice.current.name
    }
    
    /// Remove the decimal portion from a double value encoded as a string.
    ///
    /// - Parameter From: The string that holds a double value (eg, abc.xyz).
    /// - Returns: The whole number portion of the double value as a string (eg, abc.xyz returns abc).
    public static func StripDecimalPortion(From: String) -> String
    {
        if From.isEmpty
        {
            return ""
        }
        let Parts = From.split(separator: ".")
        return String(Parts[0])
    }
    
    /// List of names (from UIDevice.current.name) of devices with notches we have to contend with.
    public static let XModelNameList = ["iPhone XS Max", "iPhone X", "iPhone XS", "iPhone XR"]
    
    /// Determines if we're running on a notched device or not based on the name of the device.
    ///
    /// - Parameter DeviceName: Model/device name (generally from UIDevice.current.name).
    /// - Returns: True if the device has a notch, false if not.
    public static func IsNotchedDevice(_ DeviceName: String) -> Bool
    {
        return XModelNameList.contains(DeviceName)
    }
    
    /// Determines if the device is currently in portrait orientation.
    ///
    /// - Returns: True if the device is in a portrait orientation, false if not.
    public static func InPortraitOrientation() -> Bool
    {
        return UIScreen.main.bounds.height > UIScreen.main.bounds.width
    }
    
    /// Given a UIColor, convert it (from RGB) to a CMYK value and return the channels in a tuple.
    ///
    /// - Note: https://stackoverflow.com/questions/31667445/trying-to-use-cmyk-values-in-swift
    ///
    /// - Parameter Source: The color to convert from RGB to CMYK.
    /// - Returns: Individual channel values in a tuple with the order (Cyan, Magenta, Yellow, Black).
    public static func ToCMYK(_ Source: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat)
    {
        let (r, g, b) = GetNormalizedRGB(Source)
        if r == 0 && g == 0 && b == 0
        {
            return (0, 0, 0, 1)
        }
        var C = 1.0 - r
        var M = 1.0 - g
        var Y = 1.0 - b
        let MinCMY = min(C, M, Y)
        C = (C - MinCMY) / (1.0 - MinCMY)
        M = (M - MinCMY) / (1.0 - MinCMY)
        Y = (Y - MinCMY) / (1.0 - MinCMY)
        return (C, M, Y, MinCMY)
    }
    
    /// Given normalized C, M, Y, and K channel values, return a UIColor after conversion to RGB.
    ///
    /// - Note: https://stackoverflow.com/questions/31667445/trying-to-use-cmyk-values-in-swift
    ///
    /// - Parameters:
    ///   - Cyan: Normalized cyan value.
    ///   - Magenta: Normalized magenta value.
    ///   - Yellow: Normalized yellow value.
    ///   - Black: Normalized black value.
    /// - Returns: UIColor RGB equivalent of the passed CMYK value.
    public static func FromCMYK(_ Cyan: CGFloat, _ Magenta: CGFloat, _ Yellow: CGFloat, _ Black: CGFloat) -> UIColor
    {
        let R = (1.0 - Cyan) * (1.0 - Black)
        let G = (1.0 - Magenta) * (1.0 - Black)
        let B = (1.0 - Yellow) * (1.0 - Black)
        return UIColor(red: R, green: G, blue: B, alpha: 1.0)
    }
    
    /// Convert a vector to a tuple of three strings representing each vector component.
    ///
    /// - Parameter Raw: The vector to convert.
    /// - Returns: Tuple with three strings, one for x, y, and z.
    public static func VectorToString(_ Raw: SCNVector3) -> (String, String, String)
    {
        let X = Round(Raw.x, ToPlaces: 2)
        let Y = Round(Raw.y, ToPlaces: 2)
        let Z = Round(Raw.z, ToPlaces: 2)
        return (String(X), String(Y), String(Z))
    }
    
    /// Convert a vector to a tuple of four strings representing each vector component.
    ///
    /// - Parameter Raw: The vector to convert.
    /// - Returns: Tuple with four strings, one for x, y, z, and w.
    public static func VectorToString(_ Raw: SCNVector4) -> (String, String, String, String)
    {
        let X = Round(Raw.x, ToPlaces: 2)
        let Y = Round(Raw.y, ToPlaces: 2)
        let Z = Round(Raw.z, ToPlaces: 2)
        let W = Round(Raw.w, ToPlaces: 2)
        return (String(X), String(Y), String(Z), String(W))
    }
    
    /// Convert a quaternion to a tuple of four strings representing each component.
    ///
    /// - Parameter Raw: The quaternion to convert.
    /// - Returns: Tuple with four strings, one for x, y, z, and w.
    public static func QuaternionToString(_ Raw: SCNQuaternion) -> (String, String, String, String)
    {
        let X = Round(Raw.x, ToPlaces: 2)
        let Y = Round(Raw.y, ToPlaces: 2)
        let Z = Round(Raw.z, ToPlaces: 2)
        let W = Round(Raw.w, ToPlaces: 2)
        return (String(X), String(Y), String(Z), String(W))
    }
    
    /// Convert the passed UInt64 value into a string, separated into groups of three.
    ///
    /// - Parameters:
    ///   - Raw: The UInt64 to convert and format.
    ///   - Separator: The string to separate the groups of digits.
    /// - Returns: Value converted to a string with separators breaking the value into groups of three each.
    public static func MakeSeparatedNumber(_ Raw: UInt64, Separator: String) -> String
    {
        let SRaw = "\(Raw)"
        return SeparateNumber(SRaw, Separator: Separator)
    }
    
    /// Convert the passed UInt value into a string, separated into groups of three.
    ///
    /// - Parameters:
    ///   - Raw: The UInt to convert and format.
    ///   - Separator: The string to separate the groups of digits.
    /// - Returns: Value converted to a string with separators breaking the value into groups of three each.
    public static func MakeSeparatedNumber(_ Raw: UInt, Separator: String) -> String
    {
        let SRaw = "\(Raw)"
        return SeparateNumber(SRaw, Separator: Separator)
    }
    
    /// Convert the passed Int value into a string, separated into groups of three.
    ///
    /// - Parameters:
    ///   - Raw: The Int to convert and format.
    ///   - Separator: The string to separate the groups of digits.
    /// - Returns: Value converted to a string with separators breaking the value into groups of three each.
    public static func MakeSeparatedNumber(_ Raw: Int, Separator: String) -> String
    {
        let SRaw = "\(Raw)"
        return SeparateNumber(SRaw, Separator: Separator)
    }
    
    /// Break a number (presumably the string sent is a number) into groups of three digits separated by a
    /// specified separator.
    ///
    /// - Parameters:
    ///   - Raw: The number (in string format) to separate.
    ///   - Separator: The string to use separate groups.
    /// - Returns: String of digits (or anything, really) separated into groups of three, separated by the
    ///            specified separator string.
    private static func SeparateNumber(_ Raw: String, Separator: String) -> String
    {
        if Raw.count <= 3
        {
            return Raw
        }
        let Working = String(Raw.reversed())
        var Final = ""
        for i in 0 ..< Working.count
        {
            let AChar = String(Working[i...i])
            if i > 0 && i % 3 == 0
            {
                Final = Final + Separator
            }
            Final = Final + AChar
        }
        Final = String(Final.reversed())
        if String(Final.first!) == Separator
        {
            Final.removeFirst()
        }
        return Final
    }
    
    /// Converts a large number to a small float in a string with the appropriate suffix. For numbers over a billion, "GB" is appended.
    /// For numbers less than a billion, MB is appended.
    ///
    /// - Parameter BigNum: The number to convert.
    /// - Returns: BigNum divided by either a billion or a million then converted to a string with the appropriate suffix added.
    public static func BigNumToSuffixedNum(BigNum: Int64) -> String
    {
        let Billion: Int64 = 1000000000
        let Million: Int64 = 1000000
        let Billions: Double = Double(Double(BigNum) / Double(Billion))
        if Billions < 1.0
        {
            let Millions = Double(Double(BigNum) / Double(Million))
            let MString = "\(Millions.Round(To: 2))MB"
            return MString
        }
        else
        {
            let BString = "\(Billions.Round(To: 2))GB"
            return BString
        }
    }
    
    /// Reduce a large number to smaller, suffixed number strings.
    ///
    /// - Parameters:
    ///   - BigNum: The number to reduce then return as a string.
    ///   - AsBytes: Determines the suffix style. If true, returned numbers are assumed by measure bytes of something
    ///              and so the suffix reflects that (eg, KB, MB, GB). Otherwise, K, M, and G are used for suffixes.
    ///   - ReturnUnchangedThreshold: Values less than this value will be returned as is and without a suffix.
    /// - Returns: String value of the reduced number.
    public static func ReduceBigNum(BigNum: Int64, AsBytes: Bool = true, ReturnUnchangedThreshold: Int64 = 0) -> String
    {
        if BigNum <= ReturnUnchangedThreshold
        {
            return "\(BigNum)"
        }
        var TrillionSuffix = "T"
        var BillionSuffix = "G"
        var MillionSuffix = "M"
        var ThousandSuffix = "K"
        if AsBytes
        {
            TrillionSuffix = "TB"
            BillionSuffix = "GB"
            MillionSuffix = "MB"
            ThousandSuffix = "KB"
        }
        let Trillion: Int64 = 1000000000000
        let Billion: Int64 = 1000000000
        let Million: Int64 = 1000000
        let Thousand: Int64 = 1000
        let Trillions: Double = Double(Double(BigNum) / Double(Trillion))
        let Billions: Double = Double(Double(BigNum) / Double(Billion))
        let Millions: Double = Double(Double(BigNum) / Double(Million))
        let Thousands: Double = Double(Double(BigNum) / Double(Thousand))
        
        if Trillions >= 1.0
        {
            let TrString = "\(Trillions.Round(To: 2))" + TrillionSuffix
            return TrString
        }
        if Billions >= 1.0
        {
            let BString = "\(Billions.Round(To: 2))" + BillionSuffix
            return BString
        }
        if Millions >= 1.0
        {
            let MString = "\(Millions.Round(To: 2))" + MillionSuffix
            return MString
        }
        
        let TString = "\(Thousands.Round(To: 2))" + ThousandSuffix
        return TString
    }
}

