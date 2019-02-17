//
//  SepiaToneSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/16/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class SepiaToneSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.SepiaTone)
        LevelSlider.addTarget(self, action: #selector(SliderStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        let Level = ParameterManager.GetDouble(From: FilterID, Field: .SepiaToneLevel, Default: 1)
        LevelValueLabel.text = "\(Level.Round(To: 2))"
        LevelSlider.value = Float(Level * 1000.0)
    }
    
    @objc func SliderStoppedSliding()
    {
        let SliderValue = Double(LevelSlider.value / 1000.0)
        LevelValueLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .SepiaToneLevel)
        ShowSampleView()
    }
    
    @IBAction func HandleLevelSliderChanged(_ sender: Any)
    {
        let SliderValue = Double(LevelSlider.value / 1000.0)
        LevelValueLabel.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBOutlet weak var LevelSlider: UISlider!
    @IBOutlet weak var LevelValueLabel: UILabel!
    
    @IBAction func HandleBackButotn(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
}
