//
//  GradientPickerProtocol.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

protocol GradientPickerProtocol: class
{
    func EditedGradient(_ Edited: String?, Tag: Any?)
    
    func GradientToEdit(_ EditMe: String?, Tag: Any?)
    
    func SetStop(StopColor: UIColor?, StopLocation: Double?)
}
