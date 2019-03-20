//
//  HistogramDataProtocol.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import MetalPerformanceShaders

protocol HistogramDataProtocol
{
    func SetHistogramData(HistogramData: [vector_float4])
}
