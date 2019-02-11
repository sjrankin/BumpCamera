//
//  MonochromeColorsParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

/// Parameters to send to the metal kernel to control how it draws the image.
struct MonochromeColorParameters
{
    /// Colorspace to use: 0 = RGB, 1 = CMYK, 2 = HSB
    let Colorspace: simd_uint1
    /// Compare bright channel values using max. If false, min is used.
    let ForBright: Bool
    /// Process red channel colors.
    let ForRed: Bool
    /// Process green channel colors.
    let ForGreen: Bool
    /// Process blue channel colors.
    let ForBlue: Bool
    /// Process cyan channel colors.
    let ForCyan: Bool
    /// Process magenta channel colors.
    let ForMagenta: Bool
    /// Process yellow channel colors.
    let ForYellow: Bool
    /// Process (theoretically - this will probably never happen) black channel colors.
    let ForBlack: Bool
    /// Number of hue segments to use when in HSB.
    let HueSegmentCount: simd_uint1
    /// Which segment is selcted by the user.
    let SelectedIndex: simd_uint1
}
