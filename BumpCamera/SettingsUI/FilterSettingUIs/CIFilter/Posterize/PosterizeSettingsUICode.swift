//
//  PosterizeSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/16/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class PosterizeSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Posterize)
        LevelSlider.addTarget(self, action: #selector(SliderStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        let Level = ParameterManager.GetInt(From: FilterID, Field: .PosterizeLevel, Default: 6)
        LevelValueLabel.text = "\(Level)"
        LevelSlider.value = Float(Level * 100)
    }
    
    @objc func SliderStoppedSliding()
    {
        let SliderValue = Int(LevelSlider.value / 100.0)
        LevelValueLabel.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .PosterizeLevel)
        ShowSampleView()
    }
    
    @IBAction func HandleLevelSliderChanged(_ sender: Any)
    {
        let SliderValue = Int(LevelSlider.value / 100.0)
        LevelValueLabel.text = "\(SliderValue)"
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
