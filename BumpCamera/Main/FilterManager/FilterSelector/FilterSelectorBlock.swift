//
//  FilterSelectionBlock.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/17/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Contains information for filter groups when used with controls used
/// to select groups and filters.
class FilterSelectorBlock
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
    public var GroupType: FilterManager.FilterGroups = FilterManager.FilterGroups.NotSet
    
    /// Filter type - used for when this class is applied for selecting filters.
    public var FilterType: FilterManager.FilterTypes = FilterManager.FilterTypes.NotSet
    
    /// Prefix string - used for debugging.
    public var Prefix: String = ""
    
    /// Implemented flag.
    public var IsImplemented: Bool = false
    
    /// Sort order.
    public var SortOrder: Int = -1
    
    /// ID of the filter.
    public var FilterID: UUID? = nil
}
