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
    //0 = horizontal (left to right), 1 = vertical (top to bottom), 2 = quadrant
    let Direction: simd_uint1
    //0 = left, 1 = right
    let HorizontalSide: simd_uint1
    //0 = top, 1 = bottom
    let VerticalSide: simd_uint1
    //quadrant to reflect
    let Quadrant: simd_uint1
    //set to true if image source is AV foundation
    let IsAVRotated: simd_bool
}
