//
//  EdgeWorkSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/12/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class EdgeWorkSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.EdgeWork)
        RadiusSlider.addTarget(self, action: #selector(SliderStoppedSliding), for: [.touchUpOutside, .touchUpInside])
        MergeSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .MergeWithBackground, Default: true)
        let SliderVal = ParameterManager.GetDouble(From: FilterID, Field: .Radius, Default: 3.0)
        RadiusSlider.value = Float(SliderVal * 100.0)
        RadiusValue.text = "\(SliderVal.Round(To: 2))"
        ShowSampleView()
    }

    @objc func SliderStoppedSliding()
    {
        let SliderVal = Double(RadiusSlider.value / 100.0)
        RadiusValue.text = "\(SliderVal.Round(To: 2))"
        UpdateValue(WithValue: SliderVal, ToField: .Radius)
        ShowSampleView()
    }
    
    @IBAction func HandleRadiusSliderChanged(_ sender: Any)
    {
        let SliderVal = Double(RadiusSlider.value / 100.0)
        RadiusValue.text = "\(SliderVal.Round(To: 2))"
    }
    
    @IBAction func HandleMergeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeSwitch.isOn, ToField: .MergeWithBackground)
        ShowSampleView()
    }
    
    @IBOutlet weak var RadiusValue: UILabel!
    @IBOutlet weak var RadiusSlider: UISlider!
    @IBOutlet weak var MergeSwitch: UISwitch!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHome(_ sender: Any)
    {
    }
}
