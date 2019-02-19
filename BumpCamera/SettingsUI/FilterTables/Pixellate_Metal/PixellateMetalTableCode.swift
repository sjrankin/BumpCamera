//
//  PixellateMetalTableCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/29/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class PixellateMetalTableCode: FilterTableBase
{
    let Filter = FilterManager.FilterTypes.PixellateMetal
    var FilterID: UUID!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
        FilterID = FilterManager.FilterInfoMap[Filter]!.0
        
        //https://stackoverflow.com/questions/9390298/iphone-how-to-detect-the-end-of-slider-drag
        WidthSlider.addTarget(self, action: #selector(WidthDoneSliding), for: [.touchUpInside, .touchUpOutside])
        HeightSlider.addTarget(self, action: #selector(HeightDoneSliding), for: [.touchUpInside, .touchUpOutside])
        
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
        WidthInput.inputAccessoryView = KeyboardBar
        HeightInput.inputAccessoryView = KeyboardBar
        
        let WidthAsAny = ParameterManager.GetField(From: FilterID, Field: .BlockWidth)
        var FinalWidth: Int = 20
        if let SomeWidth = WidthAsAny as? Int
        {
            FinalWidth = SomeWidth
        }
        WidthInput.text = "\(FinalWidth)"
        WidthSlider.value = Float(FinalWidth) * 50.0
        
        let HeightAsAny = ParameterManager.GetField(From: FilterID, Field: .BlockHeight)
        var FinalHeight: Int = 20
        if let SomeHeight = HeightAsAny as? Int
        {
            FinalHeight = SomeHeight
        }
        HeightInput.text = "\(FinalHeight)"
        HeightSlider.value = Float(FinalHeight) * 50.0
    }
    
    var KeyboardBar: UIToolbar?
    
    @objc func KeyboardDoneButtonHandler()
    {
        view.endEditing(true)
    }
    
    @objc func WidthDoneSliding()
    {
        let SliderValue: Int = Int(WidthSlider.value / 50.0)
        WidthInput.text = "\(SliderValue)"
        UpdateBoth()
    }
    
    @objc func HeightDoneSliding()
    {
        let SliderValue: Int = Int(HeightSlider.value / 50.0)
        HeightInput.text = "\(SliderValue)"
        UpdateBoth()
    }
    
    func UpdateBoth()
    {
        let Width = GetValue(From: WidthInput, WidthSlider)
        let Height = GetValue(From: HeightInput, HeightSlider)
        UpdateSettings(WithWidth: Width, WithHeight: Height)
    }
    
    func GetValue(From: UITextField, _ Slider: UISlider) -> Int
    {
        if let Raw = From.text
        {
            if let IVal = Int(Raw)
            {
                if IVal < 0
                {
                    SetDefault(From, With: Slider, To: 0)
                    return 0
                }
                if IVal > 100
                {
                    SetDefault(From, With: Slider, To: 100)
                }
                return IVal
            }
            else
            {
                SetDefault(From, With: Slider, To: 20)
                return 20
            }
        }
        else
        {
            SetDefault(From, With: Slider, To: 20)
            return 20
        }
    }
    
    func SetDefault(_ TextBox: UITextField, With: UISlider, To: Int)
    {
        TextBox.text = "\(To)"
        With.value = Float(To) * 50.0
    }
    
    @IBAction func HandleWidthSliderChanged(_ sender: Any)
    {
        view.endEditing(true)
        let SliderValue: Int = Int(WidthSlider.value / 50.0)
        WidthInput.text = "\(SliderValue)"
    }
    
    @IBAction func HandleHeightSliderChanged(_ sender: Any)
    {
        view.endEditing(true)
        let SliderValue: Int = Int(WidthSlider.value / 50.0)
        WidthInput.text = "\(SliderValue)"
    }
    
    @IBAction func HandleWidthChanged(_ sender: Any)
    {
        let NewWidth = GetValue(From: WidthInput, WidthSlider)
        WidthSlider.value = Float(NewWidth) * 50.0
        UpdateBoth()
    }
    
    @IBAction func HandleHeightChanged(_ sender: Any)
    {
        let NewHeight = GetValue(From: HeightInput, HeightSlider)
        HeightSlider.value = Float(NewHeight) * 50.0
        UpdateBoth()
    }
    
    @IBOutlet weak var HeightSlider: UISlider!
    @IBOutlet weak var WidthSlider: UISlider!
    @IBOutlet weak var WidthInput: UITextField!
    @IBOutlet weak var HeightInput: UITextField!
    
    func UpdateSettings(WithWidth: Int, WithHeight: Int)
    {
        ParameterManager.SetField(To: FilterID, Field: .BlockWidth, Value: WithWidth as Any?)
        ParameterManager.SetField(To: FilterID, Field: .BlockHeight, Value: WithHeight as Any?)
        ParentDelegate?.NewRawValue()
    }
}
