//
//  PrivacyManager.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Class that helps maintain user privacy by determining what functions may violate the user's privacy settings.
class PrivacyManager
{
    static let _Settings = UserDefaults.standard
    
    /// Returns the value of the maximum privacy flag.
    ///
    /// - Returns: Value of the maximum privacy flag.
    public static func InMaximumPrivacy() -> Bool
    {
        return _Settings.bool(forKey: "MaximumPrivacy")
    }
    
    /// Sets the maximum privacy level to the passed value. If maximum privacy is enabled,
    /// this function sets all privacy flags to false for other areas.
    ///
    /// - Parameter enabled: Value to set the maximum privacy flag.
    public static func SetMaximumPrivacy(To enabled: Bool)
    {
        _Settings.set(enabled, forKey: "MaximumPrivacy")
        if !enabled
        {
            _Settings.set(false, forKey: "SaveRuntimeInformation")
            _Settings.set(false, forKey: "CollectPerformanceStatistics")
            _Settings.set(false, forKey: "SaveUserInformationInEXIF")
            _Settings.set(false, forKey: "SaveGPSCoordinatesWithImage")
            _Settings.set(false, forKey: "AllowUserSampleImages")
            _Settings.set(false, forKey: "UseActivityLog")
        }
    }
    
    /// Determines if accessing functionality in the passed area is a privacy violation according to how the
    /// user set privacy controls.
    ///
    /// - Parameter For: The functional area the caller wants to access.
    /// - Returns: True if accessing the passed functional area is a privacy violation, false if not.
    public static func IsPrivacyViolation(For: PrivacyAreas) -> Bool
    {
        if !_Settings.bool(forKey: "MaximumPrivacy")
        {
            return true
        }
        
        switch For
        {
        case .Runtime:
            return _Settings.bool(forKey: "SaveRuntimeInformation")
            
        case .Performance:
            return _Settings.bool(forKey: "CollectPerformanceStatistics")
            
        case .EXIFUserName:
            return _Settings.bool(forKey: "SaveUserInformationInEXIF")
            
        case .EXIFLocation:
            return _Settings.bool(forKey: "SaveGPSCoordinatesWithImage")
            
        case .SampleImage:
            return _Settings.bool(forKey: "AllowUserSampleImages")
            
        case .ActivityLog:
            #if DEBUG
            return _Settings.bool(forKey: "UseActivityLog")
            #else
            return false
            #endif
        }
        
        return false
    }
}

/// Represents a functionary area that may potentially violate privacy of the user. The user can change privacy settings
/// as he sees fit.
///
/// - Runtime: Save runtime information.
/// - Performance: Filter performance data.
/// - EXIFLocation: Save device's GPS information in EXIF data.
/// - EXIFUserName: Save user's name and copyright information in EXIF data.
/// - SampleImage: Save sample image for filter settings.
/// - ActivityLog: Collect, maintain, and save activity logs. Valid only in DEBUG mode.
enum PrivacyAreas
{
    case Runtime
    case Performance
    case EXIFLocation
    case EXIFUserName
    case SampleImage
    case ActivityLog
}
