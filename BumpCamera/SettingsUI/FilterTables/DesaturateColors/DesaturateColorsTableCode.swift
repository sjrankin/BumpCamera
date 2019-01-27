//
//  DesaturateColorsTableCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/26/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class DesaturateColorsTableCode: FilterTableBase
{
    let Filter = FilterManager.FilterTypes.DesaturateColors
    var FilterID: UUID? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
        FilterID = FilterManager.FilterMap[Filter]
        let DeSatAny = ParameterManager.GetField(From: FilterID!, Field: FilterManager.InputFields.Normal)
        var WorkingDeSat: Double = 0.8
        if let Raw = DeSatAny as? Double
        {
            WorkingDeSat = Raw
        }
        DeSatInput.text = "\(WorkingDeSat.Round(To: 2))"
        DeSatSlider.value = Float(WorkingDeSat) * 1000.0
        
        DeSatSlider.addTarget(self, action: #selector(SliderDoneSliding),
                              for: [.touchUpInside, .touchUpOutside])
        DeSatSlider.addTarget(self, action: #selector(SliderStartSlider),
                              for: [.touchDragInside, .touchDragOutside])
        
        //Create a keyboard button bar that contains a button that lets the user finish editing cleanly.
        if KeyboardBar == nil
        {
            KeyboardBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 50))
            KeyboardBar?.barStyle = .default
            let FlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let KeyboardDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self,
                                                     action: #selector(KeyboardDoneButtonHandler))
            KeyboardBar?.sizeToFit()
            KeyboardBar?.items = [FlexSpace, KeyboardDoneButton]
        }
        DeSatInput.inputAccessoryView = KeyboardBar
    }
    
    @IBOutlet weak var DeSatSlider: UISlider!
    
    @objc func SliderDoneSliding()
    {
        SliderTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                           selector: #selector(UpdateFromSlider),
                                           userInfo: nil, repeats: false)
    }
    
    @objc func SliderStartSlider()
    {
        if SliderTimer != nil
        {
            SliderTimer?.invalidate()
            SliderTimer = nil
        }
    }
    
    @IBAction func HandleSliderValueChanged(_ sender: Any)
    {
        let SliderRaw = DeSatSlider.value
        let NewValue = SliderRaw / 1000.0
        DeSatInput.text = "\(NewValue.Round(To: 2))"
    }
    
    @objc func UpdateFromSlider()
    {
        SliderTimer?.invalidate()
        SliderTimer = nil
        let SliderRaw = DeSatSlider.value
        let NewValue = SliderRaw / 1000.0
        DeSatInput.text = "\(NewValue.Round(To: 2))"
        UpdateSettings(WithValue: NewValue)
    }
    
    var SliderTimer: Timer? = nil
    
    var KeyboardBar: UIToolbar?
    
    @objc func KeyboardDoneButtonHandler()
    {
        view.endEditing(true)
        FinalizeInput(TextBox: DeSatInput)
    }
    
    @IBAction func HandleDeSatChanged(_ sender: Any)
    {
        view.endEditing(true)
        FinalizeInput(TextBox: DeSatInput)
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
                DeSatSlider.value = NewSliderValue
                UpdateSettings(WithValue: Raw)
            }
        }
        else
        {
            SetDefaultValue(To: 0.8, ForTextBox: TextBox, ForSlider: DeSatSlider)
        }
    }
    
    func SetDefaultValue(To: Float, ForTextBox: UITextField, ForSlider: UISlider)
    {
        ForTextBox.text = "\(To)"
        ForSlider.value = Float(To * 1000.0)
    }
    
    @IBOutlet weak var DeSatInput: UITextField!
    
    //https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    
    func UpdateSettings(WithValue: Float)
    {
        let DVal = Double(WithValue).Clamp(0.0, 1.0)
        ParameterManager.SetField(To: FilterID!,
                                  Field: FilterManager.InputFields.Normal,
                                  Value: DVal as Any?)
        ParentDelegate?.NewRawValue()
    }
}
