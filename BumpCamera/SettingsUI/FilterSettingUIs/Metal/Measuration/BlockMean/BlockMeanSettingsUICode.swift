//
//  BlockMeanSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import simd

class BlockMeanSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.BlockMean, CallFilter: false)
        BlockCountValue.text = ""
        
        BlockWidthValue.text = "\(CurrentBlockWidth)"
        WidthSlider.value = Float(CurrentBlockWidth * 10)
        BlockHeightValue.text = "\(CurrentBlockHeight)"
        HeightSlider.value = Float(CurrentBlockHeight * 10)
        
        ResultsTable.layer.borderWidth = 0.5
        ResultsTable.layer.borderColor = UIColor.black.cgColor
        ResultsTable.layer.cornerRadius = 5.0
        
        ResultsTable.delegate = self
        ResultsTable.dataSource = self
        ResultsTable.reloadData()
    }
    
    @IBAction func HandleWidthChanged(_ sender: Any)
    {
        CurrentBlockWidth = Int(WidthSlider.value / 10.0)
        BlockWidthValue.text = "\(CurrentBlockWidth)"
    }
    
    var CurrentBlockWidth: Int = 20
    
    @IBAction func HandleHeightChanged(_ sender: Any)
    {
        CurrentBlockHeight = Int(HeightSlider.value / 10.0)
        BlockHeightValue.text = "\(CurrentBlockHeight)"
    }
    
    var CurrentBlockHeight: Int = 20
    
    @IBAction func HandleCalculatePressed(_ sender: Any)
    {
        let BMean = BlockMean()
        BMean.InitializeForImage()
        var Parameters = [String: Any]()
        Parameters["Width"] = CurrentBlockWidth as Any
        Parameters["Height"] = CurrentBlockHeight as Any
        Parameters["CalculateMean"] = true as Any
        let Results = BMean.Query(Image: SampleViewImage!, Parameters: Parameters)
        if let Final = Results
        {
            var XCount: Int? = nil
            if let BlocksX = Final["HorizontalBlocks"] as? Double
            {
                XCount = Int(BlocksX)
            }
            var YCount: Int? = nil
            if let BlocksY = Final["VerticalBlocks"] as? Double
            {
                YCount = Int(BlocksY)
            }
            if XCount != nil && YCount != nil
            {
                let BlockCount = XCount! * YCount!
                BlockCountValue.text = "\(BlockCount)"
            }
            else
            {
                BlockCountValue.text = "?"
                MeanResults.removeAll()
                ResultsTable.reloadData()
                return
            }
            if let Means = Final["BlockMeans"] as? [simd_float4]
            {
                MeanResults.removeAll()
                for Y in 0 ..< YCount!
                {
                    for X in 0 ..< XCount!
                    {
                        let Index = (XCount! * Y) + X
                        let Color = UIColor.From(Float4: Means[Index])
                        MeanResults.append((X, Y, Color))
                    }
                }
                ResultsTable.reloadData()
            }
        }
    }
    
    var MeanResults = [(Int, Int, UIColor)]()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if tableView.tag == 100
        {
            return MeanResults.count
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        if tableView.tag == 100
        {
            return 1
        }
        return super.numberOfSections(in: tableView)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if tableView.tag == 100
        {
            let Cell = BlockMeanResultCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "MeanColorAtBlock")
            let (X, Y, Color) = MeanResults[indexPath.row]
            Cell.SetData(IndexValue: "(\(X),\(Y))", Color: Color)
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if tableView.tag == 100
        {
            return BlockMeanResultCell.CellHeight
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    @IBOutlet weak var BlockHeightValue: UILabel!
    @IBOutlet weak var BlockWidthValue: UILabel!
    @IBOutlet weak var HeightSlider: UISlider!
    @IBOutlet weak var WidthSlider: UISlider!
    @IBOutlet weak var BlockCountValue: UILabel!
    @IBOutlet weak var ResultsTable: UITableView!
}
