//
//  HSBAdjustTableCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HSBAdjustTableCode: FilterTableBase
{
    let Filter = FilterManager.FilterTypes.HSBAdjust
    var FilterID: UUID!
    let _Settings = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        FilterID = FilterManager.FilterMap[Filter]
        
        ContrastSlider.addTarget(self, action: #selector(ContrastDoneSliding), for: [.touchUpInside, .touchUpOutside])
        BrightnessSlider.addTarget(self, action: #selector(BrightnessDoneSliding), for: [.touchUpInside, .touchUpOutside])
        SaturationSlider.addTarget(self, action: #selector(SaturationDoneSliding), for: [.touchUpInside, .touchUpOutside])
        
        
        SKeyboardBar = MakeToolbarForKeyboard(ActionSelection: #selector(SKeyboardDoneButtonHandler))
        SaturationBox.inputAccessoryView = SKeyboardBar
        CKeyboardBar = MakeToolbarForKeyboard(ActionSelection: #selector(SKeyboardDoneButtonHandler))
        ContrastBox.inputAccessoryView = CKeyboardBar
        BKeyboardBar = MakeToolbarForKeyboard(ActionSelection: #selector(SKeyboardDoneButtonHandler))
        BrightnessBox.inputAccessoryView = BKeyboardBar
        
        InitializeUIContents()
    }
    
    func MakeToolbarForKeyboard(ActionSelection: Selector) -> UIToolbar
    {
        //Create a keyboard button bar that contains a button that lets the user finish editing cleanly.
        let KeyboardBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 50))
        KeyboardBar.barStyle = .default
        let FlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let KeyboardDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self,
                                                 action: ActionSelection)
        KeyboardBar.sizeToFit()
        KeyboardBar.items = [FlexSpace, KeyboardDoneButton]
        return KeyboardBar
    }
    
    var SKeyboardBar: UIToolbar?
    var CKeyboardBar: UIToolbar?
    var BKeyboardBar: UIToolbar?
    
    //https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    
    func InitializeUIContents()
    {
        let SatAsAny = ParameterManager.GetField(From: FilterID, Field: FilterManager.InputFields.InputSaturation)
        var WorkingSat = 1.0
        if let Sat = SatAsAny as? Double
        {
            WorkingSat = Sat
        }
        SaturationBox.text = "\(WorkingSat.Round(To: 1))"
        SaturationSlider.value = Float(WorkingSat * 1000.0)
        
        let ConAsAny = ParameterManager.GetField(From: FilterID, Field: FilterManager.InputFields.InputCContrast)
        var WorkingCon = 1.0
        if let Con = ConAsAny as? Double
        {
            WorkingCon = Con
        }
        ContrastBox.text = "\(WorkingCon.Round(To: 1))"
        ContrastSlider.value = Float(WorkingCon * 1000.0)
        
        let BriAsAny = ParameterManager.GetField(From: FilterID, Field: FilterManager.InputFields.InputBrightness)
        var WorkingBri = 1.0
        if let Bri = BriAsAny as? Double
        {
            WorkingBri = Bri
        }
        BrightnessBox.text = "\(WorkingBri.Round(To: 1))"
        BrightnessSlider.value = Float(WorkingBri * 1000.0)
    }
    
    @objc func ContrastDoneSliding()
    {
        let SliderRaw = ContrastSlider.value
        let NewValue = SliderRaw / 1000.0
        ContrastBox.text = "\(NewValue.Round(To: 1))"
        UpdateSettings(WithValue: NewValue, Field: FilterManager.InputFields.InputCContrast)
    }
    
    @objc func BrightnessDoneSliding()
    {
        let SliderRaw = BrightnessSlider.value
        let NewValue = SliderRaw / 1000.0
        BrightnessBox.text = "\(NewValue.Round(To: 1))"
        UpdateSettings(WithValue: NewValue, Field: FilterManager.InputFields.InputBrightness)
    }
    
    @objc func SaturationDoneSliding()
    {
        let SliderRaw = SaturationSlider.value
        let NewValue = SliderRaw / 1000.0
        SaturationBox.text = "\(NewValue.Round(To: 1))"
        UpdateSettings(WithValue: NewValue, Field: FilterManager.InputFields.InputSaturation)
    }
    
    func GetTextField(_ TextBox: UITextField) -> FilterManager.InputFields
    {
        if TextBox == SaturationBox
        {
            return FilterManager.InputFields.InputSaturation
        }
        if TextBox == ContrastBox
        {
            return FilterManager.InputFields.InputCContrast
        }
        return FilterManager.InputFields.InputBrightness
    }
    
    func FinalizeInput(TextBox: UITextField, AssociatedSlider: UISlider, MinValue: Double, MaxValue: Double)
    {
        if let RawS = TextBox.text
        {
            if var Raw = Double(RawS)
            {
                if Raw < 0.0
                {
                    Raw = 0.0
                }
                if Raw > Double(AssociatedSlider.maximumValue / 1000.0)
                {
                    Raw = Double(AssociatedSlider.maximumValue)
                }
                let NewSliderValue = Raw * 1000.0
                AssociatedSlider.value = Float(NewSliderValue)
                TextBox.text = "\(Raw.Round(To: 1))"
                UpdateSettings(WithValue: Float(Raw), Field: GetTextField(TextBox))
            }
            else
            {
                SetDefault(TextBox, AssociatedSlider, To: 1.0)
            }
        }
        else
        {
            SetDefault(TextBox, AssociatedSlider, To: 1.0)
        }
    }
    
    func SetDefault(_ InputBox: UITextField, _ Slider: UISlider, To: Double)
    {
        let RawString = "\(To.Round(To: 1))"
        InputBox.text = RawString
        Slider.value = Float(To * 1000.0)
        UpdateSettings(WithValue: Float(To), Field: GetTextField(InputBox))
    }
    
    @objc func SKeyboardDoneButtonHandler()
    {
        FinalizeInput(TextBox: SaturationBox, AssociatedSlider: SaturationSlider, MinValue: 0.0, MaxValue: 2.0)
    }
    
    @objc func BKeyboardDoneButtonHandler()
    {
        FinalizeInput(TextBox: BrightnessBox, AssociatedSlider: BrightnessSlider, MinValue: 0.0, MaxValue: 1.0)
    }
    
    @objc func CKeyboardDoneButtonHandler()
    {
        FinalizeInput(TextBox: ContrastBox, AssociatedSlider: ContrastSlider, MinValue: 0.0, MaxValue: 1.0)
    }
    
    @IBAction func SaturationBoxChanged(_ sender: Any)
    {
        FinalizeInput(TextBox: SaturationBox, AssociatedSlider: SaturationSlider, MinValue: 0.0, MaxValue: 2.0)
    }
    
    @IBAction func ContrastBoxChanged(_ sender: Any)
    {
        FinalizeInput(TextBox: ContrastBox, AssociatedSlider: ContrastSlider,MinValue: 0.0, MaxValue: 1.0)
    }
    
    @IBAction func BrightnessBoxChanged(_ sender: Any)
    {
        FinalizeInput(TextBox: BrightnessBox, AssociatedSlider: SaturationSlider, MinValue: 0.0, MaxValue: 1.0)
    }
    
    @IBOutlet weak var SaturationBox: UITextField!
    
    @IBOutlet weak var SaturationSlider: UISlider!
    
    @IBOutlet weak var ContrastBox: UITextField!
    
    @IBOutlet weak var ContrastSlider: UISlider!
    
    @IBOutlet weak var BrightnessBox: UITextField!
    
    @IBOutlet weak var BrightnessSlider: UISlider!
    
    func UpdateSettings(WithValue: Float, Field: FilterManager.InputFields)
    {
        let NewSize: Double = Double(WithValue)
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: Field, Value: NewSize as Any?)
        ParentDelegate?.NewRawValue()
    }
}
