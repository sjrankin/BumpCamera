//
//  VibranceSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class VibranceSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Vibrance)
        
        AmountSlider.addTarget(self,
                               action: #selector(SliderStoppedSliding),
                               for: [.touchUpInside, .touchUpOutside])
        let Amount = ParameterManager.GetDouble(From: FilterID, Field: .Amount, Default: 0.0)
        AmountValueLabel.text = "\(Amount.Round(To: 2))"
        AmountSlider.value = Float(Amount * 1000.0)
    }
    
    @objc func SliderStoppedSliding()
    {
        let SliderValue = Double(AmountSlider.value / 1000.0)
        AmountValueLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .Amount)
        ShowSampleView()
    }
    
    @IBAction func HandleAmountSliderChanged(_ sender: Any)
    {
        let SliderValue = Double(AmountSlider.value / 1000.0)
        AmountValueLabel.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBOutlet weak var AmountSlider: UISlider!
    @IBOutlet weak var AmountValueLabel: UILabel!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
}
