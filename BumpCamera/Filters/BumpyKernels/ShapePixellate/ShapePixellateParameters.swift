//
//  ShapePixellateParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct ShapePixellateParameters
{
    let Size: simd_int1
    // 0 = square, 1 = circle
    let Shape: simd_int1
    // 0 = mean of block, 1 = hue of block, 2 = grayscale mean of block, 3 = specified color
    let BlockColorFrom: simd_int1
    let BlockColor: simd_float4
    let DrawOutline: simd_bool
    // 0 = max sat & bri from mean of block, 1 = grayscale mean of block, 2 = specified color
    let OutlineColorFrom: simd_int1
    let OutlineColor: simd_float4
    let OutlineThickness: simd_int1
}
