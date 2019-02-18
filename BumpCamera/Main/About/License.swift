//
//  License.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation

/// Encapsulates a legal license including name of the software referenced by the license,
/// the holder of the license, and the text of the license.
class License
{
    /// Initialize the class.
    ///
    /// - Parameters:
    ///   - Name: Name of the sofware under license.
    ///   - Holder: Name of the holder of the license.
    ///   - Text: Text of the license.
    init(Name: String, Holder: String, Text: String)
    {
        _Title = Name
        LicenseHolder = Holder
        LicenseText = Text
    }
    
    /// Initialize the class.
    ///
    /// - Parameters:
    ///   - Name: Name of the sofware under license.
    ///   - Holder: Name of the holder of the license.
    ///   - Text: Text of the license.
    ///   - Use: Usage of the code.
    init(Name: String, Holder: String, Text: String, Use: String)
    {
        _Title = Name
        LicenseHolder = Holder
        LicenseText = Text
        _Use = Use
    }
    
    private var _Title: String = ""
    /// Get or set the name of the software under license.
    public var SoftwareTitle: String
    {
        get
        {
            return _Title
        }
        set
        {
            _Title = newValue
        }
    }
    
    private var _Holder: String = ""
    /// Get or set the name of the holder of the license.
    public var LicenseHolder: String
    {
        get
        {
            return _Holder
        }
        set
        {
            _Holder = newValue
        }
    }
    
    private var _Text: String = ""
    /// Get or set the text of the license.
    public var LicenseText: String
    {
        get
        {
            return _Text
        }
        set
        {
            _Text = newValue
        }
    }
    
    private var _Use: String = ""
    /// Get or set the usage information.
    public var Usage: String
    {
        get
        {
            return _Use
        }
        set
        {
            _Use = newValue
        }
    }
}
