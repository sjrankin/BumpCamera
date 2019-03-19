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
                return
            }
            if let Means = Final["BlockMeans"] as? [ReturnBlockData]
            {
                MeanResults.removeAll()
                for Returned in Means
                {
                    let Count = CGFloat(Returned.Count)
                    let Red = CGFloat(Returned.Red) / Count
                    let Green = CGFloat(Returned.Green) / Count
                    let Blue = CGFloat(Returned.Blue) / Count
                    let Color = UIColor(red: Red, green: Green, blue: Blue, alpha: 1.0)
                    MeanResults.append((Int(Returned.X), Int(Returned.Y), Color, Int(Returned.Count)))
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToResultViewer":
            if let Dest = segue.destination as? BlockmeanResultViewerCode
            {
                Dest.SetMeanData(MeanData: MeanResults)
            }
            
        default:
            break
        }
    }
    
    var MeanResults = [(Int, Int, UIColor, Int)]()
    
    @IBOutlet weak var BlockHeightValue: UILabel!
    @IBOutlet weak var BlockWidthValue: UILabel!
    @IBOutlet weak var HeightSlider: UISlider!
    @IBOutlet weak var WidthSlider: UISlider!
    @IBOutlet weak var BlockCountValue: UILabel!
}
