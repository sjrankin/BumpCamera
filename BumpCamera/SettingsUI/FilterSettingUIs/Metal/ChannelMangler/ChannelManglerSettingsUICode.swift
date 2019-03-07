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
        let Description = MangleTypes[SelectedRow]?.1
        ManglerExplanation.text = Description
    }
    
    let MangleTypes: [Int: (String, String)] =
        [
            0: ("NOP", "No changes made to the image."),
            1: ("Channel Max Other", "Each channel's value becomes the maximum of the other two channels."),
            2: ("Channel Min Other", "Each channel's value becomes the minimum of the other two channels."),
            3: ("Channel + Mean Other", "Channel values become (channel value + Mean(other two channels)) / 2"),
            4: ("Max Channel Inverted", "The channel with the greatest value is inverted. The other two are used as is."),
            5: ("Min Channel Inverted", "The channel with the smallest value is inverted. The other two are used as is."),
            6: ("Transpose Red", "The red channel values is obtained from the transposed pixel."),
            7: ("Transpose Green", "The green channel values is obtained from the transposed pixel."),
            8: ("Transpose Blue", "The blue channel values is obtained from the transposed pixel."),
            9: ("Transpose Cyan", "The cyan channel values is obtained from the transposed pixel."),
            10: ("Transpose Magenta", "The magenta channel values is obtained from the transposed pixel."),
            11: ("Transpose Yellow", "The yellow channel values is obtained from the transposed pixel."),
            12: ("Transpose Black", "The black channel values is obtained from the transposed pixel."),
            13: ("Transpose Hue", "The hue channel values is obtained from the transposed pixel."),
            14: ("Transpose Saturation", "The saturation channel values is obtained from the transposed pixel."),
            15: ("Transpose Brightness", "The brightness channel values is obtained from the transposed pixel."),
            16: ("Ranged Hue", "The hue value is constrained to an equal range within 360°."),
            17: ("Ranged Saturation", "The saturation value is constrained to an equal range."),
            18: ("Ranged Brightness", "The brightness value is constrained to an equal range."),
            19: ("Red + X:8", "The red channel value is obtained 8 horizontal pixels to the right (and down if near the right edge)."),
            20: ("Green + X:8", "The green channel value is obtained 8 horizontal pixels to the right (and down if near the right edge)."),
            21: ("Blue + X:8", "The blue channel value is obtained 8 horizontal pixels to the right (and down if near the right edge)."),
            22: ("3x3 Red Mean", "The red channel is set to the mean of the 3x3 grid with the current pixel as the center."),
            23: ("3x3 Green Mean", "The green channel is set to the mean of the 3x3 grid with the current pixel as the center."),
            24: ("3x3 Blue Mean", "The blue channel is set to the mean of the 3x3 grid with the current pixel as the center."),
            25: ("Largest Mean Channel", "Each channel is set to the greatest mean value of the red, green, or blue channels."),
            26: ("Smallest Mean Channel", "Each channel is set to the smallest mean value of the red, green, or blue channels."),
            27: ("Mask with 0xfe", "Each channel value is converted to 0...255 then masked with 0xfe."),
            28: ("Mask with 0xfc", "Each channel value is converted to 0...255 then masked with 0xfc."),
            29: ("Mask with 0xf8", "Each channel value is converted to 0...255 then masked with 0xf8."),
            30: ("Mask with 0xf0", "Each channel value is converted to 0...255 then masked with 0xf0."),
            31: ("Mask with 0xe0", "Each channel value is converted to 0...255 then masked with 0xe0."),
            32: ("Mask with 0xc0", "Each channel value is converted to 0...255 then masked with 0xc0."),
            33: ("Mask with 0x80", "Each channel value is converted to 0...255 then masked with 0x80."),
            34: ("Compact Shift Low", "Each channel has all bits compressed such that there are no 0s, then shifted right."),
            35: ("Compact Shift High", "Each channel has all bits compressed such that there are no 0s, then shifted left."),
            36: ("Reverse Bits", "Each channe's bits are reversed."),
            37: ("Red xor Green Blue", "The green and blue channel values are xored with the red channel."),
            38: ("Green xor Red blue", "The red and blue channel values are xored with the green channel."),
            39: ("Blue xor Red Green", "The red and green channel values are xored with the blue channel."),
            40: ("Multi-Xored", "Each channel is xored with the xor of the other two channels."),
            41: ("Xor-Or", "Each channel is xored with the another channel ored with the third channel."),
            42: ("Xor-And", "Each channel is xored with the another channel anded with the third channel."),
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
        return MangleTypes[row]?.0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        let Description = MangleTypes[row]?.1
        ManglerExplanation.text = Description
        UpdateValue(WithValue: row, ToField: .ChannelManglerAction)
        ShowSampleView()
    }
    
    @IBOutlet weak var ManglerExplanation: UILabel!
    @IBOutlet weak var ChannelManglingPicker: UIPickerView!
}
