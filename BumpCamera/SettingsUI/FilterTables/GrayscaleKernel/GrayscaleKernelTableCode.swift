//
//  GrayscaleKernelTableCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GrayscaleKernelTableCode: FilterTableBase, UIPickerViewDelegate, UIPickerViewDataSource
{
    let Filter = FilterManager.FilterTypes.GrayscaleKernel
    var FilterID: UUID? = nil
    var TypesInOrder: [GrayscaleTypes] = GrayscaleAdjust.GrayscaleTypesInOrder()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
            self.tableView.tableFooterView = UIView()
        
                FilterID = FilterManager.FilterMap[Filter]
        
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
        RedInput.inputAccessoryView = KeyboardBar
        GreenInput.inputAccessoryView = KeyboardBar
        BlueInput.inputAccessoryView = KeyboardBar
    
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
        
        var RVal = 0.3
        let RawRVal = ParameterManager.GetField(From: FilterID!, Field: FilterManager.InputFields.RAdjustment)
        if let RawR = RawRVal as? Double
        {
            RVal = RawR
        }
        RedInput.text = "\(RVal.Round(To: 4))"
        
        var GVal = 0.5
        let RawGVal = ParameterManager.GetField(From: FilterID!, Field: FilterManager.InputFields.GAdjustment)
        if let RawG = RawGVal as? Double
        {
            GVal = RawG
        }
        GreenInput.text = "\(GVal.Round(To: 4))"
        
        var BVal = 0.2
        let RawBVal = ParameterManager.GetField(From: FilterID!, Field: FilterManager.InputFields.BAdjustment)
        if let RawB = RawBVal as? Double
        {
            BVal = RawB
        }
        BlueInput.text = "\(BVal.Round(To: 4))"
    }
    
    var KeyboardBar: UIToolbar? = nil
    
    @objc func KeyboardDoneButtonHandler()
    {
        
    }
    
    @IBAction func HandleRedChanged(_ sender: Any)
    {
    }
    
    @IBAction func HandleGreenChanged(_ sender: Any)
    {
    }
    
    @IBAction func HandleBluechanged(_ sender: Any)
    {
        
    }
    
    func UpdateSettings(WithValue: Int, Field: FilterManager.InputFields)
    {
        print("Sending new value: \(WithValue)")
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: Field, Value: WithValue as Any?)
        ParentDelegate?.NewRawValue()
    }
    
    func UpdateSettings(WithValue: Double, Field: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: Field, Value: WithValue as Any?)
        ParentDelegate?.NewRawValue()
    }
    @IBOutlet weak var RedInput: UITextField!
    @IBOutlet weak var GreenInput: UITextField!
    @IBOutlet weak var BlueInput: UITextField!
    @IBOutlet weak var GrayPicker: UIPickerView!
    @IBOutlet weak var GrayTypeDescription: UILabel!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
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
        GrayTypeDescription.text = Description
        UpdateSettings(WithValue: NewType.rawValue, Field: FilterManager.InputFields.Command)
    }
    
    func SelectGrayscaleType(Index: Int)
    {
        let GType = GrayscaleAdjust.GetGrayscaleTypeFromCommandIndex(Index)
        let PIndex = TypesInOrder.index(of: GType)
        GrayPicker.selectRow(PIndex!, inComponent: 0, animated: true)
        let Description = GrayscaleAdjust.GrayscaleTypeDescription(For: GType)
        GrayTypeDescription.text = Description
    }
}
