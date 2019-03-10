//
//  PixelCounterSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class PixelCounterSettingsUICode: FilterSettingUIBase
{
    var Measuration: PixelCounter? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.PixelCounter, CallFilter: false)
        ColorResults = [(UIColor, Int)]()
        MeanColor.layer.borderColor = UIColor.black.cgColor
        MeanColor.layer.borderWidth = 0.5
        MeanColor.layer.cornerRadius = 5.0
        MeanColor.backgroundColor = UIColor.clear
        
        Measuration = PixelCounter()
        Measuration?.InitializeForImage()
        MeanPixelValueLabel.text = "Mean pixel"
        
        ColorCountTable.delegate = self
        ColorCountTable.dataSource = self
        HueRangeTable.delegate = self
        HueRangeTable.dataSource = self
    }
    
    var ColorResults: [(UIColor, Int)]? = nil
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if tableView.tag == 1000
        {
            return ColorResults!.count
        }
        if tableView.tag == 2000
        {
            return HueCountResults.count
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        if tableView.tag == 1000
        {
            return 1
        }
        if tableView.tag == 2000
        {
            return 1
        }
        return super.numberOfSections(in: tableView)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if tableView.tag == 1000
        {
            let Cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Table1000Cell")
            Cell.textLabel!.text = "Color: \(Utility.ColorToString(TestColors[indexPath.row]))"
            Cell.detailTextLabel!.text = "Count: \(ColorCounts[indexPath.row])"
            return Cell
        }
        if tableView.tag == 2000
        {
            let Cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Table2000Cell")
            Cell.textLabel!.text = "Range start \(HueCountResults[indexPath.row].0)"
            Cell.detailTextLabel!.text = "Count: \(HueCountResults[indexPath.row].1)"
            return Cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    var TestColors = [UIColor.red, UIColor.green, UIColor.blue]
    var ColorCounts = [Int]()
    
    @IBAction func HandleCountButtonPressed(_ sender: Any)
    {
        var Parameters = [String: Any]()
        Parameters["Action"] = 0 as Any
        Parameters["PixelSearchCount"] = 3 as Any
        Parameters["CountFor"] = TestColors
        Parameters["CountIf"] = 0 as Any
        Parameters["HueOffset"] = 0.0 as Any
        Parameters["RangeSize"] = 0.0 as Any
        let Results = Measuration?.Query(Image: SampleViewImage!, Parameters: Parameters)
        if let Final = Results
        {
            ColorCounts.removeAll()
            for (_, Raw) in Final
            {
                let Count = Raw as! Double
                ColorCounts.append(Int(Count))
            }
            ColorCountTable.reloadData()
        }
        else
        {
            ColorCounts.removeAll()
            ColorCountTable.reloadData()
            print("Error returned by PixelCounter.")
        }
    }
    
    var HueCountResults = [(Double, Int)]()
    
    @IBAction func HandleCountHuesButtonPressed(_ sender: Any)
    {
        var Parameters = [String: Any]()
        Parameters["Action"] = 2 as Any
        Parameters["PixelSearchCount"] = 3 as Any
        Parameters["CountFor"] = [UIColor]()
        Parameters["CountIf"] = 0 as Any
        Parameters["HueOffset"] = 0.0 as Any
        Parameters["RangeSize"] = 0.1 as Any
        let Results = Measuration?.Query(Image: SampleViewImage!, Parameters: Parameters)
        HueCountResults.removeAll()
        if let Final = Results
        {
            var Range = 0.0
            for (_, RawCount) in Final
            {
                let FinalCount = RawCount as! Double
                HueCountResults.append((Range, Int(FinalCount)))
                Range = Range + 0.1
            }
        }
        else
        {
            print("Error returned by PixelCounter.")
        }
        HueRangeTable.reloadData()
    }
    
    @IBAction func HandleMeanColorButtonPressed(_ sender: Any)
    {
        var Parameters = [String: Any]()
        Parameters["Action"] = 1 as Any
        Parameters["PixelSearchCount"] = 3 as Any
        Parameters["CountFor"] = [UIColor]()
        Parameters["CountIf"] = 0 as Any
        Parameters["HueOffset"] = 0.0 as Any
        Parameters["RangeSize"] = 0.0 as Any
        let Results = Measuration?.Query(Image: SampleViewImage!, Parameters: Parameters)
        if let Final = Results
        {
            let Total = Final["PixelCount"] as! Int
            let RedMean = CGFloat(Final["MeanRed"] as! Double)
            let GreenMean = CGFloat(Final["MeanGreen"] as! Double)
            let BlueMean = CGFloat(Final["MeanBlue"] as! Double)
            let MWidth = Int(Final["Width"] as! Double)
            let MHeight = Int(Final["Height"] as! Double)
            let stemp = "\(MWidth)x\(MHeight), rgb=(\(Int(RedMean)),\(Int(GreenMean)),\(Int(BlueMean)))"
            MeanPixelValueLabel.text = stemp
//            let CalculatedMeanColor = UIColor(red: RedMean, green: GreenMean, blue: BlueMean, alpha: 1.0)
//            MeanColor.backgroundColor = CalculatedMeanColor
//            MeanPixelValueLabel.text = "Pixel count: \(Total), Value: \(Utility.ColorToString(CalculatedMeanColor))"
        }
        else
        {
            MeanPixelValueLabel.text = ""
            print("Error returned from PixelCounter.")
        }
    }
    
    @IBOutlet weak var MeanPixelValueLabel: UILabel!
    @IBOutlet weak var MeanColor: UIView!
    @IBOutlet weak var ColorCountTable: UITableView!
    @IBOutlet weak var HueRangeTable: UITableView!
}
