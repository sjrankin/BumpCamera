//
//  GroupNode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Maintains information about a filter group and its list of associated filters. Used mainly by the filter selection UI.
class GroupNode
{
    /// Group title.
    public var Title: String = ""
    /// Sequentially assigned node ID.
    public var NodeID: Int = 0
    /// Group ID.
    public var ID: UUID!
    /// Group selected flag.
    public var IsSelected: Bool = false
    /// Node color.
    public var Color: UIColor = UIColor.red
    /// Group type.
    public var GroupType: FilterManager.FilterGroups = .NotSet
    /// Sort order. Not currently used.
    public var SortOrder: Int = -1
    /// Group prefix - not currently used.
    public var Prefix: String = ""
    /// List of filters in the group.
    public var GroupFilters: [FilterNode]!
    /// If true, the group node is for favorites.
    public var IsFavoriteList: Bool = false
    /// If true, the group node is for five-starred filters.
    public var IsFiveStarList: Bool = false
    
    /// Determines if the ordinal value is a valid index into the list of filters (eg, in range).
    ///
    /// - Parameter Value: The value to check against the current range of filters.
    /// - Returns: True if the value is in the range of filters, false if not.
    public func ValidFilterOrdinal(_ Value: Int) -> Bool
    {
        if Value < 0
        {
            return false
        }
        if Value > GroupFilters!.count - 1
        {
            return false
        }
        return true
    }
    
    /// Return the specified filter by ordinal.
    ///
    /// - Parameter Ordinal: The ordinal to use to determine the filter to return.
    /// - Returns: The filter at the ordinalth position on success, nil if bad Ordinal.
    public func FilterByOrdinal(_ Ordinal: Int) -> FilterNode?
    {
        if Ordinal < 0 || Ordinal > GroupFilters.count - 1
        {
            return nil
        }
        return GroupFilters[Ordinal]
    }
    
    /// Determines if the group contains the specified filter.
    ///
    /// - Parameter Filter: The filter to look for in the filter list.
    /// - Returns: True if the group contains the specified filter, false if not.
    public func ContainsFilter(_ Filter: FilterManager.FilterTypes) -> Bool
    {
        for SomeFilter in GroupFilters
        {
            if SomeFilter.FilterType == Filter
            {
                return true
            }
        }
        return false
    }
    
    /// Returns the selected filter type.
    ///
    /// - Returns: The selected filter type. Nil if no filters are selected.
    public func SelectedFilter() -> FilterManager.FilterTypes?
    {
        for SomeFilter in GroupFilters
        {
            if SomeFilter.IsSelected
            {
                return SomeFilter.FilterType
            }
        }
        return nil
    }
    
    /// Select the specified filter.
    ///
    /// - Parameter Filter: The filter type to select.
    /// - Returns: True on success, false on failure (because the filter type wasn't found in the filter list).
    @discardableResult public func SelectFilter(_ Filter: FilterManager.FilterTypes) -> Bool
    {
        for SomeFilter in GroupFilters
        {
            if SomeFilter.FilterType == Filter
            {
                SomeFilter.IsSelected = true
                return true
            }
        }
        return false
    }
}
