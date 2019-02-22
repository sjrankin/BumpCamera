//
//  DesaturateSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class DesaturateSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        Initialize(FilterType: FilterManager.FilterTypes.DesaturateColors)
        DesatSlider.addTarget(self, action: #selector(SliderDoneSliding), for: [.touchUpInside, .touchUpOutside])
        let DesatValue = ParameterManager.GetDouble(From: FilterID, Field: .Normal, Default: 1.0)
        DesatSlider.value = Float(DesatValue) * 1000.0
        DesatInput.text = ToString(DesatValue, ToPlace: 2)
        MakeToolbarForKeyboard(For: DesatInput, ActionSelection: #selector(KeyboardDoneButtonHandler))
    }
    
    @objc func SliderDoneSliding()
    {
        let SliderRaw = DesatSlider.value
        let NewValue = SliderRaw / 1000.0
        DesatInput.text = "\(NewValue.Round(To: 2))"
        UpdateValue(WithValue: Double(NewValue), ToField: .Normal)
        ShowSampleView()
    }
    
    @IBAction func HandleDesatSliderChanged(_ sender: Any)
    {
        let SliderRaw = DesatSlider.value
        let NewValue = SliderRaw / 1000.0
        DesatInput.text = "\(NewValue.Round(To: 2))"
    }
    
    @objc func KeyboardDoneButtonHandler()
    {
        view.endEditing(true)
        FinalizeInput(TextBox: DesatInput)
    }
    
    func FinalizeInput(TextBox: UITextField)
    {
        if let RawS = TextBox.text
        {
            if var Raw = Float(RawS)
            {
                if Raw < 0.0
                {
                    Raw = 0.0
                    TextBox.text = "\(Raw.Round(To: 2))"
                }
                if Raw > 1.0
                {
                    Raw = 1.0
                    TextBox.text = "\(Raw.Round(To: 2))"
                }
                let NewSliderValue = Float(Raw * 1000.0)
                DesatSlider.value = NewSliderValue
                UpdateValue(WithValue: Double(NewSliderValue), ToField: .Normal)
                ShowSampleView()
            }
        }
        else
        {
            SetDefaultValue(To: 0.8, ForTextBox: TextBox, ForSlider: DesatSlider)
        }
    }
    
    func SetDefaultValue(To: Float, ForTextBox: UITextField, ForSlider: UISlider)
    {
        ForTextBox.text = "\(To)"
        ForSlider.value = Float(To * 1000.0)
    }
    
    //https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    
    @IBAction func HandleDesatInputChanged(_ sender: Any)
    {
        self.view.endEditing(true)
        FinalizeInput(TextBox: DesatInput)
    }
    
    @IBOutlet weak var DesatInput: UITextField!
    @IBOutlet weak var DesatSlider: UISlider!
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
    }
}
