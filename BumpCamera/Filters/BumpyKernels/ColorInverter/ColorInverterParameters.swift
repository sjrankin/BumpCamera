//
//  ColorInverterParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct ColorInverterParameters
{
    //0 = rgb, 1 = hsb, 2 = xyz, 3 = yuv, 4 = cmyk
    let Colorspace: simd_uint1
    let InvertChannel1: simd_bool
    let InvertChannel2: simd_bool
    let InvertChannel3: simd_bool
    let InvertChannel4: simd_bool
    let EnableChannel1Threshold: simd_bool
    let EnableChannel2Threshold: simd_bool
    let EnableChannel3Threshold: simd_bool
    let EnableChannel4Threshold: simd_bool
    let Channel1Threshold: simd_float1
    let Channel2Threshold: simd_float1
    let Channel3Threshold: simd_float1
    let Channel4Threshold: simd_float1
    let Channel1InvertIfGreater: simd_bool
    let Channel2InvertIfGreater: simd_bool
    let Channel3InvertIfGreater: simd_bool
    let Channel4InvertIfGreater: simd_bool
    let InvertAlpha: simd_bool
    let EnableAlphaThreshold: simd_bool
    let AlphaThreshold: simd_float1
    let AlphaInvertIfGreater: simd_bool
}
