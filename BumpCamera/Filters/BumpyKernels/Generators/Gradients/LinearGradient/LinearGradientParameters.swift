//
//  LinearGradientParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct GradientColorStop
{
    let Color: simd_float4
    let Location: simd_float1
}

struct LinearGradientParameters
{
    let GradientStopCount: simd_uint1
    let Background: simd_float4
    let IsHorizontal: simd_bool
    let ImplicitOffset1: simd_float1
    let ImplicitOffset2: simd_float1
}
