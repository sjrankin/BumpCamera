//
//  MPSDilateSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MPSDilateSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.MPSErode)
        
        let KWidth = ParameterManager.GetInt(From: FilterID, Field: .IWidth, Default: 3)
        let KHeight = ParameterManager.GetInt(From: FilterID, Field: .IHeight, Default: 3)
        
        WidthValue.text = "\(KWidth)"
        HeightValue.text = "\(KHeight)"
        
        WidthSlider.value = Float(KWidth * 20)
        HeightSlider.value = Float(KHeight * 20)
    }
    
    @IBAction func WidthChanged(_ sender: Any)
    {
        var SliderValue = Int(WidthSlider.value / 20.0)
        if SliderValue % 2 == 0
        {
            SliderValue = SliderValue + 1
        }
        WidthValue.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .IWidth)
        ShowSampleView()
    }
    
    @IBAction func HeightChanged(_ sender: Any)
    {
        var SliderValue = Int(HeightSlider.value / 20.0)
        if SliderValue % 2 == 0
        {
            SliderValue = SliderValue + 1
        }
        HeightValue.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .IHeight)
        ShowSampleView()
    }
    
    @IBOutlet weak var HeightValue: UILabel!
    @IBOutlet weak var WidthValue: UILabel!
    @IBOutlet weak var HeightSlider: UISlider!
    @IBOutlet weak var WidthSlider: UISlider!
}
