//
//  GroupDataBlock.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/17/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Contains information for filter groups when used with controls used
/// to select groups and filters.
class GroupDataBlock
{
    /// The title of the filter group.
    public var Title: String = ""
    
    /// The ID of the filter group - used for debugging purposes.
    public var ID: Int = 0
    
    /// Filter group selected flag.
    public var IsSelected: Bool = false
    
    /// Filter group color.
    public var Color: UIColor = UIColor.red
    
    /// Filter group type.
    public var GroupType: FilterGroups = FilterGroups.NotSet
    
    /// Filter type - used for when this class is applied for selecting filters.
    public var FilterType: FilterNames = FilterNames.NotSet
    
    /// Prefix string - used for debugging.
    public var Prefix: String = ""
}
