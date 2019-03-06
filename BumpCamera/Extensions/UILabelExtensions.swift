//
//  UILabelExtensions.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/25/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Extensions for UILabel.
extension UILabel
{
    /// Determines if the text of label is larger than can be fully displayed. Returns true if
    /// the text is too big for the size of the label, false if not.
    ///
    /// - Note:
    ///    - [How to check if UILabel is truncated](https://stackoverflow.com/questions/3077109/how-to-check-if-uilabel-is-truncated)
    var IsTruncated: Bool
    {
        guard let Text = text else
        {
            return false
        }
        let TextSize = (Text as NSString).boundingRect(with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
                                                       options: .usesLineFragmentOrigin,
                                                       attributes: [.font: font as Any],
                                                       context: nil).size
        return TextSize.height > bounds.size.height
    }
}
