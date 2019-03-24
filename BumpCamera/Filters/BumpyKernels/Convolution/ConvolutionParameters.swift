//
//  ConvolutionParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct ConvolveParameters
{
    let Width: simd_int1
    let Height: simd_int1
    let KernelCenterX: simd_int1
    let KernelCenterY: simd_int1
    let Factor: simd_float1
    let Bias: simd_float1
}
