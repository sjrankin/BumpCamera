//
//  Versioning.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Contains versioning and copyright information. The contents of this file are automatically updated with each
/// build by the VersionUpdater utility.
public class Versioning
{
    /// Major version number.
    public static let MajorVersion: String = "1"
    
    /// Minor version number.
    public static let MinorVersion: String = "0"
    
    /// Potential version suffix.
    public static let VersionSuffix: String = ""
    
    /// Name of the application.
    public static let ApplicationName = "BumpCamera"
    
    /// Returns a standard-formatted version string in the form of "Major.Minor" with optional
    /// version suffix.
    ///
    /// - Parameter IncludeVersionSuffix: If true and the VersionSuffix value is non-empty, the contents
    ///                                   of VersionSuffix will be appended (with a leading space) to the
    ///                                   returned string.
    /// - Returns: Standard version string.
    public static func MakeVersionString(IncludeVersionSuffix: Bool = false) -> String
    {
        var Final = "Version \(MajorVersion).\(MinorVersion)"
        if IncludeVersionSuffix
        {
            if !VersionSuffix.isEmpty
            {
                Final = Final + " " + VersionSuffix
            }
        }
        return Final
    }
    
    /// Build number.
    public static let Build: Int = 1332
    
    /// Build increment.
    private static let BuildIncrement = 1
    
    /// Build ID.
    public static let BuildID: String = "7CAD56DC-A270-4387-9631-7A01E4DD8275"
    
    /// Build date.
    public static let BuildDate: String = "5 March 2019"
    
    /// Build Time.
    public static let BuildTime: String = "23:10"
    
    /// Return a standard build string.
    ///
    /// - Returns: Standard build string.
    public static func MakeBuildString() -> String
    {
        let Final = "Build \(Build), \(BuildDate) \(BuildTime)"
        return Final
    }
    
    /// Copyright years.
    public static let CopyrightYears = [2018, 2019]
    
    /// Legal holder of the copyright.
    public static let CopyrightHolder = "Stuart Rankin"
    
    /// Returns copyright text.
    ///
    /// - Returns: Program copyright text.
    public static func CopyrightText() -> String
    {
        var Years = Versioning.CopyrightYears
        var CopyrightYears = ""
        if Years.count > 1
        {
            Years = Years.sorted()
            let FirstYear = Years.first
            let LastYear = Years.last
            CopyrightYears = "\(FirstYear!) - \(LastYear!)"
        }
        else
        {
            CopyrightYears = String(describing: Years[0])
        }
        let CopyrightTextString = "Copyright © \(CopyrightYears) \(CopyrightHolder)"
        return CopyrightTextString
    }
    
    /// Return an XML-formatted key-value pair string.
    ///
    /// - Parameters:
    ///   - Key: The key part of the key-value pair.
    ///   - Value: The value part of the key-value pair.
    /// - Returns: XML-formatted key-value pair string.
    private static func MakeKVP(_ Key: String, _ Value: String) -> String
    {
        let KVP = "\(Key)=\"\(Value)\""
        return KVP
    }
    
    /// Emit version information as an XML string.
    ///
    /// - Parameter LeadingSpaceCount: The number of leading spaces to insert before
    ///                                each line of the returned result. If not specified,
    ///                                no extra leading spaces are used.
    /// - Returns: XML string with version information.
    public static func EmitXML(_ LeadingSpaceCount: Int = 0) -> String
    {
        let Spaces = String(repeating: " ", count: LeadingSpaceCount)
        var Emit = Spaces + "<Version "
        Emit = Emit + MakeKVP("Application", ApplicationName) + " "
        Emit = Emit + MakeKVP("Version", MajorVersion + "." + MinorVersion) + " "
        Emit = Emit + MakeKVP("Build", String(describing: Build)) + " "
        Emit = Emit + MakeKVP("BuildDate", BuildDate + ", " + BuildTime) + " "
        Emit = Emit + MakeKVP("BuildID", BuildID)
        Emit = Emit + ">\n"
        Emit = Emit + Spaces + "  " + CopyrightText() + "\n"
        Emit = Emit + Spaces + "</Version>"
        return Emit
    }
}
