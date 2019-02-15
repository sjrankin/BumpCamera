//
//  ColorPickerProtocol.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Protocol for sending colors to be edited and received new colors in return.
protocol ColorPickerProtocol
{
    /// Sets the color to be edited. Used by the caller of the color picker.
    ///
    /// - Parameter Color: The color to be edited.
    /// - Parameter Tag: Value returned to the caller in EditedColor. Unchanged by the color picker.
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    
    
    /// Sets the newly edited color.
    ///
    /// - Parameter Edited: The user-edited color. May be nil if no changes (eg, the user selected the cancel operation).
    ///                     Used by the color picker.
    /// - Parameter Tag: Value returned to the caller from an initial call to ColorToEdit.
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
}
