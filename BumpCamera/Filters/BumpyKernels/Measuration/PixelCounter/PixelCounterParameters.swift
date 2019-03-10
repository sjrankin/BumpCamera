//
//  PixelCounterParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct PixelCounterParameters
{
    //0 = count, 1 = return mean, 2 = count pixels in ranges
    let Action: simd_uint1
    let PixelSearchCount: simd_uint1
    //0 = unconditionally count, 1 count if hue +/- offset
    let CountIf: simd_uint1
    let HueOffset: simd_float1
    let ReturnBufferSize: simd_uint1
    let RangeSize: simd_float1
}
