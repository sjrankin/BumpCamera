//
//  ScrollDebug.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ScrollDebug: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource
{
    var GroupCount = 7
    var GroupTitles: [(String, FilterGroups, Int)]? = nil
    var Filters: FilterManager? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Filters = FilterManager()
        GroupTitles = Filters!.GetGroupNames()
        #if true
        GroupTitles!.sort{$0.2 < $1.2}
        MakeGroupData(GroupTitles!)
        #else
        MakeGroupDataX(GroupCount)
        #endif
        CurrentGroupFilters = (Filters?.FiltersForGroup(GroupList[0].Group))!
        GroupList[0].IsSelected = true
        
        GroupScroll.register(ScrollTestItem2.self, forCellWithReuseIdentifier: "SlowlySlug")
        GroupScroll.allowsSelection = true
        GroupScroll.allowsMultipleSelection = false
        
        DetailScroll.register(ScrollTestItem.self, forCellWithReuseIdentifier: "FredFastbender")
        DetailScroll.allowsSelection = true
        DetailScroll.allowsMultipleSelection = false
        
        Toolbar.layer.zPosition = 1000
        DetailScroll.layer.zPosition = 501
        GroupScroll.layer.zPosition = 500
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        LastSelectedGroup = 0
        GroupRect = GroupScroll.frame
        HiddenGroup = CGRect(x: DetailScroll.frame.minX, y: view.frame.height,
                             width: DetailScroll.frame.width, height: DetailScroll.frame.height)
        UIView.animate(withDuration: 0.1, animations:
            {
                self.GroupScroll.frame = self.HiddenGroup
        })
        GroupScroll.isHidden = true
        GroupScroll.delegate = self
        GroupScroll.dataSource = self
        GroupScroll.reloadData()
        GroupScroll.layer.borderWidth = 0.5
        GroupScroll.layer.borderColor = UIColor.white.cgColor
        GroupScroll.layer.cornerRadius = 5.0
        
        DetailRect = DetailScroll.frame
        HiddenRect = CGRect(x: DetailScroll.frame.minX, y: view.frame.height,
                            width: DetailScroll.frame.width, height: DetailScroll.frame.height)
        UIView.animate(withDuration: 0.1, animations:
            {
                self.DetailScroll.frame = self.HiddenRect
        })
        DetailScroll.isHidden = true
        DetailScroll.delegate = self
        DetailScroll.dataSource = self
        DetailScroll.reloadData()
        DetailScroll.layer.borderWidth = 0.5
        DetailScroll.layer.borderColor = UIColor.gray.cgColor
        DetailScroll.layer.cornerRadius = 5.0
    }
    
    func MakeGroupDataX(_ Count: Int)
    {
        GroupList = [GroupData]()
        let AScalar = "A".unicodeScalars.last!
        let FirstIndex = AScalar.value
        for Index in 0 ..< Count
        {
            let NewScalar = FirstIndex + UInt32(Index)
            let Group = GroupData()
            Group.Data = String(Character(UnicodeScalar(NewScalar)!))
            Group.Prefix = Group.Data
            Group.ID = Index
            Group.IsSelected = false
            GroupList.append(Group)
        }
    }
    
    func MakeGroupData(_ FilterGroupList: [(String, FilterGroups, Int)])
    {
        GroupList = [GroupData]()
        GroupCount = FilterGroupList.count
        let AScalar = "A".unicodeScalars.last!
        let CharIndex = AScalar.value
        for Index in 0 ..< GroupCount
        {
            let Group = GroupData()
            let TheGroup = FilterGroupList[Index].1
            Group.Color = (Filters?.ColorForGroup(TheGroup))!
            Group.Group = TheGroup
            let NewScalar = CharIndex + UInt32(Index)
            Group.Data = FilterGroupList[Index].0
            Group.Prefix = String(Character(UnicodeScalar(NewScalar)!))
            Group.ID = Index
            Group.IsSelected = false
            GroupList.append(Group)
        }
    }
    
    var GroupList: [GroupData]!
    
    var DetailRect = CGRect.zero
    var HiddenRect = CGRect.zero
    var GroupRect = CGRect.zero
    var HiddenGroup = CGRect.zero
    
    @IBAction func HandleTest(_ sender: Any)
    {
        if IsShowing
        {
            UIView.animate(withDuration: 0.45, animations:
                {
                    self.DetailScroll.frame = self.HiddenRect
                    self.GroupScroll.frame = self.HiddenGroup
            })
            IsShowing = false
        }
        else
        {
            DetailScroll.isHidden = false
            GroupScroll.isHidden = false
            UIView.animate(withDuration: 0.3, animations:
                {
                    self.DetailScroll.frame = self.DetailRect
                    self.GroupScroll.frame = self.GroupRect
            })
            IsShowing = true
            DetailScroll.reloadData()
            GroupScroll.reloadData()
        }
    }
    
    var IsShowing = false
    
    @IBOutlet weak var Toolbar: UIToolbar!
    @IBOutlet weak var DetailScroll: UICollectionView!
    @IBOutlet weak var GroupScroll: UICollectionView!
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if collectionView == GroupScroll
        {
            return GroupCount
        }
        if collectionView == DetailScroll
        {
            let FilterCount: Int = (Filters?.FiltersForGroup(GroupList[LastSelectedGroup].Group).count)!
            return FilterCount
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if collectionView == DetailScroll
        {
            let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FredFastbender", for: indexPath) as UICollectionViewCell
            var Test: ScrollTestItem!
            Test = Cell as? ScrollTestItem
            if GroupWithSelectedFilter != LastSelectedGroup
            {
                Test.SetSelectionState(Selected: false)
            }
            else
            {
                #if true
                Test.SetSelectionState(Selected: LastSelectedItem == indexPath.row)
                #else
                if LastSelectedItem != indexPath.row
                {
                    Test.SetSelectionState(Selected: false)
                }
                #endif
            }
            #if true
            let TheFilter = CurrentGroupFilters[indexPath.row]
            let Title = Filters!.GetFilterTitle(TheFilter)
            #else
            let Title = GroupList![LastSelectedGroup].Prefix + "\(indexPath.row)"
            #endif
            Test.SetCellValue(Title, CellColor: GroupList![LastSelectedGroup].Color)
            return Test
        }
        else
        {
            let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SlowlySlug", for: indexPath) as UICollectionViewCell
            var Test: ScrollTestItem2!
            Test = Cell as? ScrollTestItem2
            Test.SetCellValue(GroupList[indexPath.row].Data, GroupColor: GroupList[indexPath.row].Color)
            //print("Setting cell \(indexPath.row):(\(GroupList![indexPath.row].Data)) to \(GroupList![indexPath.row].IsSelected)")
            Test.SetSelectionState(Selected: GroupList![indexPath.row].IsSelected, ForRow: indexPath.row,
                                   ID: GroupList![indexPath.row].ID)
            return Test
        }
    }
    
    var LastSelectedItem: Int = -1
    var LastSelectedGroup: Int = -1
    var GroupWithSelectedFilter: Int = -1
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if collectionView == DetailScroll
        {
            if LastSelectedItem > -1
            {
                collectionView.deselectItem(at: IndexPath(index: LastSelectedItem), animated: true)
            }
            LastSelectedItem = indexPath.row
            guard let Cell = collectionView.cellForItem(at: indexPath) else
            {
                return
            }
            let SelectedCell = Cell as! ScrollTestItem
            SelectedCell.SetSelectionState(Selected: true)
            GroupWithSelectedFilter = LastSelectedGroup
            //print("Group with selected filter: \(GroupWithSelectedFilter)")
        }
        else
        {
            LastSelectedGroup = indexPath.row
            CurrentGroupFilters = (Filters?.FiltersForGroup(GroupList[LastSelectedGroup].Group))!
            GroupList.forEach{$0.IsSelected = false}
            GroupList[indexPath.row].IsSelected = true
            GroupScroll.reloadData()
            DetailScroll.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
    {
        if collectionView == DetailScroll
        {
            guard let Cell = collectionView.cellForItem(at: indexPath) else
            {
                return
            }
            let SelectedCell = Cell as! ScrollTestItem
            SelectedCell.SetSelectionState(Selected: false)
        }
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    var CurrentGroupFilters = [FilterNames]()
}

class GroupData
{
    public var Data: String = ""
    public var ID: Int = 0
    public var IsSelected: Bool = false
    public var Prefix: String = ""
    public var Color: UIColor = UIColor.red
    public var Group: FilterGroups = FilterGroups.NotSet
}
