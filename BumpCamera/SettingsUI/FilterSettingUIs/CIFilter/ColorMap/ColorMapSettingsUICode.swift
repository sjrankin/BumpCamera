//
//  ColorMapSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorMapSettingsUICode: FilterSettingUIBase, UIPickerViewDelegate, UIPickerViewDataSource
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.ColorMap)
        
        GradientSample.layer.borderColor = UIColor.black.cgColor
        GradientSample.layer.borderWidth = 0.5
        GradientSample.layer.cornerRadius = 5.0
        LoadUIContents()
        
        GradientPicker.delegate = self
        GradientPicker.dataSource = self
    }
    
    func LoadUIContents()
    {
        
    }
    
    let GradientsForPicker: [(String, String)] =
    [
        ("White to Black", "(White)@(0.0),(Black)@(1.0)"),
        ("White to Red", "(White)@(0.0),(Red)@(1.0)"),
        ("White to Green", "(White)@(0.0),(Green)@(1.0)"),
        ("White to Blue", "(White)@(0.0),(Blue)@(1.0)"),
        ("White to Cyan", "(White)@(0.0),(Cyan)@(1.0)"),
        ("White to Magenta", "(White)@(0.0),(Magenta)@(1.0)"),
        ("White to Yellow", "(White)@(0.0),(Yellow)@(1.0)"),
        ("White to Orange", "(White)@(0.0),(Orange)@(1.0)"),
        ("White to Indigo", "(White)@(0.0),(Indigo)@(1.0)"),
        ("White to Violet", "(White)@(0.0),(Violet)@(1.0)"),
        ("Rainbow", "(Red)@(0.0),(Orange)@(0.18),(Yellow)@(0.36),(Green)@(0.52),(Blue)@(0.68),(Indigo)@(0.84),(Violet)@(1.0)")
    ]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return GradientsForPicker.count
    }
    
    @IBOutlet weak var GradientPicker: UIPickerView!
    @IBOutlet weak var GradientSample: UIImageView!
    @IBOutlet weak var InvertGradientSwitch: UISwitch!
}
