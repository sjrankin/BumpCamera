//
//  DEParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/14/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct DEParameters
{
    //Half of a window size. Must be odd.
    let WindowSize: simd_uint1
    //0 = red, 1 = green, 2 = blue, 3 = hue, 4 = saturation, 5 = brightness, 6 = cyan, 7 = magenta, 8 = yellow, 9 = black
    let ValueDetermination: simd_uint1
    //Operation to perform: 0 = erode, 1 = dilate
    let Operation: simd_uint1
}
