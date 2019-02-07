//
//  ThresholdParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct ThresholdParameters
{
    let ThresholdValue: simd_float1
    let ThresholdInput: simd_uint1
    let ApplyIfHigher: simd_bool
    let LowColor: simd_float4
    let HighColor: simd_float4
}
