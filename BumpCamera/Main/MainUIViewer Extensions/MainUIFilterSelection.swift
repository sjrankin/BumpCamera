//
//  MainUIFilterSelectionExtension.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// This extension adds code to allow the user to select filter groups and filters via the main UI. The only reason
/// why this is in an extension is to reduce the size of the file where the main implementation of the UI lives. Due
/// to some Swift limitation, all stored properties are in the main file.
extension MainUIViewer
{
    // MARK: Filter collection view code.
    
    /// Update the visibility of the filter selection UI. This is essentially a toggle function.
    ///
    /// - Parameters:
    ///   - ShowDuration: Animation duration for showing the UI.
    ///   - HideDuration: Animation duration for hiding the UI.
    func UpdateFilterSelectionVisibility(ShowDuration: Double = 0.25, HideDuration: Double = 0.4)
    {
        if FiltersAreShowing
        {
            UIView.animate(withDuration: HideDuration)
            {
                self.FilterCollectionView.frame = self.HiddenFilter
                self.GroupCollectionView.frame = self.GroupHidden
            }
            FiltersAreShowing = false
        }
        else
        {
            FilterCollectionView.isHidden = false
            GroupCollectionView.isHidden = false
            UIView.animate(withDuration: ShowDuration)
            {
                self.FilterCollectionView.frame = self.FilterRect
                self.GroupCollectionView.frame = self.GroupRect
            }
            FiltersAreShowing = true
            FilterCollectionView.reloadData()
            GroupCollectionView.reloadData()
            StartHidingTimer()
        }
    }
    
    /// Initialize the filter selector mechanism/UI.
    func InitializeFilterSelector()
    {
        MainBottomToolbar.layer.zPosition = 1000
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        LastSelectedItem = 0
        FilterCollectionView.register(FilterCollectionCell.self, forCellWithReuseIdentifier: "FilterItem")
        FilterCollectionView.allowsSelection = true
        FilterCollectionView.allowsMultipleSelection = false
        FilterCollectionView.layer.zPosition = 501
        FilterRect = FilterCollectionView.frame
        HiddenFilter = CGRect(x: FilterCollectionView.frame.minX, y: view.frame.height,
                              width: FilterCollectionView.frame.width, height: FilterCollectionView.frame.height)
        UIView.animate(withDuration: 0.1) {
            self.FilterCollectionView.frame = self.HiddenFilter
        }
        FilterCollectionView.isHidden = true
        FilterCollectionView.delegate = self
        FilterCollectionView.dataSource = self
        FilterCollectionView.layer.borderWidth = 0.5
        FilterCollectionView.layer.borderColor = UIColor.white.cgColor
        FilterCollectionView.layer.cornerRadius = 5.0
        FilterCollectionView.clipsToBounds = true
        FilterCollectionView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.35)
        
        LastSelectedGroup = 0
        GroupCollectionView.register(FilterCollectionCell.self, forCellWithReuseIdentifier: "GroupCell")
        GroupCollectionView.allowsSelection = true
        GroupCollectionView.allowsMultipleSelection = false
        GroupCollectionView.layer.zPosition = 500
        GroupRect = GroupCollectionView.frame
        GroupHidden = CGRect(x: GroupCollectionView.frame.minX, y: view.frame.height,
                             width: GroupCollectionView.frame.width, height: GroupCollectionView.frame.height)
        UIView.animate(withDuration: 0.1) {
            self.GroupCollectionView.frame = self.GroupHidden
        }
        GroupCollectionView.isHidden = true
        GroupCollectionView.delegate = self
        GroupCollectionView.dataSource = self
        GroupCollectionView.layer.borderWidth = 0.5
        GroupCollectionView.layer.borderColor = UIColor.white.cgColor
        GroupCollectionView.layer.cornerRadius = 5.0
        GroupCollectionView.clipsToBounds = true
        GroupCollectionView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.35)
        
        let InitialFilterIDS = _Settings.string(forKey: "CurrentFilter")
        let InitialFilterID = UUID(uuidString: InitialFilterIDS!)
        print("Initial filter: \(Filters!.GetFilterTitle(InitialFilterID!))")
        
        GroupTitles = Filters!.GetGroupNames()
        GroupTitles!.sort{$0.2 < $1.2}
        MakeGroupData(GroupTitles!)
        CurrentGroupFilters = (Filters?.FiltersForGroup(GroupNodes[0].GroupType))!
        GroupNodes[0].IsSelected = true
        let FilterDataForGroup = Filters?.GetFilterData(ForGroup: (GroupTitles?.first!.1)!)
        MakeFilterData(FilterDataForGroup!, (GroupTitles?.first!.1)!)
    }
    
    /// Make a list of groups for filters.
    ///
    /// - Parameter FilterGroupList: List of filter groups.
    func MakeGroupData(_ FilterGroupList: [(String, FilterManager.FilterGroups, Int)])
    {
        GroupNodes = [FilterSelectorBlock]()
        GroupCount = FilterGroupList.count
        let AScalar = "A".unicodeScalars.last!
        let CharIndex = AScalar.value
        for Index in 0 ..< GroupCount
        {
            let Group = FilterSelectorBlock()
            let TheGroup = FilterGroupList[Index].1
            Group.Color = (Filters?.ColorForGroup(TheGroup))!
            Group.GroupType = TheGroup
            let NewScalar = CharIndex + UInt32(Index)
            Group.Title = FilterGroupList[Index].0
            Group.Prefix = String(Character(UnicodeScalar(NewScalar)!))
            Group.ID = Index
            Group.IsSelected = false
            GroupNodes.append(Group)
        }
    }
    
    /// Make a list of filter nodes.
    ///
    /// - Parameters:
    ///   - FilterDataList: Filter node data for a given filter group.
    ///   - ForGroup: The group to which the filters belongs.
    func MakeFilterData(_ FilterDataList: [(String, FilterManager.FilterTypes, Int, Bool)], _ ForGroup: FilterManager.FilterGroups)
    {
        FilterNodes = [FilterSelectorBlock]()
        FilterCount = FilterDataList.count
        let AScalar = "A".unicodeScalars.last!
        let CharIndex = AScalar.value
        for Index in 0 ..< FilterCount
        {
            let FilterNode = FilterSelectorBlock()
            let TheFilter = FilterDataList[Index].1
            FilterNode.Color = (Filters?.ColorForGroup(ForGroup))!
            FilterNode.FilterType = TheFilter
            let NewScalar = CharIndex + UInt32(Index)
            FilterNode.Title = FilterDataList[Index].0
            FilterNode.Prefix = String(Character(UnicodeScalar(NewScalar)!))
            FilterNode.ID = Index
            FilterNode.FilterID = Filters!.GetFilterID(For: FilterDataList[Index].1)
            FilterNode.IsSelected = false
            FilterNode.SortOrder = FilterDataList[Index].2
            FilterNodes.append(FilterNode)
        }
        FilterNodes.sort{$0.SortOrder < $1.SortOrder}
    }

    /// Returns the number of items for the UICollectionView. The quanity varies depending on which group
    /// is selected. This function handles both group counts and filter counts.
    ///
    /// - Parameters:
    ///   - collectionView: The collection that wants the number of items.
    ///   - section: Not used.
    /// - Returns: Number of items for the specified collection.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if collectionView == FilterCollectionView
        {
            if LastSelectedGroup < 0
            {
                return 0
            }
            let FilterCount: Int = (Filters?.FiltersForGroup(GroupNodes[LastSelectedGroup].GroupType).count)!
            return FilterCount
        }
        if collectionView == GroupCollectionView
        {
            return GroupCount
        }
        return 0
    }
    
    /// Return a UICollectionViewCell for the specified collection and index. This function handles both group and
    /// filter UICollectionViews.
    ///
    /// - Parameters:
    ///   - collectionView: The collection view that wants a cell.
    ///   - indexPath: Determines which cell needs to be populated.
    /// - Returns: A UICollectionViewCell (cast to the appropriate type) for the specified collection and index.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if collectionView == FilterCollectionView
        {
            let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterItem", for: indexPath) as UICollectionViewCell
            var FilterCell: FilterCollectionCell!
            FilterCell = Cell as? FilterCollectionCell
            FilterCell.SetCellValue(Title: FilterNodes[indexPath.row].Title, IsSelected: false, ID: indexPath.row, IsGroup: false,
                                    Color:GroupNodes[LastSelectedGroup].Color)
            FilterCell.SetSelectionState(Selected: FilterNodes[indexPath.row].IsSelected)
            return FilterCell
        }
        else
        {
            let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath) as UICollectionViewCell
            var GroupCell: FilterCollectionCell!
            GroupCell = Cell as? FilterCollectionCell
            GroupCell.SetCellValue(Title: GroupNodes[indexPath.row].Title, IsSelected: false, ID: indexPath.row,
                                   IsGroup: true, Color: GroupNodes[indexPath.row].Color)
            GroupCell.SetSelectionState(Selected: GroupNodes[indexPath.row].IsSelected)
            return GroupCell
        }
    }
    
    /// Handle selection events in the UI for group and filter selections. Handles selection events for both
    /// group and filter selections.
    ///
    /// - Parameters:
    ///   - collectionView: The UICollectionView where the selection event occurred.
    ///   - indexPath: The newly selected item.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if collectionView == FilterCollectionView
        {
            LastSelectedItem = indexPath.row
            FilterNodes.forEach{$0.IsSelected = false}
            FilterNodes[indexPath.row].IsSelected = true
            FilterCollectionView.reloadData()
            let Current = FilterNodes[indexPath.row].FilterType
            if Filters!.GetFilterID(For: Current) == LastSelectedFilterID
            {
                print("Tried to select the same filter two times in a row.")
                return
            }
            let FilterTitle = Filters!.GetFilterTitle(Current)
            ShowFilter(FilterTitle)
            Filters!.SetCurrentFilter(Name: Current)
            LastSelectedFilterID = Filters!.GetFilterID(For: Current)
            _Settings.set(LastSelectedFilterID?.uuidString, forKey: "CurrentFilter")
            StopHideTimer()
            StartHidingTimer()
        }
        if collectionView == GroupCollectionView
        {
            LastSelectedGroup = indexPath.row
            let FilterData = Filters?.GetFilterData(ForGroup: GroupNodes[LastSelectedGroup].GroupType)
            MakeFilterData(FilterData!, GroupNodes[LastSelectedGroup].GroupType)
            CurrentGroupFilters = (Filters?.FiltersForGroup(GroupNodes[LastSelectedGroup].GroupType))!
            FilterNodes.forEach{if $0.FilterID == LastSelectedFilterID
            {
                $0.IsSelected = true
                }
                else
            {
                $0.IsSelected = false
                }
            }
            GroupNodes.forEach{$0.IsSelected = false}
            GroupNodes[indexPath.row].IsSelected = true
            GroupCollectionView.reloadData()
            FilterCollectionView.reloadData()
            StopHideTimer()
            StartHidingTimer()
        }
    }
    
    /// Handles deselection events for filter deselections.
    ///
    /// - Parameters:
    ///   - collectionView: The filter's UICollectionView.
    ///   - indexPath: Index of the newly deselected item.
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
    {
        if collectionView == FilterCollectionView
        {
            guard let Cell = collectionView.cellForItem(at: indexPath) else
            {
                return
            }
            let SelectedCell = Cell as! FilterCollectionCell
            SelectedCell.SetSelectionState(Selected: false)
        }
    }
    
    func StartHidingTimer()
    {
        if !_Settings.bool(forKey: "HideFilterSelectionUI")
        {
            return
        }
        
        let Interval = _Settings.double(forKey: "SelectionHideTime")
        HideTimer = Timer.scheduledTimer(timeInterval: Interval, target: self, selector: #selector(AutoHideUI), userInfo: nil, repeats: false)
    }
    
    func StopHideTimer()
    {
        if !_Settings.bool(forKey: "HideFilterSelectionUI")
        {
            return
        }
        
        HideTimer?.invalidate()
        HideTimer = nil
    }
    
    @objc func AutoHideUI()
    {
        HideTimer?.invalidate()
        HideTimer = nil
        UpdateFilterSelectionVisibility()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        if scrollView != GroupCollectionView && scrollView != FilterCollectionView
        {
            return
        }
        StopHideTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        if scrollView != GroupCollectionView && scrollView != FilterCollectionView
        {
            return
        }
        StartHidingTimer()
    }
}
