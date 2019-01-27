//
//  ChannelSwizzleParameters.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import simd

struct ChannelSwizzles
{
    //Values: 0 = r, 1 = g, 2 = b, 3 = h, 4 = s, 5 = L
    let Channel1: simd_float1
    let Channel2: simd_float1
    let Channel3: simd_float1
}
