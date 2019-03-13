//
//  MaskingKernelParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct MaskingKernelParameters
{
    let MaskColor: simd_float4
    let Tolerance: simd_int1
}
