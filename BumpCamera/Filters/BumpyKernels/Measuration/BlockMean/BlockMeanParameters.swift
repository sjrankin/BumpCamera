//
//  BlockMeanParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct BlockMeanParameters
{
    let Width: simd_int1
    let Height: simd_int1
    let CalculateMean: simd_bool
}

struct ReturnBlockData
{
    let X: simd_int1
    let Y: simd_int1
    let Red: simd_float1
    let Green: simd_float1
    let Blue: simd_float1
    let Alpha: simd_float1
    let Count: simd_int1
}
