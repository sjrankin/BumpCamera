//
//  FilterNode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Information about a filter. Lives in a filter group node.
class FilterNode
{
    /// The title of the filter.
    public var Title: String = ""
    /// The node ID (sequentially assigned).
    public var NodeID: Int = 0
    /// The filter ID.
    public var ID: UUID!
    /// The filter type.
    public var FilterType: FilterManager.FilterTypes = FilterManager.FilterTypes.NotSet
    /// Not currently used.
    public var Prefix: String = ""
    /// Filter is implemented flag.
    public var IsImplemented: Bool = false
    /// Sort order. Not currently used.
    public var SortOrder: Int = -1
    /// Parent node delegate.
    public var delegate: GroupNode? = nil
    /// Node selection flag
    public var IsSelected: Bool = false
    /// Get the color of the node. (Retrieved from the parent node.)
    public var Color: UIColor
    {
        get
        {
            return (delegate?.Color)!
        }
    }
}
