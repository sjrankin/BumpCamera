//
//  Pixellate2TableCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/30/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class Pixellate2TableCode: FilterTableBase, NewFieldSettingProtocol
{
    let Filter = FilterManager.FilterTypes.PixellateMetal
    var FilterID: UUID!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
        FilterID = FilterManager.FilterMap[Filter]
        
        //https://stackoverflow.com/questions/9390298/iphone-how-to-detect-the-end-of-slider-drag
        WidthSlider.addTarget(self, action: #selector(WidthDoneSliding), for: [.touchUpInside, .touchUpOutside])
        HeightSlider.addTarget(self, action: #selector(HeightDoneSliding), for: [.touchUpInside, .touchUpOutside])
        
        let H_Highlight = ParameterManager.GetBool(From: FilterID, Field: .HighlightColor, Default: false)
        let S_Highlight = ParameterManager.GetBool(From: FilterID, Field: .HighlightSaturation, Default: false)
        let B_Highlight = ParameterManager.GetBool(From: FilterID, Field: .HighlightBrightness, Default: false)
        let H_String = H_Highlight ? "enabled" : "disabled"
        let S_String = S_Highlight ? "enabled" : "disabled"
        let B_String = B_Highlight ? "enabled" : "disabled"
        ColorEnabledLabel.text = H_String
        SaturationEnabledLabel.text = S_String
        BrightnessEnabledLabel.text = B_String
    }
    
    @objc func WidthDoneSliding()
    {
        let SliderValue: Int = Int(WidthSlider.value / 50.0)
        WidthOut.text = "\(SliderValue)"
        UpdateBoth()
    }
    
    @objc func HeightDoneSliding()
    {
        let SliderValue: Int = Int(HeightSlider.value / 50.0)
        HeightOut.text = "\(SliderValue)"
        UpdateBoth()
    }
    
    func UpdateBoth()
    {
        let Width = Int(WidthSlider.value / 50.0)
        let Height = Int(HeightSlider.value / 50.0)
        UpdateSettings(WithWidth: Width, WithHeight: Height)
    }
    
    @IBAction func HandleWidthSliderChanged(_ sender: Any)
    {
        let SliderValue: Int = Int(WidthSlider.value / 50.0)
        WidthOut.text = "\(SliderValue)"
    }
    
    @IBAction func HandleHeightSliderChanged(_ sender: Any)
    {
        let SliderValue: Int = Int(HeightSlider.value / 50.0)
        HeightOut.text = "\(SliderValue)"
    }
    
    @IBOutlet weak var SaturationEnabledLabel: UILabel!
    @IBOutlet weak var ColorEnabledLabel: UILabel!
    @IBOutlet weak var BrightnessEnabledLabel: UILabel!
    @IBOutlet weak var HeightOut: UILabel!
    @IBOutlet weak var WidthOut: UILabel!
    @IBOutlet weak var WidthSlider: UISlider!
    @IBOutlet weak var HeightSlider: UISlider!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToPixellateColorHighlighting":
            break
            
        case "ToPixellateBrightnessHighlighting":
            break
            
        case "ToPixellateSaturateHighlighting":
            break
            
        default:
            break
        }
        super.prepare(for: segue, sender: self)
    }
    
    func UpdateSettings(WithWidth: Int, WithHeight: Int)
    {
        ParameterManager.SetField(To: FilterID, Field: .BlockWidth, Value: WithWidth as Any?)
        ParameterManager.SetField(To: FilterID, Field: .BlockHeight, Value: WithHeight as Any?)
        ParentDelegate?.NewRawValue()
    }
    
    func NewRawValue()
    {
    }
    
    func NewRawValue(For: FilterManager.InputFields)
    {
        switch For
        {
        case .HighlightColor:
            let H_Highlight = ParameterManager.GetBool(From: FilterID, Field: .HighlightColor, Default: false)
            let H_String = H_Highlight ? "enabled" : "disabled"
            ColorEnabledLabel.text = H_String
            ParameterManager.SetField(To: FilterID, Field: .HighlightColor, Value: H_Highlight as Any?)
            
        case .HighlightSaturation:
            let S_Highlight = ParameterManager.GetBool(From: FilterID, Field: .HighlightSaturation, Default: false)
            let S_String = S_Highlight ? "enabled" : "disabled"
            SaturationEnabledLabel.text = S_String
            ParameterManager.SetField(To: FilterID, Field: .HighlightSaturation, Value: S_Highlight as Any?)
            
        case .HighlightBrightness:
            let B_Highlight = ParameterManager.GetBool(From: FilterID, Field: .HighlightBrightness, Default: false)
            let B_String = B_Highlight ? "enabled" : "disabled"
            BrightnessEnabledLabel.text = B_String
            ParameterManager.SetField(To: FilterID, Field: .HighlightBrightness, Value: B_Highlight as Any?)
            
        default:
            break
        }
    }
}
