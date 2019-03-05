//
//  ChannelManglerSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ChannelManglerSettingsUICode: FilterSettingUIBase, UIPickerViewDelegate, UIPickerViewDataSource
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.ChannelMangler)
        ChannelManglingPicker.delegate = self
        ChannelManglingPicker.dataSource = self
        ChannelManglingPicker.reloadAllComponents()
        let SelectedRow = ParameterManager.GetInt(From: FilterID, Field: .ChannelManglerAction, Default: 0)
        ChannelManglingPicker.selectRow(SelectedRow, inComponent: 0, animated: true)
    }
    
    let MangleTypes: [Int: String] =
        [
            0: "NOP",
            1: "Channel Max Other",
            2: "Channel Min Other",
            3: "Channel + Mean Other",
            4: "Max Channel Inverted",
            5: "Min Channel Inverted",
            6: "Transpose Red",
            7: "Transpose Green",
            8: "Transpose Blue",
            9: "Transpose Cyan",
            10: "Transpose Magenta",
            11: "Transpose Yellow",
            12: "Transpose Black",
            13: "Inverted Hue",
            14: "Inverted Saturation",
            15: "Inverted Brightness",
            16: "Ranged Hue",
            17: "Ranged Saturation",
            18: "Ranged Brightness",
    ]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return MangleTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return MangleTypes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        UpdateValue(WithValue: row, ToField: .ChannelManglerAction)
        ShowSampleView()
    }
    
    @IBOutlet weak var ChannelManglingPicker: UIPickerView!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
}
