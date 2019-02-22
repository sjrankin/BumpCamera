//
//  PointillizeSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/22/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class PointillizeSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Pointillize)
        RadiusSlider.addTarget(self,
                               action: #selector(RadiusSliderStoppedSliding),
                               for: [.touchUpInside, .touchUpOutside])
        
        MergeButton.isOn = ParameterManager.GetBool(From: FilterID, Field: .MergeWithBackground, Default: true)
        SetUI(MergeButton.isOn)
        let Radius = ParameterManager.GetDouble(From: FilterID, Field: .Radius, Default: 20.0)
        RadiusValueLabel.text = "\(Int(Radius))"
        RadiusSlider.value = Float(Radius * 100)
        let BGType = ParameterManager.GetInt(From: FilterID, Field: .BackgroundType, Default: 0)
        BackgroundSegment.selectedSegmentIndex = BGType
    }
    
    func SetUI(_ Merge: Bool)
    {
        BackgroundLabel.isEnabled = Merge
        BackgroundSegment.isEnabled = Merge
    }
    
    @objc func RadiusSliderStoppedSliding()
    {
        let SliderValue: Int = Int(RadiusSlider.value / 100.0)
        RadiusValueLabel.text = "\(SliderValue)"
        UpdateValue(WithValue: Double(SliderValue), ToField: .Radius)
        ShowSampleView()
    }
    
    @IBAction func HandleRadiusSliderChanged(_ sender: Any)
    {
        let SliderValue: Int = Int(RadiusSlider.value / 100.0)
        RadiusValueLabel.text = "\(SliderValue)"
    }
    
    @IBAction func HandleBackgroundChanged(_ sender: Any)
    {
        let BGType = BackgroundSegment.selectedSegmentIndex
        UpdateValue(WithValue: BGType, ToField: .BackgroundType)
        ShowSampleView()
    }
    
    @IBOutlet weak var RadiusSlider: UISlider!
    @IBOutlet weak var RadiusValueLabel: UILabel!
    @IBOutlet weak var BackgroundLabel: UILabel!
    @IBOutlet weak var BackgroundSegment: UISegmentedControl!
    
    @IBAction func HandleMergeChanged(_ sender: Any)
    {
        let DoMerge = MergeButton.isOn
        SetUI(DoMerge)
        UpdateValue(WithValue: DoMerge, ToField: .MergeWithBackground)
        ShowSampleView()
    }
    
    @IBOutlet weak var MergeButton: UISwitch!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
}
