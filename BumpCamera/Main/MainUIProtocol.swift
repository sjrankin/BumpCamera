//
//  MainUIProtocol.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation

/// Protocol intended for communication from child classes and the parent (main UI) class.
protocol MainUIProtocol: class
{
    /// Notifies the main UI that user favorites were changed one way or another.
    func UserFavoritesChanged()
    
    /// Notifies the main UI that a mode button was pressed.
    ///
    /// - Parameter ButtonType: Indicates the button that was pressed.
    func ModeButtonPressed(ButtonType: CameraModeTypes)
}
