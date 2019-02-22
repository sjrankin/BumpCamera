//
//  HSBFilterSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/31/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HSBFilterSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

        Initialize(FilterType: FilterManager.FilterTypes.HSBAdjust)
        
        SatSlider.addTarget(self, action: #selector(SatDoneSliding), for: [.touchUpInside, .touchUpOutside])
        let SatVal = ParameterManager.GetDouble(From: FilterID, Field: .InputSaturation, Default: 1.0)
        SatSlider.value = Float(SatVal) * 1000.0
        SaturationInput.text = "\(SatVal.Round(To: 2))"
        
        ConSlider.addTarget(self, action: #selector(ConDoneSliding), for: [.touchUpInside, .touchUpOutside])
        let ConVal = ParameterManager.GetDouble(From: FilterID, Field: .InputCContrast, Default: 1.0)
        ConSlider.value = Float(ConVal) * 1000.0
        ContrastInput.text = "\(ConVal.Round(To: 2))"
        
        BriSlider.addTarget(self, action: #selector(BriDoneSliding), for: [.touchUpInside, .touchUpOutside])
        let BriVal = ParameterManager.GetDouble(From: FilterID, Field: .InputBrightness, Default: 1.0)
        BriSlider.value = Float(BriVal) * 1000.0
        BrightnessInput.text = "\(BriVal.Round(To: 2))"
        
        SaturationInput.inputAccessoryView = MakeToolbarForKeyboard(ActionSelection: #selector(SatInputDone))
        ContrastInput.inputAccessoryView = MakeToolbarForKeyboard(ActionSelection: #selector(ConInputDone))
        BrightnessInput.inputAccessoryView = MakeToolbarForKeyboard(ActionSelection: #selector(BriInputDone))
    }
    
    @objc func SatInputDone()
    {
        view.endEditing(true)
        CoordinateChange(SaturationInput, SatSlider, 2.0, .InputSaturation)
    }
    
    @objc func ConInputDone()
    {
        view.endEditing(true)
        CoordinateChange(ContrastInput, ConSlider, 1.0, .InputCContrast)
    }
    
    @objc func BriInputDone()
    {
        view.endEditing(true)
        CoordinateChange(BrightnessInput, BriSlider, 1.0, .InputBrightness)
    }
    
    @IBAction func HandleSaturationInputDone(_ sender: Any)
    {
        view.endEditing(true)
        CoordinateChange(SaturationInput, SatSlider, 2.0, .InputSaturation)
    }
    
    @IBAction func HandleContrastInputDone(_ sender: Any)
    {
        view.endEditing(true)
        CoordinateChange(ContrastInput, ConSlider, 1.0, .InputCContrast)
    }
    
    @IBAction func HandleBrightnessInputDone(_ sender: Any)
    {
        view.endEditing(true)
        CoordinateChange(BrightnessInput, BriSlider, 1.0, .InputBrightness)
    }
    
    func CoordinateChange(_ TextBox: UITextField, _ Slider: UISlider, _ Max: Double, _ Field: FilterManager.InputFields)
    {
        let ValidatedValue = ValidateValue(TextBox, Slider, Max)
        Slider.value = Float(ValidatedValue) * 1000.0
        UpdateValue(WithValue: ValidatedValue, ToField: Field)
    }
    
    func ValidateValue(_ From: UITextField, _ Slider: UISlider, _ Max: Double) -> Double
    {
        if let Raw = From.text
        {
            if let RawNumber = Double(Raw)
            {
                if RawNumber < 0.0
                {
                    ForceDefault(From, Slider, To: 0.0)
                    return 0.0
                }
                if RawNumber > Max
                {
                    ForceDefault(From, Slider, To: Max)
                    return Max
                }
                return RawNumber
            }
            else
            {
                ForceDefault(From, Slider, To: 1.0)
                return 1.0
            }
        }
        else
        {
            ForceDefault(From, Slider, To: 1.0)
            return 1.0
        }
    }
    
    func ForceDefault(_ TextBox: UITextField, _ Slider: UISlider, To: Double)
    {
        TextBox.text = "\(To.Round(To: 2))"
        Slider.value = Float(To) * 1000.0
    }
    
    @objc func SatDoneSliding()
    {
        let SliderValue: Double = Double(SatSlider.value / 1000.0)
        SaturationInput.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: Double(SliderValue), ToField: .InputSaturation)
        ShowSampleView()
    }
    
    @objc func ConDoneSliding()
    {
        let SliderValue: Double = Double(ConSlider.value / 1000.0)
        ContrastInput.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: Double(SliderValue), ToField: .InputCContrast)
        ShowSampleView()
    }
    
    @objc func BriDoneSliding()
    {
        let SliderValue: Double = Double(BriSlider.value / 1000.0)
        BrightnessInput.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: Double(SliderValue), ToField: .InputBrightness)
        ShowSampleView()
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleSaturationSliderChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(SatSlider.value / 1000.0)
        SaturationInput.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBAction func HandleContrastSliderChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(ConSlider.value / 1000.0)
        ContrastInput.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBAction func HandleBrightnessSliderChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(BriSlider.value / 1000.0)
        BrightnessInput.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBOutlet weak var BrightnessInput: UITextField!
    @IBOutlet weak var ContrastInput: UITextField!
    @IBOutlet weak var SaturationInput: UITextField!
    @IBOutlet weak var BriSlider: UISlider!
    @IBOutlet weak var ConSlider: UISlider!
    @IBOutlet weak var SatSlider: UISlider!
}
