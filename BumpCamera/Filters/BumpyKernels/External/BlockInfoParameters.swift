//
//  BlockInfoParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/29/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct BlockInfoParameters
{
    let Width: simd_uint1
    let Height: simd_uint1
    let HighlightAction: simd_uint1
    let HighlightPixelBy: simd_uint1
    let BrightnessHighlight: simd_uint1
    let HighlightColor: simd_float4
    let ColorDetermination: simd_uint1
    let HighlightValue: simd_float1
    let HighlightIfGreater: simd_bool
}
