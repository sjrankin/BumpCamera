//
//  HighlightPixelsCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/16/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HighlightPixelsCode: FilterSettingUIBase, UIPickerViewDelegate, UIPickerViewDataSource
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.PixellateMetal, IsChildDialog: true)
        
        HighlightPixelSelector.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .PixellationHighlighting, Default: 3)
        OriginalGroupActionFrame = HighlightSelector.frame
        OriginalTitleLabelFrame = HighlightPixelLabel.frame
        EnableIfFrame = HighlightIfGreaterSwitch.frame
        HighlightSliderFrame = HighlightSlider.frame
        HighlightValueFrame = HighlightValueLabel.frame
        ActionsTitleFrame = ActionsLabel.frame
        
        let HighlightValue = ParameterManager.GetDouble(From: FilterID, Field: .PixelHighlightActionValue, Default: 0.5)
        HighlightValueLabel.text = "\(HighlightValue.Round(To: 2))"
        HighlightSlider.value = Float(HighlightValue * 1000.0)
        HighlightIfGreaterSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .PixelHighlightActionIfGreater, Default: true)
        
        HighlightSelector.delegate = self
        HighlightSelector.dataSource = self
        HighlightSelector.reloadAllComponents()
        
        let HAction = ParameterManager.GetInt(From: FilterID, Field: .PixelHighlightAction, Default: 0)
        HighlightSelector.selectRow(HAction, inComponent: 0, animated: true)
        
        SetUI(Show: HighlightPixelSelector.selectedSegmentIndex != 3)
    }
    
    var ActionsTitleFrame: CGRect!
    var OriginalTitleLabelFrame: CGRect!
    var EnableIfFrame: CGRect!
    var HighlightSliderFrame: CGRect!
    var HighlightValueFrame: CGRect!
    var OriginalGroupActionFrame: CGRect!
    let HighlightOptions =
        [
            "Convert to grayscale",
            "Set to transparent",
            "Set to black",
            "Set to white",
            "Set to gray",
            "Invert color",
            "Invert hue",
            "Set brightness to max",
            "Set saturation to max",
            "Outline pixel",
            "Swap R & B",
    ]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return HighlightOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return HighlightOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        print("Selected action: \(row)")
        UpdateValue(WithValue: row, ToField: .PixelHighlightAction)
        ShowSampleView()
    }
    
    var IsShowing = true
    
    func SetUI(Show: Bool)
    {
        if Show && IsShowing
        {
            return
        }
        if !Show && !IsShowing
        {
            return
        }
        IsShowing = Show
        if Show
        {
            #if true
            UIView.animate(withDuration: 0.15, animations:
                {
                    self.HighlightSelector.alpha = 1.0
                    self.HighlightPixelLabel.alpha = 1.0
                    self.HighlightIfGreaterSwitch.alpha = 1.0
                    self.HighlightSlider.alpha = 1.0
                    self.HighlightValueLabel.alpha = 1.0
                    self.ActionsLabel.alpha = 1.0
            })
            #else
            UIView.animate(withDuration: 0.15, delay: 0.0,
                           usingSpringWithDamping: 0.4, initialSpringVelocity: 0.8,
                           options: [.curveEaseOut],
                           animations: {
                            self.HighlightSelector.frame = self.OriginalGroupActionFrame
                            self.HighlightPixelLabel.frame = self.OriginalTitleLabelFrame
                            self.HighlightIfGreaterSwitch.frame = self.EnableIfFrame
                            self.HighlightSlider.frame = self.HighlightSliderFrame
                            self.HighlightValueLabel.frame = self.HighlightValueFrame
                            self.ActionsLabel.frame = self.ActionsTitleFrame
            })
            #endif
        }
        else
        {
            #if true
            UIView.animate(withDuration: 0.25, animations:
                {
                    self.HighlightSelector.alpha = 0.0
                    self.HighlightPixelLabel.alpha = 0.0
                    self.HighlightIfGreaterSwitch.alpha = 0.0
                    self.HighlightSlider.alpha = 0.0
                    self.HighlightValueLabel.alpha = 0.0
                    self.ActionsLabel.alpha = 0.0
            })
            #else
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn],
                           animations: {
                            self.HighlightSelector.frame = CGRect(x: -1000, y: self.OriginalGroupActionFrame.minY,
                                                                  width: self.OriginalGroupActionFrame.width,
                                                                  height: self.OriginalGroupActionFrame.height)
                            self.HighlightPixelLabel.frame = CGRect(x: -1000, y: self.OriginalTitleLabelFrame.minY,
                                                                    width: self.OriginalTitleLabelFrame.width,
                                                                    height: self.OriginalTitleLabelFrame.height)
                            self.HighlightIfGreaterSwitch.frame = CGRect(x: -1000, y: self.EnableIfFrame.minY,
                                                                 width: self.EnableIfFrame.width,
                                                                 height: self.EnableIfFrame.height)
                            self.HighlightSlider.frame = CGRect(x: -1000, y: self.HighlightSliderFrame.minY,
                                                                width: self.HighlightSliderFrame.width,
                                                                height: self.HighlightSliderFrame.height)
                            self.HighlightValueLabel.frame = CGRect(x: -1000, y: self.HighlightValueFrame.minY,
                                                                    width: self.HighlightValueFrame.width,
                                                                    height: self.HighlightValueFrame.height)
                            self.ActionsLabel.frame = CGRect(x: -1000, y: self.ActionsTitleFrame.minY,
                                                             width: self.ActionsTitleFrame.width,
                                                             height: self.ActionsTitleFrame.height)
            })
            #endif
        }
    }
    
    @IBAction func HandleHighlightSliderChanged(_ sender: Any)
    {
        let SliderValue = Double(HighlightSlider.value / 1000.0)
        HighlightValueLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .PixelHighlightActionValue)
        ShowSampleView()
    }
    
    @IBAction func HandleHighlightPixelChanged(_ sender: Any)
    {
        let Selector = HighlightPixelSelector.selectedSegmentIndex
        print("Highlight selector: \(Selector)")
        UpdateValue(WithValue: Selector, ToField: .PixellationHighlighting)
        ShowSampleView()
        SetUI(Show: Selector != 3)
    }
    
    @IBAction func HandleHighlightIfGreaterChanged(_ sender: Any)
    {
        UpdateValue(WithValue: HighlightIfGreaterSwitch.isOn, ToField: .PixelHighlightActionIfGreater)
        ShowSampleView()
    }
    
    @IBOutlet weak var HighlightIfGreaterSwitch: UISwitch!
    @IBOutlet weak var ActionsLabel: UILabel!
    @IBOutlet weak var HighlightSelector: UIPickerView!
    @IBOutlet weak var HighlightPixelLabel: UILabel!
    @IBOutlet weak var HighlightValueLabel: UILabel!
    @IBOutlet weak var HighlightSlider: UISlider!
    @IBOutlet weak var HighlightPixelSelector: UISegmentedControl!
}
