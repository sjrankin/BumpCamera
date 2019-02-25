//
//  HalftoneSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/31/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Code to run settings for all half-tone related CIFilters.
class HalftoneSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var WorkingType: FilterManager.FilterTypes!
        let TypeVal = _Settings.integer(forKey: "SetupForFilterType")
        if let VariableType: FilterManager.FilterTypes = FilterManager.FilterTypes(rawValue: TypeVal)
        {
            WorkingType = VariableType
        }
        else
        {
            WorkingType = FilterManager.FilterTypes.LineScreen
        }
        let FilterTitle = FilterManager.GetFilterTitle(WorkingType)
        title = FilterTitle! + " Settings"
        Initialize(FilterType: WorkingType)
        
        PopulateUI()
        AngleSlider.addTarget(self, action: #selector(AngleDoneSliding), for: [.touchUpInside, .touchUpOutside])
        WidthSlider.addTarget(self, action: #selector(WidthDoneSliding), for: [.touchUpInside, .touchUpOutside])
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
        super.viewWillDisappear(animated)
    }
    
    /// Populate the UI with saved values.
    func PopulateUI()
    {
        let W = ParameterManager.GetDouble(From: FilterID, Field: .Width, Default: 10.0)
        let A = ParameterManager.GetDouble(From: FilterID, Field: .Angle, Default: 90.0)
        let Merge = ParameterManager.GetBool(From: FilterID, Field: .MergeWithBackground, Default: true)
        let Adjust = ParameterManager.GetBool(From: FilterID, Field: .AdjustInLandscape, Default: true)
        
        WidthLabel.text = "\(W.Round(To: 1))"
        WidthSlider.value = Float(W) * 10.0
        AngleLabel.text = "\(A.Round(To: 1))°"
        AngleSlider.value = Float(A) * 10.0
        MergeWithOriginalSwitch.isOn = Merge
        AdjustForLandscapeSwitch.isOn = Adjust
    }
    
    @objc func AngleDoneSliding()
    {
        let SliderValue: Double = Double(AngleSlider.value / 10.0)
        AngleLabel.text = "\(SliderValue.Round(To: 1))°"
        UpdateValue(WithValue: SliderValue, ToField: .Angle)
        ShowSampleView()
    }
    
    @objc func WidthDoneSliding()
    {
        let SliderValue: Double = Double(WidthSlider.value / 10.0)
        WidthLabel.text = "\(SliderValue.Round(To: 1))"
        UpdateValue(WithValue: SliderValue, ToField: .Width)
        ShowSampleView()
    }
    
    @IBAction func HandleAngleSliderChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(AngleSlider.value / 10.0)
        AngleLabel.text = "\(SliderValue.Round(To: 1))°"
        UpdateValue(WithValue: SliderValue, ToField: .Angle)
        ShowSampleView()
    }
    
    @IBAction func HandleWidthSliderChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(WidthSlider.value / 10.0)
        WidthLabel.text = "\(SliderValue.Round(To: 1))"
        UpdateValue(WithValue: SliderValue, ToField: .Width)
        ShowSampleView()
    }
    
    @IBAction func HandleMergeWithOriginalChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeWithOriginalSwitch.isOn, ToField: .MergeWithBackground)
        ShowSampleView()
    }
    
    @IBAction func HandleAdjustForLandscapeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: AdjustForLandscapeSwitch.isOn, ToField: .AdjustInLandscape)
        ShowSampleView()
    }
    
    @IBOutlet weak var AngleLabel: UILabel!
    @IBOutlet weak var WidthLabel: UILabel!
    @IBOutlet weak var WidthSlider: UISlider!
    @IBOutlet weak var AngleSlider: UISlider!
    @IBOutlet weak var MergeWithOriginalSwitch: UISwitch!
    @IBOutlet weak var AdjustForLandscapeSwitch: UISwitch!
    
    @IBAction func HandleBackButtonPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomeButtonPressed(_ sender: Any)
    {
    }
}
