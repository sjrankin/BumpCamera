//
//  GrayscaleKernelParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct GrayscaleParameters
{
    let Command: simd_int1
    let RMultiplier: simd_float1
    let GMultiplier: simd_float1
    let BMultiplier: simd_float1
}
