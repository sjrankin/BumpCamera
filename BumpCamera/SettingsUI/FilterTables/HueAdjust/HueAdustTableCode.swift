//
//  HueAdustTableCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HueAdjustTableCode: FilterTableBase
{
    let Filter = FilterManager.FilterTypes.HueAdjust
    var FilterID: UUID? = nil
    let _Settings = UserDefaults.standard
    let SmallestAngle: Float = 0.0
    let LargestAngle: Float = 360.0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ColorHueCell")
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        FilterID = FilterManager.FilterInfoMap[Filter]!.0
        let RawAsAny = ParameterManager.GetField(From: FilterID!, Field: FilterManager.InputFields.Angle)
        var WorkingRaw: Double = 0.0
        if let Raw = RawAsAny as? Double
        {
            WorkingRaw = (Raw * 360.0)
        }
        HueInputTextBox.text = "\(WorkingRaw.Round(To: 1))"
        HueSlider.value = 10.0 * Float(WorkingRaw)
        
        //https://stackoverflow.com/questions/9390298/iphone-how-to-detect-the-end-of-slider-drag
        HueSlider.addTarget(self, action: #selector(SliderDoneSliding), for: [.touchUpInside, .touchUpOutside])
        
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
        HueInputTextBox.inputAccessoryView = KeyboardBar
    }
    
    var KeyboardBar: UIToolbar?
    
    @objc func KeyboardDoneButtonHandler()
    {
        view.endEditing(true)
        FinalizeHueInput(TextBox: HueInputTextBox)
    }
    
    @objc func SliderDoneSliding()
    {
        let SliderRaw = HueSlider.value
        let NewValue = SliderRaw / 10.0
        HueInputTextBox.text = "\(NewValue.Round(To: 1))"
        UpdateSettings(WithValue: NewValue)
    }
    
    //https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    
    @IBAction func HandleHueInputChanged(_ sender: Any)
    {
        FinalizeHueInput(TextBox: sender as! UITextField)
    }
    
    func FinalizeHueInput(TextBox: UITextField)
    {
        if let RawS = HueInputTextBox.text
        {
            if var Raw = Float(RawS)
            {
                if Raw < Float(SmallestAngle)
                {
                    Raw = Float(SmallestAngle)
                    HueInputTextBox.text = "\(Raw.Round(To: 1))"
                }
                if Raw > Float(LargestAngle)
                {
                    Raw = Float(LargestAngle)
                    HueInputTextBox.text = "\(Raw.Round(To: 1))"
                }
                let NewSliderValue = Float(Raw * 10.0)
                HueSlider.value = NewSliderValue
                UpdateSettings(WithValue: Raw)
            }
        }
        else
        {
            SetDefaultHue(To: 180.0)
        }
    }
    
    func SetDefaultHue(To: Float)
    {
        HueInputTextBox.text = "\(To)"
        HueSlider.value = Float(To * 10.0)
        UpdateSettings(WithValue: To)
    }
    
    @IBOutlet weak var HueInputTextBox: UITextField!
    
    @IBOutlet weak var HueSlider: UISlider!
    
    func UpdateSettings(WithValue: Float)
    {
        var NewSize: Double = Double(WithValue)
        NewSize = NewSize / 360.0
        ParameterManager.SetField(To: FilterID!,
                                  Field: FilterManager.InputFields.Angle,
                                  Value: NewSize as Any?)
        ParentDelegate?.NewRawValue()
    }
}
