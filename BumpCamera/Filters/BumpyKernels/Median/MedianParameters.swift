//
//  MedianParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct MedianParameters
{
    let Width: simd_int1
    let Height: simd_int1
    let KernelCenterX: simd_int1
    let KernelCenterY: simd_int1
    let MedianOn: simd_int1
}
