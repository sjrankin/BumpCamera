//
//  CollapsibleTableViewHeaderDelegate.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/1/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

protocol CollapsibleTableViewHeaderDelegate
{
    func ToggleSection(Header: CollapsibleHeader, Section: Int)
}
