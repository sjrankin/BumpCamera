//
//  FilterSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/30/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

//https://github.com/jeantimex/ios-swift-collapsible-table-section/blob/master/ios-swift-collapsible-table-section/CollapsibleTableViewController.swift
class FilterSettingsUICode: UITableViewController, CollapsibleTableViewHeaderDelegate
{
    let Filters = FilterManager()
    let _Settings = UserDefaults.standard
    var Sections = [FilterSectionData]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        PreloadTable()
        
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func PreloadTable()
    {
        GroupTitles = Filters.GetGroupNames()
        GroupTitles?.sort{$0.2 < $1.2}
        
        var Index = 1
        for (GroupTitle, GroupType, _) in GroupTitles!
        {
            let NewSection = FilterSectionData()
            NewSection.HeaderTitle = GroupTitle
            NewSection.Index = Index
            var FiltersForGroup = Filters.GetFilterData(ForGroup: GroupType)
            FiltersForGroup.sort{$0.2 < $1.2}
            for (FilterTitle, FilterType, _, _) in FiltersForGroup
            {
                NewSection.CellData.append((FilterType, FilterTitle))
            }
            Sections.append(NewSection)
            Index = Index + 1
        }
        
        let FilterIDString = _Settings.string(forKey: "CurrentFilter")
        let FilterID = UUID(uuidString: FilterIDString!)
        let TypeOfFilter = Filters.GetFilterTypeFrom(ID: FilterID!)
        let CurrentName = Filters.GetFilterTitle(TypeOfFilter!)
        let FirstSection = FilterSectionData()
        FirstSection.HeaderTitle = "Current Filter"
        FirstSection.CanCollapse = false
        FirstSection.Index = 0
        FirstSection.CellData.append((TypeOfFilter!, CurrentName))
        Sections.insert(FirstSection, at: 0)
    }
    
    var GroupTitles: [(String, FilterManager.FilterGroups, Int)]? = nil
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        var Title: String!
        var CanCollapse = true
        Title = Sections[section].HeaderTitle
        CanCollapse = Sections[section].CanCollapse
        
        let Header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as? CollapsibleHeader ?? CollapsibleHeader(reuseIdentifier: "Header", CanCollapse: CanCollapse)
        
        Header.TitleLabel.text = Title
        Header.ArrowLabel.text = "▶"
        Header.SetCollapseVisual(IsCollapsed: Sections[section].SectionCollapsed)
        Header.Section = section
        Header.delegate = self
        return Header
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let Index = indexPath.section
        return Sections[Index].SectionCollapsed ? 0 : UITableView.automaticDimension
    }
    
    override func tableView(_ TableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 44.0
    }
    
    override func tableView(_ TableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 1.0
    }
    
    func ToggleSection(Header: CollapsibleHeader, Section: Int)
    {
        let DoCollapse = Sections[Section].Toggle()
        Header.SetCollapseVisual(IsCollapsed: DoCollapse)
        self.tableView.beginUpdates()
        self.tableView.reloadSections(NSIndexSet(index: Section) as IndexSet, with: .automatic)
        self.tableView.endUpdates()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return Sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if Sections[section].SectionCollapsed
        {
            return 0
        }
        return Sections[section].CellData.count
    }
    
    var FilterList = [FilterManager.FilterGroups: [FilterManager.FilterTypes]]()
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let Cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "FilterCell")
        let TypeOfFilter = Sections[indexPath.section].CellType(AtIndex: indexPath.row)
        Cell.selectionStyle = .none
        Cell.accessoryType = .disclosureIndicator
        let Title = Filters.GetFilterTitle(TypeOfFilter)
        Cell.textLabel!.text = Title
        return Cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let TypeOfFilter = Sections[indexPath.section].CellType(AtIndex: indexPath.row)
        _Settings.set(TypeOfFilter.rawValue, forKey: "SetupForFilterType")
        if let StoryboardName = FilterManager.StoryboardFor(TypeOfFilter)
        {
            print("Filter \(TypeOfFilter) storyboard name is \(StoryboardName) at \(CACurrentMediaTime())")
            let Storyboard = UIStoryboard(name: StoryboardName, bundle: nil)
            if let Controller = Storyboard.instantiateViewController(withIdentifier: StoryboardName) as? UINavigationController
            {
                print("Filter \(TypeOfFilter) after instantiation at \(CACurrentMediaTime())")
                DispatchQueue.main.async
                    {
                self.present(Controller, animated: true, completion: nil)
                }
            }
            else
            {
                print("Error instantiating storyboard \(StoryboardName)")
            }
        }
        else
        {
            print("No storyboard name available for \(TypeOfFilter)")
        }
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        //navigationController?.popToRootViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
}

extension UIView
{
    func Rotate(_ ToValue: CGFloat, Duration: TimeInterval = 0.2)
    {
        let Animation = CABasicAnimation(keyPath: "transform.rotation")
        Animation.toValue = ToValue
        Animation.duration = Duration
        Animation.isRemovedOnCompletion = false
        Animation.fillMode = CAMediaTimingFillMode.forwards
        self.layer.add(Animation, forKey: nil)
    }
}
