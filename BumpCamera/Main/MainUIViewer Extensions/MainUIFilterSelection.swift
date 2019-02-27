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
    
    /// Initialize the filter UI data structure. Load the initial filter and set it for use. If no existing filter is in place, or
    /// the user specified to not use the last filter, start with the pass-through filter.
    func InitializeFilterUIData()
    {
        var InitialGroup = FilterManager.FilterGroups.NotSet
        var InitialFilter = FilterManager.FilterTypes.NotSet
        if _Settings.bool(forKey: "StartWithLastFilter")
        {
            let InitialFilterIDS = _Settings.string(forKey: "CurrentFilter")
            let InitialFilterID = UUID(uuidString: InitialFilterIDS!)
            InitialFilter = FilterManager.GetFilterTypeFrom(ID: InitialFilterID!)!
            InitialGroup = FilterManager.GroupFromFilter(ID: InitialFilterID!)!
            print("Loading last used group:filter \(InitialGroup):\(InitialFilter)")
            Filters!.SetCurrentFilter(FilterType: InitialFilter)
        }
        else
        {
            InitialGroup = FilterManager.FilterGroups.Standard
            InitialFilter = FilterManager.FilterTypes.PassThrough
            var IDS = ""
            if let InitialFilterID = FilterManager.GetFilterID(For: InitialFilter)
            {
                IDS = InitialFilterID.uuidString
            }
            else
            {
                IDS = "e18b32bf-e965-41c6-a1f5-4bb4ed6ba472"
            }
            _Settings.set(IDS, forKey: "CurrentFilter")
        }
        GroupData = GroupNodeManager(InitialGroup: InitialGroup, InitialFilter: InitialFilter, ForTargets: [.LiveView])
    }
    
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
    }
    
    /// Programmatically select a filter and show the UI.
    /// - Note: Does not yet show the UI on command.
    /// - Parameters:
    ///   - ID: ID of the filter to select.
    ///   - ShowUI: If true, the filter selection UI will be made visible if it isn't already.
    func SelectFilter(ID: UUID, ShowUI: Bool)
    {
        GroupData.SelectFilter(ID)
    }
    
    /// Programmatically select a filter and show the UI.
    /// - Note: Does not yet show the UI on command.
    /// - Parameters:
    ///   - FilterType: The type of the filter to select.
    ///   - ShowUI: If true, the filter selection UI will be made visible if it isn't already.
    func SelectFilter(FilterType: FilterManager.FilterTypes, ShowUI: Bool)
    {
        GroupData.SelectFilter(FilterType)
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
            return GroupData.FiltersInGroup(LastSelectedGroup)
        }
        if collectionView == GroupCollectionView
        {
            return GroupData!.GroupCount
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
            //Add filters to the filter row.
            let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterItem", for: indexPath) as UICollectionViewCell
            var FilterCell: FilterCollectionCell!
            FilterCell = Cell as? FilterCollectionCell
            let Node = GroupData!.GetFilterNode(LastSelectedGroup, indexPath.row)
            FilterCell.SetCellValue(Title: Node!.Title, IsSelected: false, ID: indexPath.row, IsGroup: false,
                                    Color: Node!.Color)
            FilterCell.SetSelectionState(Selected: Node!.IsSelected)
            return FilterCell
        }
        else
        {
            //Add groups to the group row.
            let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath) as UICollectionViewCell
            var GroupCell: FilterCollectionCell!
            GroupCell = Cell as? FilterCollectionCell
            let Node = GroupData!.GroupNodeByOrdinal(indexPath.row)
            GroupCell.SetCellValue(Title: Node!.Title, IsSelected: false, ID: indexPath.row,
                                   IsGroup: true, Color: Node!.Color)
            GroupCell.SetSelectionState(Selected: Node!.IsSelected)
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
            //Handle filter selections. If the selected group is different from the selected filter, the proper
            //group will be selected here as well.
            collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
            LastSelectedItem = indexPath.row
            GroupData!.SelectFilterAt(GroupIndex: LastSelectedGroup, FilterIndex: LastSelectedItem)
            FilterCollectionView.reloadData()
            let Current = GroupData!.CurrentFilter()
            if FilterManager.GetFilterID(For: Current!) == LastSelectedFilterID
            {
                print("Tried to select the same filter two times in a row.")
                return
            }
            LastSelectedFilterID = FilterManager.GetFilterID(For: Current!)
            let FilterTitle = FilterManager.GetFilterTitle(Current!)
            ShowFilter(FilterTitle!)
            //The next line actually switches the filters being used.
            Filters!.SetCurrentFilter(FilterType: Current!)
            _Settings.set(LastSelectedFilterID?.uuidString, forKey: "CurrentFilter")
            //See if the currently selected group is where the newly selected filter lives. If not, select the proper group.
            let NewFiltersGroup = FilterManager.GroupFromFilter(ID: LastSelectedFilterID!)
            if GroupData!.CurrentGroup() != NewFiltersGroup
            {
                GroupData!.SelectGroup(NewFiltersGroup!)
                if let GroupIndex = GroupData!.OrdinalOfGroup(NewFiltersGroup!)
                {
                    let IP = IndexPath(row: GroupIndex, section: 0)
                    GroupCollectionView.scrollToItem(at: IP, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
                }
            }
            StopHideTimer()
            StartHidingTimer()
        }
        if collectionView == GroupCollectionView
        {
            //Handle group selections. Update the filters shown in the UI when new groups are selected.
            collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
            LastSelectedGroup = indexPath.row
            GroupData!.SelectGroup(LastSelectedGroup)
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
    
    /// Start the hide UI timer.
    func StartHidingTimer()
    {
        if !_Settings.bool(forKey: "HideFilterSelectionUI")
        {
            return
        }
        
        let Interval = _Settings.double(forKey: "SelectionHideTime")
        HideTimer = Timer.scheduledTimer(timeInterval: Interval, target: self, selector: #selector(AutoHideUI), userInfo: nil, repeats: false)
    }
    
    /// Stop the hide UI timer.
    func StopHideTimer()
    {
        if !_Settings.bool(forKey: "HideFilterSelectionUI")
        {
            return
        }
        
        HideTimer?.invalidate()
        HideTimer = nil
    }
    
    /// Called when the hide UI timer fires. Hides the UI automatically so it doesn't clutter up the screen.
    @objc func AutoHideUI()
    {
        HideTimer?.invalidate()
        HideTimer = nil
        UpdateFilterSelectionVisibility()
    }
    
    /// Event triggered when the scroll view started moving (via the user). When this happens, stop the hide UI timer.
    ///
    /// - Parameter scrollView: The scroll view control (or control with this protocol) that started moving.
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        if scrollView != GroupCollectionView && scrollView != FilterCollectionView
        {
            return
        }
        StopHideTimer()
    }

    /// Event triggered when the scroll view stopped moving (via the user). When this happens, start the hide UI timer.
    ///
    /// - Parameter scrollView: The scroll view control (or control with this protocol) that stopped moving.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        if scrollView != GroupCollectionView && scrollView != FilterCollectionView
        {
            return
        }
        StartHidingTimer()
    }
}
