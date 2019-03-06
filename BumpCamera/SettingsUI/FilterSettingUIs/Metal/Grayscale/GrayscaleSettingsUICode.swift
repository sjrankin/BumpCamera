//
//  GrayscaleSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GrayscaleSettingsUICode: FilterSettingUIBase, UIPickerViewDelegate, UIPickerViewDataSource
{
    var TypesInOrder: [GrayscaleTypes] = GrayscaleAdjust.GrayscaleTypesInOrder()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        Initialize(FilterType: FilterManager.FilterTypes.GrayscaleKernel)
        let FilterTitle = FilterManager.GetFilterTitle(Filter)
        title = "Settings for " + FilterTitle!
        
        GrayPicker.delegate = self
        GrayPicker.dataSource = self
        GrayPicker.reloadAllComponents()
        
        var GType = 0
        let RawGType = ParameterManager.GetField(From: FilterID!, Field: FilterManager.InputFields.Command)
        if let IGtype = RawGType as? Int
        {
            GType = IGtype
        }
        SelectGrayscaleType(Index: GType)
    }
    
    func numberOfComponents(in picerkView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return GrayscaleAdjust.GrayscaleTypesInOrder().count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        let GType = TypesInOrder[row]
        let Title = GrayscaleAdjust.GrayscaleTypeTitle(For: GType)
        return Title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        let NewType = TypesInOrder[row]
        let Description = GrayscaleAdjust.GrayscaleTypeDescription(For: NewType)
        GrayscaleDescription.text = Description
        UpdateValue(WithValue: NewType.rawValue, ToField: .Command)
        ShowSampleView()
    }

    func SelectGrayscaleType(Index: Int)
    {
        let GType = GrayscaleAdjust.GetGrayscaleTypeFromCommandIndex(Index)
        let PIndex = TypesInOrder.firstIndex(of: GType)
        GrayPicker.selectRow(PIndex!, inComponent: 0, animated: true)
        let Description = GrayscaleAdjust.GrayscaleTypeDescription(For: GType)
        GrayscaleDescription.text = Description
    }
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var GrayscaleDescription: UILabel!
    @IBOutlet weak var GrayPicker: UIPickerView!
}
