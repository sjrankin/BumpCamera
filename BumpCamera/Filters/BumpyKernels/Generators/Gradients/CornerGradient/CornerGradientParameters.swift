//
//  CornerGradientParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct CornerGradientParameters
{
    let HasUL: simd_bool
    let HasUR: simd_bool
    let HasLL: simd_bool
    let HasLR: simd_bool
    let UL: simd_uint2
    let UR: simd_uint2
    let LL: simd_uint2
    let LR: simd_uint2
    let ULColor: simd_float4
    let URColor: simd_float4
    let LLColor: simd_float4
    let LRColor: simd_float4
    let IncludeAlpha: simd_bool
}
