//
//  MainUIModeHandler.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

extension MainUIViewer
{
    /// Switch the camera's mode to the specified mode type.
    ///
    /// - Parameter ModeType: The new mode type.
    func SwitchToMode(ModeType: CameraModeTypes)
    {
        if ModeType == CurrentCameraMode
        {
            print("Already in \(ModeType.rawValue) mode.")
            return
        }
        SwapIcons(ForMode: ModeType)
    }
    
    /// Swap the icons in the lower toolbar to be appropriate for the passed
    /// camera mode.
    ///
    /// - Parameter ForMode: The mode that determines the icons to display.
    func SwapIcons(ForMode: CameraModeTypes)
    {
        guard let IconList = ModeIconTable[ForMode] else
        {
            print("Error getting icon list for \(ForMode.rawValue).")
            return
        }
    }
}
