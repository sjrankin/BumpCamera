//
//  DescendentDelta.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Protocol used to let descendent filter settings UI classes let their parents know they changed
/// something that the parent should be aware of.
protocol DescendentDelta
{
    /// Called when a descendent changes a value in an input field.
    ///
    /// - Parameters:
    ///   - DescendentName: Name of the descendent. Used for debugging.
    ///   - Field: The field that it changed. The descendent is required to write out the value
    ///            to the ParameterManager before calling this function.
    func UpdatedFrom(_ DescendentName: String, Field: FilterManager.InputFields)
}
