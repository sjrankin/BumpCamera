//
//  LaplacianSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class LaplacianSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.MPSLaplacian)
        
        let Bias = ParameterManager.GetDouble(From: FilterID, Field: .Bias, Default: 0.5)
        BiasValue.text = "\(Bias.Round(To: 2))"
        BiasSlider.value = Float(Bias * 1000.0)
    }
    
    @IBAction func HandleBiasChanged(_ sender: Any)
    {
        let SliderValue = Double(BiasSlider.value / 1000.0)
        BiasValue.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .Bias)
        ShowSampleView()
    }
    
    @IBOutlet weak var BiasSlider: UISlider!
    @IBOutlet weak var BiasValue: UILabel!
}
