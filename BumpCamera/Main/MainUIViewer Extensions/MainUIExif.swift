//
//  MainUIExif.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/17/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

extension MainUIViewer
{
    /// Add Exif data to the passed dictionary. What gets added is controlled by passed parameters and the Privacy Manager.
    ///
    /// - Parameters:
    ///   - ExifData: The dictionary of Exif data to modify.
    ///   - Keywords: List of keywords to add.
    ///   - Description: Description string to add.
    ///   - Title: Title string to add.
    ///   - Author: Author name.
    ///   - Copyright: Copyright data.
    ///   - AddLocation: Determines if location is added or not.
    func AddExifData(To ExifData: inout CFDictionary, Keywords: [String], Description: String? = nil, Title: String? = nil,
                     Author: String? = nil, Copyright: String? = nil, AddLocation: Bool = false)
    {
        let Metadata = ExifData
        var KeywordList = ""
        for Index in 0 ..< KeywordList.count
        {
            KeywordList = KeywordList + Keywords[Index]
            if Index < KeywordList.count - 1
            {
                KeywordList = KeywordList + "; "
            }
        }
        if !PrivacyManager.IsPrivacyViolation(For: .EXIFUserName)
        {
            if let Copyright = Copyright
            {
                
            }
        }
        if AddLocation
        {
            if !PrivacyManager.IsPrivacyViolation(For: .EXIFLocation)
            {
                
            }
        }
    }
}
