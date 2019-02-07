//
//  SolarizeParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct SolarizeParameters
{
    let SolarizeHow: simd_uint1
    let Threshold: simd_float1
    let LowHue: simd_float1
    let HighHue: simd_float1
    let BrightnessThreshold: simd_float1
    let SaturationThreshold: simd_float1
    let SolarizeIfGreater: simd_bool
}
