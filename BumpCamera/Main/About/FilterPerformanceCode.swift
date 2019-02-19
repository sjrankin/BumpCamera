//
//  FilterPerformanceCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class FilterPerformanceCode: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        MakeFilterLists()
        self.tableView.reloadData()
    }
    
    func MakeFilterLists()
    {
        HeaderList = [String]()
        FullList = [String: [FilterManager.FilterTypes]]()
        for (KernelType, KernelName) in FilterManager.FilterKernelMap
        {
            FullList[KernelName] = FilterManager.FiltersByKernel(KernelType: KernelType)
            HeaderList.append(KernelName)
        }
        HeaderList.sort{$0 < $1}
        HeaderList.append("Actions")
    }
    
    var FullList: [String: [FilterManager.FilterTypes]]!
    var HeaderList: [String]!
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return HeaderList.count
    }
    
    override func tableView(_ TableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let HeaderTitle = HeaderList[section]
        if HeaderTitle == "Actions"
        {
            return 1
        }
        return FullList![HeaderTitle]!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return HeaderList[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return PerformanceCell.CellHeight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let Cell = PerformanceCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "PerformanceCell")
        let HTitle = HeaderList[indexPath.section]
        if HTitle == "Actions"
        {
            let Cell = PerformanceActionCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "ActionCell")
            Cell.selectionStyle = .none
            Cell.delegate = self
            return Cell
        }
        let Filter = FullList[HTitle]![indexPath.row]
        let (Name, ImageCount, ImageTime, LiveCount, LiveTime) = GetFilterPerformance(FilterType: Filter)!
        Cell.SetData(FilterName: Name, ImageCount: ImageCount, ImageMean: ImageTime, LiveCount: LiveCount, LiveMean: LiveTime)
        return Cell
    }
    
    func GetFilterPerformance(FilterType: FilterManager.FilterTypes) -> (String, Int, Double, Int, Double)?
    {
        if let ID = FilterManager.GetFilterID(For: FilterType)
        {
            let (ImageCount, ImageTime) = ParameterManager.GetRenderStatistics(ID: ID, ForImage: true)!
            let (LiveCount, LiveTime) = ParameterManager.GetRenderStatistics(ID: ID, ForImage: false)!
            let Name = FilterManager.GetFilterTitle(FilterType)
            return (Name!, ImageCount, ImageTime, LiveCount, LiveTime)
        }
        return nil
    }
    
    func DoReset()
    {
        let Alert = UIAlertController(title: "Really Reset Statistics?",
                                      message: "Do you really want to reset all filter performance statistics? If you haven't saved your data, you can with the Export button.",
                                      preferredStyle: UIAlertController.Style.alert)
        Alert.addAction(UIAlertAction(title: "Reset", style: UIAlertAction.Style.destructive, handler: HandleResetActions))
        Alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: HandleResetActions))
        present(Alert, animated: true)
    }
    
    @objc func HandleResetActions(Action: UIAlertAction)
    {
        switch Action.title
        {
        case "Reset":
            FilterManager.ResetPerformanceStatistics(CalledBy: "FilterPerformanceCode")
            let Alert2 = UIAlertController(title: "Reset Complete",
                                           message: "All filter performance data has been reset. If you have not disabled performance data collection, data will start accumulating immediately.",
                                           preferredStyle: UIAlertController.Style.alert)
            Alert2.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(Alert2, animated: true)
            
        case "Cancel":
            break
            
        default:
            break
        }
    }
    
    func DoExport()
    {
        let Alert = UIAlertController(title: "Export Filter Performance Data",
                                      message: "Select the format of your exported data. Files are stored in the PerformanceData directory off of the BumpCamera top-level directory, viewable with Apple's Files app.",
                                      preferredStyle: UIAlertController.Style.alert)
        Alert.addAction(UIAlertAction(title: "Save as XML", style: UIAlertAction.Style.default, handler: HandleExportActions))
        Alert.addAction(UIAlertAction(title: "Save as CSV", style: UIAlertAction.Style.default, handler: HandleExportActions))
        Alert.addAction(UIAlertAction(title: "Save as JSON", style: UIAlertAction.Style.default, handler: HandleExportActions))
        Alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: HandleExportActions))
        present(Alert, animated: true)
    }
    
    @objc func HandleExportActions(Action: UIAlertAction)
    {
        var ShowResult = false
        var SavedOK = false
        var SaveName = ""
        switch Action.title
        {
        case "Save as XML":
            ShowResult = true
            let (OK, Name) = FilterManager.ExportPerformanceStatistics(AsType: FilterManager.ExportDataTypes.XML)
            SavedOK = OK
            SaveName = Name
            
        case "Save as CSV":
            ShowResult = true
            let (OK, Name) = FilterManager.ExportPerformanceStatistics(AsType: FilterManager.ExportDataTypes.CSV)
            SavedOK = OK
            SaveName = Name
            
        case "Save as JSON":
            ShowResult = true
            let (OK, Name) = FilterManager.ExportPerformanceStatistics(AsType: FilterManager.ExportDataTypes.JSON)
            SavedOK = OK
            SaveName = Name
            
        case "Cancel":
            ShowResult = false
            
        default:
            break
        }
        if ShowResult
        {
            if SavedOK
            {
                let Alert2 = UIAlertController(title: "Save Complete",
                                               message: "Filter performance data successfully saved and placed into the BumpCamera directory with the name \(SaveName).",
                    preferredStyle: UIAlertController.Style.alert)
                Alert2.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(Alert2, animated: true)
            }
            else
            {
                let Alert2 = UIAlertController(title: "Error Saving Performance Data",
                                               message: "There was an error saving performance data. Make sure there is enough space on your device and try again.",
                                               preferredStyle: UIAlertController.Style.alert)
                Alert2.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(Alert2, animated: true)
            }
        }
    }
    
    func DoClearDirectory()
    {
        let Alert = UIAlertController(title: "Clear Performance Directory?",
                                      message: "Delete all old, exported performance data files in the PerformanceData directory? (This will not affect data stored internally.)",
                                      preferredStyle: UIAlertController.Style.alert)
        Alert.addAction(UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive, handler: HandleClearDirectoryActions))
        Alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(Alert, animated: true)
    }
    
    @objc func HandleClearDirectoryActions(Action: UIAlertAction)
    {
        switch Action.title
        {
        case "Delete":
            let OK = FileHandler.ClearDirectory(FileHandler.PerformanceDirectory)
            if !(OK)
            {
                print("Error clearing performance directory.")
            }
            
        default:
            break
        }
    }
}
