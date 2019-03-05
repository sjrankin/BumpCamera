//
//  MainUIModes.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/26/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Modes the user interface can be in.
///
/// - LiveView: Live view (also used for taking still images).
/// - VideoMode: Video mode (used for taking videos).
/// - EditMode: Edit mode (for editing images or videos in the user's photo album).
/// - OnTheFlyMode: Special mode for combining various filters, such as for multiple-exposure and the like.
/// - AnimatedGIFMode: Mode for creating animated GIFs.
/// - About: Not really a mode but used for creating the mode selection UI.
enum UIModes: Int
{
    case LiveView = 0
    case VideoMode = 1
    case EditMode = 2
    case OnTheFlyMode = 3
    case AnimatedGIFMode = 4
    case About = 10000
}
