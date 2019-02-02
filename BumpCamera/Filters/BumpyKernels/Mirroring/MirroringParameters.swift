//
//  MirroringParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct MirrorParameters
{
    //0 = horizontal (left to right), 1 = vertical (top to bottom)
    let Direction: simd_uint1
    //0 = left, 1 = right
    let HorizontalSide: simd_uint1
    //0 = top, 1 = bottom
    let VerticalSide: simd_uint1
    //location of the center horizontal axis
    let HorizontalAxis: simd_uint1
    //location of the center vertical axis
    let VerticalAxis: simd_uint1
}
