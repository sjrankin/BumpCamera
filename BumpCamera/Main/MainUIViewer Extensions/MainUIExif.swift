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
    func AddExifData(To: CFDictionary, Keywords: [String], Description: String? = nil, Title: String? = nil, Author: String? = nil, Copyright: String? = nil)
    {
        let Metadata = To
        var KeywordList = ""
        for Index in 0 ..< KeywordList.count
        {
            KeywordList = KeywordList + Keywords[Index]
            if Index < KeywordList.count - 1
            {
                KeywordList = KeywordList + "; "
            }
        }
        if let Copyright = Copyright
        {
            
        }
    }
}
