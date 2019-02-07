//
//  GridParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct GridParameters
{
    let GridX: simd_uint1
    let GridY: simd_uint1
    let Width: simd_uint1
    let GridColor: simd_float4
    let BackgroundColor: simd_float4
    let InvertGridColor: simd_bool
    let InvertBackgroundColor: simd_bool
}
