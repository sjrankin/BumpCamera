//
//  CheckerboardParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct CheckerboardParameters
{
    let Q1Color: simd_float4
    let Q2Color: simd_float4
    let Q3Color: simd_float4
    let Q4Color: simd_float4
    let BlockSize: simd_float1
}
