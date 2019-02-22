//
//  SolarizeSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class SolarizeSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Solarize)
        InitializeSlider(ThresholdSlider, Action: #selector(ThresholdSliderStoppedSliding))
        InitializeSlider(SaturationSlider, Action: #selector(SaturationSliderStoppedSliding))
        InitializeSlider(BrightnessSlider, Action: #selector(BrightnessSliderStoppedSliding))
        SetupUI()
    }
    
    func SetupUI()
    {
        let How = ParameterManager.GetInt(From: FilterID, Field: .SolarizeMethod, Default: 0)
        SetEnabledState(How)
        
        switch How
        {
        case 0:
            ChannelThresholdSwitch.isOn = true
            
        case 1:
            SaturationThresholdSwitch.isOn = true
            
        case 2:
            BrightnessThresholdSwitch.isOn = true
            
        case 3:
            HueRangeThresholdSwitch.isOn = true
            
        default:
            break
        }
        
        let IfGreater = ParameterManager.GetBool(From: FilterID, Field: .SolarizeIfGreater, Default: false)
        SolarizeIfGreaterSwitch.isOn = IfGreater
        
        let TValue = ParameterManager.GetDouble(From: FilterID, Field: .SolarizeThreshold, Default: 0.5)
        ThresholdValue.text = "\(TValue.Round(To: 2))"
        ThresholdSlider.value = Float(TValue * 1000.0)
        
        let SValue = ParameterManager.GetDouble(From: FilterID, Field: .SaturationThreshold, Default: 0.5)
        SaturationValue.text = "\(SValue.Round(To: 2))"
        SaturationSlider.value = Float(SValue * 1000.0)
        
        let BValue = ParameterManager.GetDouble(From: FilterID, Field: .BrightnessThreshold, Default: 0.5)
        BrightnessValue.text = "\(BValue.Round(To: 2))"
        BrightnessSlider.value = Float(BValue * 1000.0)
        
        let HLow = ParameterManager.GetDouble(From: FilterID, Field: .HueRangeLow, Default: 0.25)
        RangeLowLabel.text = "\(HLow.Round(To: 2) * 360.0)"
        LowSlider.value = Float(HLow * 1000.0)
        
        let HHigh = ParameterManager.GetDouble(From: FilterID, Field: .HueRangeHigh, Default: 0.75)
        RangeHighLabel.text = "\(HHigh.Round(To: 2) * 360.0)"
        HighSlider.value = Float(HHigh * 1000.0)
    }
    
    func SetEnabledState(_ Method: Int)
    {
        ThresholdValue.isEnabled = (Method == 0)
        ThresholdValueLabel.isEnabled = (Method == 0)
        ThresholdSlider.isEnabled = (Method == 0)
        
        SaturationSlider.isEnabled = (Method == 1)
        SaturationValue.isEnabled = (Method == 1)
        SaturationValueLabel.isEnabled = (Method == 1)
        
        BrightnessSlider.isEnabled = (Method == 2)
        BrightnessValue.isEnabled = (Method == 2)
        BrightnessValueLabel.isEnabled = (Method == 2)
        
        LowLabel.isEnabled = (Method == 3)
        HighLabel.isEnabled = (Method == 3)
        LowSlider.isEnabled = (Method == 3)
        HighSlider.isEnabled = (Method == 3)
        RangeLowLabel.isEnabled = (Method == 3)
        RangeHighLabel.isEnabled = (Method == 3)
    }
    
    func UpdateSwitches(_ OnSwitch: UISwitch)
    {
        if ChannelThresholdSwitch != OnSwitch
        {
            ChannelThresholdSwitch.isOn = false
        }
        if SaturationThresholdSwitch != OnSwitch
        {
            SaturationThresholdSwitch.isOn = false
        }
        if BrightnessThresholdSwitch != OnSwitch
        {
            BrightnessThresholdSwitch.isOn = false
        }
        if HueRangeThresholdSwitch != OnSwitch
        {
            HueRangeThresholdSwitch.isOn = false
        }
    }
    
    func InitializeSlider(_ Slider: UISlider, Action: Selector)
    {
        Slider.addTarget(self, action: Action, for: [.touchUpInside, .touchUpOutside])
    }
    
    @objc func ThresholdSliderStoppedSliding()
    {
        let SliderValue = ThresholdSlider.value / 1000.0
        ThresholdValue.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: Double(SliderValue), ToField: .SolarizeThreshold)
        ShowSampleView()
    }
    
    @IBAction func HandleThresholdSliderChanged(_ sender: Any)
    {
        let SliderValue = ThresholdSlider.value / 1000.0
        ThresholdValue.text = "\(SliderValue.Round(To: 2))"
    }
    
    @objc func SaturationSliderStoppedSliding()
    {
        let SliderValue = SaturationSlider.value / 1000.0
        SaturationValue.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: Double(SliderValue), ToField: .SaturationThreshold)
        ShowSampleView()
    }
    
    @IBAction func HandleSaturationSliderChanged(_ sender: Any)
    {
        let SliderValue = SaturationSlider.value / 1000.0
        SaturationValue.text = "\(SliderValue.Round(To: 2))"
    }
    
    @objc func BrightnessSliderStoppedSliding()
    {
        let SliderValue = BrightnessSlider.value / 1000.0
        BrightnessValue.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: Double(SliderValue), ToField: .BrightnessThreshold)
        ShowSampleView()
    }
    
    @IBAction func HandleBrightnessSliderChanged(_ sender: Any)
    {
        let SliderValue = BrightnessSlider.value / 1000.0
        BrightnessValue.text = "\(SliderValue.Round(To: 2))"
    }
    
    func UpdateHueRange(FromLow: Bool)
    {
        var LowValue = LowSlider.value / 1000.0
        var HighValue = HighSlider.value / 1000.0
        if FromLow
        {
            if LowValue > HighValue
            {
                HighValue = LowValue
                HighSlider.value = LowValue * 1000.0
            }
        }
        else
        {
            if HighValue < LowValue
            {
                LowValue = HighValue
                LowSlider.value = HighValue * 1000.0
            }
        }
        RangeHighLabel.text = "\(HighValue.Round(To: 2))"
        RangeLowLabel.text = "\(LowValue.Round(To: 2))"
        UpdateValue(WithValue: Double(HighValue), ToField: .HueRangeHigh)
        UpdateValue(WithValue: Double(LowValue), ToField: .HueRangeLow)
        ShowSampleView()
    }
    
    @objc func LowSliderStoppedSliding()
    {
        UpdateHueRange(FromLow: true)
    }
    
    @IBAction func HandleLowSliderChanged(_ sender: Any)
    {
        UpdateHueRange(FromLow: true)
    }
    
    @objc func HighSliderStoppedSliding()
    {
        UpdateHueRange(FromLow: false)
    }
    
    @IBAction func HandleHighSliderChanged(_ sender: Any)
    {
        UpdateHueRange(FromLow: false)
    }
    
    @IBAction func HandleUseHueSwitchChanged(_ sender: Any)
    {
        if HueRangeThresholdSwitch.isOn
        {
            UpdateSwitches(HueRangeThresholdSwitch)
        }
        SetEnabledState(3)
        UpdateValue(WithValue: 3, ToField: .SolarizeMethod)
        ShowSampleView()
    }
    
    @IBAction func HandleUseSaturationSwitchChanged(_ sender: Any)
    {
        if SaturationThresholdSwitch.isOn
        {
            UpdateSwitches(SaturationThresholdSwitch)
        }
        SetEnabledState(1)
        UpdateValue(WithValue: 1, ToField: .SolarizeMethod)
        ShowSampleView()
    }
    
    @IBAction func HandleUseBrightnessSwitchChanged(_ sender: Any)
    {
        if BrightnessThresholdSwitch.isOn
        {
            UpdateSwitches(BrightnessThresholdSwitch)
        }
        SetEnabledState(2)
        UpdateValue(WithValue: 2, ToField: .SolarizeMethod)
        ShowSampleView()
    }
    
    @IBAction func HandleUseThresholdSwitchChanged(_ sender: Any)
    {
        if ChannelThresholdSwitch.isOn
        {
            UpdateSwitches(ChannelThresholdSwitch)
        }
        SetEnabledState(0)
        UpdateValue(WithValue: 0, ToField: .SolarizeMethod)
        ShowSampleView()
    }
    
    @IBAction func HandleSolarizeIfGreaterChanged(_ sender: Any)
    {
        UpdateValue(WithValue: SolarizeIfGreaterSwitch.isOn, ToField: .SolarizeIfGreater)
        ShowSampleView()
    }
    
    @IBOutlet weak var ChannelThresholdSwitch: UISwitch!
    @IBOutlet weak var SaturationThresholdSwitch: UISwitch!
    @IBOutlet weak var BrightnessThresholdSwitch: UISwitch!
    @IBOutlet weak var HueRangeThresholdSwitch: UISwitch!
    @IBOutlet weak var SolarizeIfGreaterSwitch: UISwitch!
    
    @IBOutlet weak var LowSlider: UISlider!
    @IBOutlet weak var HighSlider: UISlider!
    @IBOutlet weak var BrightnessSlider: UISlider!
    @IBOutlet weak var SaturationSlider: UISlider!
    @IBOutlet weak var ThresholdSlider: UISlider!
    
    @IBOutlet weak var HighLabel: UILabel!
    @IBOutlet weak var LowLabel: UILabel!
    @IBOutlet weak var RangeLowLabel: UILabel!
    @IBOutlet weak var RangeHighLabel: UILabel!
    @IBOutlet weak var BrightnessValueLabel: UILabel!
    @IBOutlet weak var BrightnessValue: UILabel!
    @IBOutlet weak var SaturationValue: UILabel!
    @IBOutlet weak var SaturationValueLabel: UILabel!
    @IBOutlet weak var ThresholdValue: UILabel!
    @IBOutlet weak var ThresholdValueLabel: UILabel!
    
    @IBAction func HandleCameraHomeButton(_ sender: Any)
    {
    }
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
}
