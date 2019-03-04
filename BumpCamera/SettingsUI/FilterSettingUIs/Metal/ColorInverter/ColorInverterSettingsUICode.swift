//
//  ColorInverterSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorInverterSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.ColorInversion)
        
        GroupBox.layer.cornerRadius = 5.0
        GroupBox.layer.borderColor = UIColor.black.cgColor
        GroupBox.layer.borderWidth = 0.5
        
        let Colorspace = ParameterManager.GetInt(From: FilterID, Field: .CIColorspace, Default: 0)
        CurrentColorSpace = Colorspace
        ColorspaceSegment.selectedSegmentIndex = Colorspace
        SwitchToColorSpace(Colorspace)
        SwitchToChannel(1)
        //ShowValuesFor(Channel: 1, InColorspace: Colorspace)
    }
    
    @IBAction func HandleColorspaceChanged(_ sender: Any)
    {
        let Colorspace = ColorspaceSegment.selectedSegmentIndex
        UpdateValue(WithValue: Colorspace, ToField: .CIColorspace)
        ShowSampleView()
        SwitchToColorSpace(Colorspace)
    }
    
    var CurrentColorSpace: Int = -1
    
    func SwitchToColorSpace(_ Colorspace: Int)
    {
        switch Colorspace
        {
        case 0:
            //RGB
            while ChannelSegment.numberOfSegments > 0
            {
                ChannelSegment.removeSegment(at: 0, animated: true)
            }
            ChannelSegment.insertSegment(withTitle: "Red", at: 0, animated: true)
            ChannelSegment.insertSegment(withTitle: "Green", at: 1, animated: true)
            ChannelSegment.insertSegment(withTitle: "Blue", at: 2, animated: true)
            ChannelSegment.insertSegment(withTitle: "Alpha", at: 3, animated: true)
            if CurrentChannel < 1
            {
                SwitchToChannel(1)
            }
            else
            {
                if CurrentChannel > 3
                {
                    CurrentChannel = 3
                }
                SwitchToChannel(CurrentChannel)
            }
            
        case 1:
            //HSB
            while ChannelSegment.numberOfSegments > 0
            {
                ChannelSegment.removeSegment(at: 0, animated: true)
            }
            ChannelSegment.insertSegment(withTitle: "Hue", at: 0, animated: true)
            ChannelSegment.insertSegment(withTitle: "Saturation", at: 1, animated: true)
            ChannelSegment.insertSegment(withTitle: "Brightness", at: 2, animated: true)
            ChannelSegment.insertSegment(withTitle: "Alpha", at: 3, animated: true)
            if CurrentChannel < 1
            {
                SwitchToChannel(1)
            }
            else
            {
                if CurrentChannel > 3
                {
                    CurrentChannel = 3
                }
                SwitchToChannel(CurrentChannel)
            }
            
        case 2:
            //YUV
            while ChannelSegment.numberOfSegments > 0
            {
                ChannelSegment.removeSegment(at: 0, animated: true)
            }
            ChannelSegment.insertSegment(withTitle: "Y", at: 0, animated: true)
            ChannelSegment.insertSegment(withTitle: "U", at: 1, animated: true)
            ChannelSegment.insertSegment(withTitle: "V", at: 2, animated: true)
            ChannelSegment.insertSegment(withTitle: "Alpha", at: 3, animated: true)
            if CurrentChannel < 1
            {
                SwitchToChannel(1)
            }
            else
            {
                if CurrentChannel > 3
                {
                    CurrentChannel = 3
                }
                SwitchToChannel(CurrentChannel)
            }
            
        case 3:
            // CMYK
            while ChannelSegment.numberOfSegments > 0
            {
                ChannelSegment.removeSegment(at: 0, animated: true)
            }
            ChannelSegment.insertSegment(withTitle: "Cyan", at: 0, animated: true)
            ChannelSegment.insertSegment(withTitle: "Magenta", at: 1, animated: true)
            ChannelSegment.insertSegment(withTitle: "Yellow", at: 2, animated: true)
            ChannelSegment.insertSegment(withTitle: "Black", at: 3, animated: true)
            ChannelSegment.insertSegment(withTitle: "Alpha", at: 4, animated: true)
            if CurrentChannel < 1
            {
                SwitchToChannel(1)
            }
            else
            {
                SwitchToChannel(CurrentChannel)
            }
            
        default:
            fatalError("Invalid colorspace encountered: \(Colorspace).")
        }
    }
    
    @IBAction func HandleChannelChanged(_ sender: Any)
    {
        let NewChannel = ChannelSegment.selectedSegmentIndex
        SwitchToChannel(NewChannel + 1)
    }
    
    func SwitchToChannel(_ Channel: Int)
    {
        CurrentChannel = Channel
        ShowValuesFor(Channel: CurrentChannel, InColorspace: CurrentColorSpace)
    }
    
    var CurrentChannel: Int = -1
    
    func ShowValuesFor(Channel: Int, InColorspace: Int)
    {
        let ChannelNameList = ChannelNames[InColorspace]
        InvertChannelLabel.text = "Invert " + ChannelNameList![Channel - 1]
        let DoInvertChannel = ParameterManager.GetBool(From: FilterID, Field: ChannelInversions[Channel - 1], Default: false)
        InvertChannelSwitch.isOn = DoInvertChannel
        let DoEnableThresh = ParameterManager.GetBool(From: FilterID, Field: EnableThresholds[Channel - 1], Default: false)
        EnableChannelThresholdSwitch.isOn = DoEnableThresh
        let DoGreater = ParameterManager.GetBool(From: FilterID, Field: IfGreater[Channel - 1], Default: false)
        ApplyThresholdIfGreaterSwitch.isOn = DoGreater
        let ThreshVal = ParameterManager.GetDouble(From: FilterID, Field: ChannelThresholds[Channel - 1], Default: 0.5)
        ThresholdSlider.value = Float(ThreshVal * 1000.0)
        ThresholdValue.text = "\(ThreshVal.Round(To: 2))"
        ConfigureUI()
    }
    
    func ConfigureUI()
    {
        let EnableThreshold = EnableChannelThresholdSwitch.isOn
        ThresholdTitle.isEnabled = EnableThreshold
        ThresholdSlider.isEnabled = EnableThreshold
        ThresholdValue.isEnabled = EnableThreshold
        IfGreaterTitle.isEnabled = EnableThreshold
        ApplyThresholdIfGreaterSwitch.isEnabled = EnableThreshold
        EnableThresholdTitle.isEnabled = InvertChannelSwitch.isOn
        EnableChannelThresholdSwitch.isEnabled = InvertChannelSwitch.isOn
    }
    
    let ChannelNames: [Int: [String]] =
    [
        0: ["Red", "Green", "Blue"],
        1: ["Hue", "Saturation", "Brightness"],
        2: ["Y", "U", "V"],
        3: ["Cyan", "Magenta", "Yellow", "Black"]
    ]
    
    let ChannelInversions: [FilterManager.InputFields] =
    [.CIInvertChannel1, .CIInvertChannel2, .CIInvertChannel3, .CIInvertChannel4, .CIInvertAlpha]
    
    let ChannelThresholds: [FilterManager.InputFields] =
    [.CIChannel1Threshold, .CIChannel2Threshold, .CIChannel3Threshold, .CIChannel4Threshold, .CIAlphaThreshold]
    
    let EnableThresholds: [FilterManager.InputFields] =
    [.CIEnableChannel1Threshold, .CIEnableChannel2Threshold, .CIEnableChannel3Threshold, .CIEnableChannel4Threshold, .CIEnableAlphaThreshold]
    
    let IfGreater: [FilterManager.InputFields] =
    [.CIChannel1InvertIfGreater, .CIChannel2InvertIfGreater, .CIChannel3InvertIfGreater, .CIChannel4InvertIfGreater, .CIAlphaInvertIfGreater]
    
    @IBAction func HandleInvertChannelChanged(_ sender: Any)
    {
        let DoInvert = InvertChannelSwitch.isOn
        UpdateValue(WithValue: DoInvert, ToField: ChannelInversions[CurrentChannel - 1])
        ShowSampleView()
        ConfigureUI()
    }
    
    @IBAction func HandleEnableThresholdChanged(_ sender: Any)
    {
        let EnableThreshold = EnableChannelThresholdSwitch.isOn
        UpdateValue(WithValue: EnableThreshold, ToField: EnableThresholds[CurrentChannel - 1])
        ShowSampleView()
        ConfigureUI()
    }
    
    @IBAction func HandleApplyIfGreaterChanged(_ sender: Any)
    {
        let DoIfGreater = ApplyThresholdIfGreaterSwitch.isOn
        UpdateValue(WithValue: DoIfGreater, ToField: IfGreater[CurrentChannel - 1])
        ShowSampleView()
    }
    
    @IBAction func HandleThresholdChanged(_ sender: Any)
    {
        let SliderValue = Double(ThresholdSlider.value / 1000.0)
        ThresholdValue.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: ChannelThresholds[CurrentChannel - 1])
        ShowSampleView()
    }
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
    
    @IBOutlet weak var EnableThresholdTitle: UILabel!
    @IBOutlet weak var IfGreaterTitle: UILabel!
    @IBOutlet weak var ThresholdTitle: UILabel!
    @IBOutlet weak var ThresholdSlider: UISlider!
    @IBOutlet weak var ThresholdValue: UILabel!
    @IBOutlet weak var ApplyThresholdIfGreaterSwitch: UISwitch!
    @IBOutlet weak var EnableChannelThresholdSwitch: UISwitch!
    @IBOutlet weak var InvertChannelLabel: UILabel!
    @IBOutlet weak var InvertChannelSwitch: UISwitch!
    @IBOutlet weak var GroupBox: UIView!
    @IBOutlet weak var ChannelSegment: UISegmentedControl!
    @IBOutlet weak var ColorspaceSegment: UISegmentedControl!
}
