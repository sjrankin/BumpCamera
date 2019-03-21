//
//  MPSErodeSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MPSErodeSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.MPSErode)
        
        LockSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .LockDimensions, Default: true)
        let KWidth = ParameterManager.GetInt(From: FilterID, Field: .IWidth, Default: 15)
        let KHeight = ParameterManager.GetInt(From: FilterID, Field: .IHeight, Default: 15)
        
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
        if LockSwitch.isOn
        {
            HeightSlider.value = WidthSlider.value
            HeightValue.text = "\(SliderValue)"
            UpdateValue(WithValue: SliderValue, ToField: .IHeight)
        }
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
        if LockSwitch.isOn
        {
            WidthSlider.value = HeightSlider.value
            HeightValue.text = "\(SliderValue)"
            UpdateValue(WithValue: SliderValue, ToField: .IHeight)
        }
        ShowSampleView()
    }
    
    @IBAction func HandleLockChanged(_ sender: Any)
    {
        UpdateValue(WithValue: LockSwitch.isOn, ToField: .LockDimensions)
    }
    
    @IBOutlet weak var LockSwitch: UISwitch!
    @IBOutlet weak var HeightValue: UILabel!
    @IBOutlet weak var WidthValue: UILabel!
    @IBOutlet weak var HeightSlider: UISlider!
    @IBOutlet weak var WidthSlider: UISlider!
}
