//
//  ImageScanParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct ImageScanParameters
{
    let Action: simd_uint1
    let ColorToCount: simd_float4
}

/// Types of actions the ImageScan kernel can take.
///
/// - NOP: No operation. Nothing happens.
/// - CumulativeRGBChannelValues: Accumulate the total number and value of red, green, blue, and alpha channels.
/// - CumulativeHSBChannelValues: Accumulate the total number and value of hue, saturation, brightness, and alpha channels.
/// - CumulativeCMYKChannelValues: Accumulate the total number and value of cyan, magenta, yellow, black, and alpha channels.
/// - BrightestPixels: Find the locations of the brightest pixels near the center of each border
/// - DarkestPixels: Find the location of the darkest pixels near the center of each border.
enum ImageScanActions: Int
{
    case NOP = 0
    case CumulativeRGBChannelValues = 1
    case CumulativeHSBChannelValues = 2
    case CumulativeCMYKChannelValues = 3
    case BrightestPixels = 4
    case DarkestPixels = 5
    case CountColor = 6
}
