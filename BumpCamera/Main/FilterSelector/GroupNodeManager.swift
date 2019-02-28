//
//  GroupNodeManager.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Creates and manages a hierarchy of filter groups and filters within the groups.
class GroupNodeManager
{
    /// Initialize the group node manager.
    ///
    /// - Parameters:
    ///   - InitialGroup: The initially-selected filter group.
    ///   - InitialFilter: The initially-selected filter.
    ///   - ForTargets: The list of filter targets each filter must support.
    init(InitialGroup: FilterManager.FilterGroups, InitialFilter: FilterManager.FilterTypes,
         ForTargets: [FilterTargets] = [.LiveView, .Video, .Still])
    {
        Groups = [GroupNode]()
        LoadGroups(InitialGroup, InitialFilter, ForTargets)
    }
    
    /// Create the list of groups and populate them with their respective filters.
    ///
    /// - Parameters:
    ///   - InitialGroup: The initially-selected filter group.
    ///   - InitialFilter: The initially-selected filter.
    ///   - Targets: List of filter targets each filter must support.
    func LoadGroups(_ InitialGroup: FilterManager.FilterGroups, _ InitialFilter: FilterManager.FilterTypes,
                    _ Targets: [FilterTargets] = [.LiveView, .Video, .Still])
    {
        let GroupData = FilterManager.GetGroupNames()
        var Index = 0
        for (GroupName, GroupType, SortOrder) in GroupData
        {
            let Node = GroupNode()
            Node.Title = GroupName
            Node.GroupType = GroupType
            Node.SortOrder = SortOrder
            Node.NodeID = Index
            Node.ID = FilterManager.GetGroupID(ForGroup: GroupType)!
            Node.IsSelected = GroupType == InitialGroup
            Node.Color = FilterManager.ColorForGroup(GroupType)
            Node.GroupFilters = LoadFilters(Parent: Node, FromGroup: GroupType, InitialFilter: InitialFilter, Targets)
            if Node.GroupFilters.count == 0
            {
                continue
            }
            Node.GroupFilters!.sort{$0.SortOrder < $1.SortOrder}
            Groups?.append(Node)
            Index = Index + 1
        }
        
        Groups!.sort{$0.SortOrder < $1.SortOrder}
        LoadFavoriteFilters(ForTargets: Targets)
        LoadFiveStarFilters(ForTargets: Targets)
    }
    
    /// Remove the five-star group.
    func RemoveFiveStarGroup()
    {
        var GroupIndex = -1
        for Index in 0 ..< (Groups?.count)!
        {
            if (Groups?[Index].IsFiveStarList)!
            {
                GroupIndex = Index
                break
            }
        }
        if GroupIndex < 0
        {
            return
        }
        Groups?.remove(at: GroupIndex)
    }
    
    /// Remove the favorite filters group.
    func RemoveFavoriteGroup()
    {
        var GroupIndex = -1
        for Index in 0 ..< (Groups?.count)!
        {
            if (Groups?[Index].IsFavoriteList)!
            {
                GroupIndex = Index
                break
            }
        }
        if GroupIndex < 0
        {
            return
        }
        Groups?.remove(at: GroupIndex)
    }
    
    /// Load the five-star filter group for filters that fall into the specified filter targets.
    ///
    /// - Parameter ForTargets: Valid filter targets.
    func LoadFiveStarFilters(ForTargets: [FilterTargets])
    {
        RemoveFiveStarGroup()
        let FiveStarred = FilterManager.GetFiltersWith(StarCount: 5)
        if FiveStarred.count == 0
        {
            return
        }
        let Node = GroupNode()
        Node.Title = "Five Stars"
        Node.GroupType = FilterManager.FilterGroups.FiveStar
        Node.SortOrder = 0
        Node.NodeID = -100
        Node.ID = FilterManager.GetGroupID(ForGroup: Node.GroupType)
        Node.IsSelected = false
        Node.IsFiveStarList = true
        Node.Color = FilterManager.ColorForGroup(Node.GroupType)
        var InsertIndex = 0
        if (Groups?.first?.IsFavoriteList)!
        {
            InsertIndex = 1
        }
        let FiveStarFilters = AddFiltersTo(Parent: Node, List: FiveStarred, ForTargets: ForTargets)
        if FiveStarFilters.count < 1
        {
            Node.GroupFilters = [FilterNode]()
            return
        }
        Node.GroupFilters = FiveStarFilters
        
        Groups?.insert(Node, at: InsertIndex)
    }
    
    /// Load the favorite filter group for filters that fall into the specified filter targets.
    ///
    /// - Parameter ForTargets: Valid filter targets.
    func LoadFavoriteFilters(ForTargets: [FilterTargets])
    {
        RemoveFavoriteGroup()
        let Favorite = FilterManager.GetFiltersWithFave(Value: true)
        if Favorite.count == 0
        {
            return
        }
        let Node = GroupNode()
        Node.Title = "Favorite"
        Node.GroupType = FilterManager.FilterGroups.Favorites
        Node.SortOrder = 0
        Node.NodeID = -101
        Node.ID = FilterManager.GetGroupID(ForGroup: Node.GroupType)
        Node.IsSelected = false
        Node.IsFavoriteList = true
        Node.Color = FilterManager.ColorForGroup(Node.GroupType)
        let FavoriteFilters = AddFiltersTo(Parent: Node, List: Favorite, ForTargets: ForTargets)
        if FavoriteFilters.count < 1
        {
            Node.GroupFilters = [FilterNode]()
            return
        }
        Node.GroupFilters = FavoriteFilters
        
        Groups?.insert(Node, at: 0)
    }
    
    /// Add filters to the specified group node that acts as the parent.
    ///
    /// - Parameters:
    ///   - Parent: The parent of the filters that will be added to it.
    ///   - List: List of filter types to add to the parent group.
    ///   - ForTargets: Valid targets the filters must be in in order for them to be added.
    /// - Returns: List of filter nodes.
    func AddFiltersTo(Parent: GroupNode, List: [(FilterManager.FilterTypes, Ratings)], ForTargets: [FilterTargets]) -> [FilterNode]
    {
        var FilterData = [FilterNode]()
        var Index = 0
        for (FilterType, _) in List
        {
            if !FilterManager.FilterSupportsTargets(Targets: ForTargets, ForFilter: FilterType)
            {
                //Filters not in the list of valid filter targets are not added. This is so filters that cannot
                //process live views are not used in live view mode, and the like.
                continue
            }
            if !FilterManager.IsImplemented(FilterType)
            {
                //Unimplemented filters are not added.
                continue
            }
            let Node = FilterNode()
            Node.NodeID = Index
            Node.FilterType = FilterType
            Node.ID = FilterManager.GetFilterID(For: FilterType)
            Node.Title = FilterManager.GetFilterTitle(FilterType)!
            Node.IsImplemented = FilterManager.IsImplemented(FilterType)
            Node.IsSelected = false
            Node.SortOrder = Index
            Node.delegate = Parent
            Index = Index + 1
            FilterData.append(Node)
        }
        
        return FilterData
    }
    
    /// Load the list of filters for the specified parent group.
    ///
    /// - Parameters:
    ///   - Parent: The parent group node. Used for setting the filter delegate.
    ///   - FromGroup: The type of group whose filters will be loaded.
    ///   - InitialFilter: The initially-selected filter.
    ///   - LoadOnlyImplmemented: If true, only implemented filters will be loaded.
    ///   - Targets: List of filter targets the filter must support before it is included.
    /// - Returns: List of filter nodes for the specified group. If no filters were available for
    ///            the specified group, the list will be empty.
    func LoadFilters(Parent: GroupNode, FromGroup: FilterManager.FilterGroups, InitialFilter: FilterManager.FilterTypes,
                     LoadOnlyImplmemented: Bool = true, _ Targets: [FilterTargets] = [.LiveView, .Video, .Still]) -> [FilterNode]
    {
        var FilterData = [FilterNode]()
        let FilterList = FilterManager.FiltersForGroup(FromGroup, InOrder: true)
        var Index = 0
        for FilterType in FilterList
        {
            if !FilterManager.FilterSupportsTargets(Targets: Targets, ForFilter: FilterType)
            {
                continue
            }
            if LoadOnlyImplmemented && !FilterManager.IsImplemented(FilterType)
            {
                continue
            }
            let Node = FilterNode()
            Node.NodeID = Index
            Node.FilterType = FilterType
            Node.ID = FilterManager.GetFilterID(For: FilterType)
            Node.Title = FilterManager.GetFilterTitle(FilterType)!
            Node.IsImplemented = FilterManager.IsImplemented(FilterType)
            Node.IsSelected = InitialFilter == FilterType
            Node.SortOrder = Index
            Node.delegate = Parent
            Index = Index + 1
            FilterData.append(Node)
        }
        return FilterData
    }
    
    /// List of groups.
    var Groups: [GroupNode]? = nil
    
    /// Return the number of groups being managed.
    var GroupCount: Int
    {
        get
        {
            return Groups!.count
        }
    }
    
    /// Return the ordinal value of the specified group.
    ///
    /// - Parameter TheGroup: The group whose ordinal group will be returned.
    /// - Returns: The ordinal value of the specified group on success, nil if not found.
    func OrdinalOfGroup(_ TheGroup: FilterManager.FilterGroups) -> Int?
    {
        var Index = 0
        for SomeGroup in Groups!
        {
            if SomeGroup.GroupType == TheGroup
            {
                return Index
            }
            Index = Index + 1
        }
        return nil
    }
    
    /// Returns the number of filters in the specified group ordinal.
    ///
    /// - Parameter GroupOrdinal: Ordinal of the group.
    /// - Returns: Number of filters in the specified group.
    func FiltersInGroup(_ GroupOrdinal: Int) -> Int
    {
        if !ValidGroupOrdinal(GroupOrdinal)
        {
            return 0
        }
        return Groups![GroupOrdinal].GroupFilters.count
    }
    
    /// Return a group node at the specified ordinal index.
    ///
    /// - Parameter GroupOrdinal: The value that serves as the index of the group node list.
    /// - Returns: The group at the specified ordinal on success, nil if invalid ordinal index.
    func GroupNodeByOrdinal(_ GroupOrdinal: Int) -> GroupNode?
    {
        if !ValidGroupOrdinal(GroupOrdinal)
        {
            return nil
        }
        return Groups![GroupOrdinal]
    }
    
    /// Return the filter in the specified group/filter ordinal.
    ///
    /// - Parameters:
    ///   - GroupOrdinal: Ordinal of the group where the filter is found.
    ///   - FilterOrdinal: Ordinal of the filter in the group.
    /// - Returns: The filter node on success, nil if not found (one of the ordinals out of range).
    func GetFilterNode(_ GroupOrdinal: Int, _ FilterOrdinal: Int) -> FilterNode?
    {
        if !ValidGroupOrdinal(GroupOrdinal)
        {
            return nil
        }
        return Groups![GroupOrdinal].FilterByOrdinal(FilterOrdinal)
    }
    
    /// Determines if the ordinal value is a valid index into the list of groups (eg, in range).
    ///
    /// - Parameter Value: The value to check against the current range of groups.
    /// - Returns: True if the value is in the range of groups, false if not.
    public func ValidGroupOrdinal(_ Value: Int) -> Bool
    {
        if Value < 0
        {
            return false
        }
        if Value > Groups!.count - 1
        {
            return false
        }
        return true
    }
    
    /// Determines if the group/filter ordinal combination is valid.
    ///
    /// - Parameters:
    ///   - GroupOrdinal: The group ordinal value to validate.
    ///   - FilterOrdinal: The filter ordinal value to validate.
    /// - Returns: True if the combination is valid, false if not.
    public func ValidGroupFilterOrdinals(GroupOrdinal: Int, FilterOrdinal: Int) -> Bool
    {
        if !ValidGroupOrdinal(GroupOrdinal)
        {
            return false
        }
        return Groups![GroupOrdinal].ValidFilterOrdinal(FilterOrdinal)
    }
    
    /// Select the filter at the specified group and filter ordinals. If either ordinal is invalid, no action occurs.
    ///
    /// - Parameters:
    ///   - GroupIndex: The index of the group where the filter list to select.
    ///   - FilterIndex: The index of the filter to select.
    func SelectFilterAt(GroupIndex: Int, FilterIndex: Int)
    {
        if !ValidGroupOrdinal(GroupIndex)
        {
            return
        }
        DeselectEverything()
        if Groups![GroupIndex].ValidFilterOrdinal(FilterIndex)
        {
            Groups![GroupIndex].GroupFilters[FilterIndex].IsSelected = true
        }
    }
    
    /// Deselect all filters in all groups.
    func DeselectFilters()
    {
        for Group in Groups!
        {
            Group.GroupFilters.forEach{$0.IsSelected = false}
        }
    }
    
    /// Deselect all groups.
    func DeselectGroups()
    {
        Groups!.forEach{$0.IsSelected = false}
    }
    
    /// Deselect all filters and groups.
    func DeselectEverything()
    {
        for Group in Groups!
        {
            Group.IsSelected = false
            Group.GroupFilters.forEach{$0.IsSelected = false}
        }
    }
    
    /// Select the specified filter. The filter's group is _not_ selected in this function.
    ///
    /// - Parameter Filter: The filter to select.
    func SelectFilter(_ Filter: FilterManager.FilterTypes)
    {
        if let Group = GetGroupNode(For: Filter)
        {
            DeselectFilters()
            Group.SelectFilter(Filter)
        }
    }
    
    /// Select the specified filter. The filter's group is _not_ selected in this function.
    ///
    /// - Parameter Filter: The ID of the filter to select.
    func SelectFilter(_ ID: UUID)
    {
        let FilterType = FilterManager.GetFilterTypeFrom(ID: ID)
        SelectFilter(FilterType!)
    }
    
    /// Select the specified group. No filters in any group are deselected.
    ///
    /// - Parameter TheGroup: The group to select.
    func SelectGroup(_ TheGroup: FilterManager.FilterGroups)
    {
        DeselectGroups()
        for Group in Groups!
        {
            if Group.GroupType == TheGroup
            {
                Group.IsSelected = true
                return
            }
        }
    }
    
    /// Select the specified group. No filters in any group are deselected.
    ///
    /// - Parameter TheGroup: The ID of the group to select.
    func SelectGroup(_ ID: UUID)
    {
        let GroupType = FilterManager.GetGroupFrom(ID: ID)
        return SelectGroup(GroupType!)
    }
    
    /// Select the group at the specified ordinal.
    ///
    /// - Parameter Ordinal: The ordinal position of the group to select. If out of range, no action occurs.
    func SelectGroup(_ Ordinal: Int)
    {
        if !ValidGroupOrdinal(Ordinal)
        {
            return
        }
        Groups!.forEach{$0.IsSelected = false}
        Groups![Ordinal].IsSelected = true
    }
    
    /// Select the specified group and filter (the filter does not necessarily have to reside within
    /// the specified group).
    ///
    /// - Parameters:
    ///   - Group: The group to select.
    ///   - WithFilter: The filter to select.
    func Select(Group: FilterManager.FilterGroups, WithFilter: FilterManager.FilterTypes)
    {
        SelectGroup(Group)
        SelectFilter(WithFilter)
    }
    
    /// Returns the group node where the specified filter lives.
    ///
    /// - Parameter For: The filter that determines which group is returned.
    /// - Returns: The group where the specified filter lives, nil if not found.
    func GetGroupNode(For: FilterManager.FilterTypes) -> GroupNode?
    {
        for Group in Groups!
        {
            if Group.ContainsFilter(For)
            {
                return Group
            }
        }
        return nil
    }
    
    /// Returns the currently selected group.
    ///
    /// - Returns: The currently selected group. Nil if no groups are selected.
    func CurrentGroup() -> FilterManager.FilterGroups?
    {
        for Group in Groups!
        {
            if Group.IsSelected
            {
                return Group.GroupType
            }
        }
        return nil
    }
    
    /// Returns the currently selected filter.
    ///
    /// - Returns: The currently selected filter. Nil if no filters are selected.
    func CurrentFilter() -> FilterManager.FilterTypes?
    {
        for Group in Groups!
        {
            if let FilterType = Group.SelectedFilter()
            {
                return FilterType
            }
        }
        return nil
    }
    
    /// Returns the currently selected group and filter. The filter may not necessarily be in the
    /// returned selected group.
    ///
    /// - Returns: Tuple in the order (selected group, selected filter). Either value may be nil if
    ///            not selected.
    func CurrentSelection() -> (FilterManager.FilterGroups?, FilterManager.FilterTypes?)
    {
        return (CurrentGroup(), CurrentFilter())
    }
}

