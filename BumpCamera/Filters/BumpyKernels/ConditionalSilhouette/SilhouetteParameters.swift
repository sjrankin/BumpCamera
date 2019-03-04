//
//  SilhouetteParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct SilhouetteParameters
{
    //0 = hue, 1 = saturation, 2 = brightness
    let Trigger: simd_uint1
    let HueThreshold: simd_float1
    let HueRange: simd_float1
    let SaturationThreshold: simd_float1
    let SaturationRange: simd_float1
    let BrightnessThreshold: simd_float1
    let BrightnessRange: simd_float1
    let GreaterThan: simd_bool
    let SilhouetteColor: simd_float4
}
