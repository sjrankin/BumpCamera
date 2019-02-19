//
//  PixellateTableCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class PixellateTableCode: FilterTableBase
{
    let Filter = FilterManager.FilterTypes.Pixellate
    var FilterID: UUID!
    let _Settings = UserDefaults.standard
    var BlockSizeKey = ""
    let SmallestBlockSize = 8
    let LargestBlockSize = 96
    var SetSliderMultiplier: Float = 1.0
    var GetSliderMultiplier: Float = 1.0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let RawAsAny = ParameterManager.GetField(From: FilterManager.FilterInfoMap[Filter]!.0, Field: FilterManager.InputFields.Width)
        var WorkingRaw: Double = 0.0
        if let Raw = RawAsAny as? Double
        {
            WorkingRaw = Raw - Double(SmallestBlockSize)
        }
        PixelSizeTextBlock.text = "\(WorkingRaw.Round(To: 1))"
        SetSliderMultiplier = SliderSetMultiplier(Low: SmallestBlockSize, High: LargestBlockSize)
        GetSliderMultiplier = 1.0 / SetSliderMultiplier
        PixelSizeSlider.value = SetSliderMultiplier * Float(WorkingRaw)
        
        //https://stackoverflow.com/questions/9390298/iphone-how-to-detect-the-end-of-slider-drag
        PixelSizeSlider.addTarget(self, action: #selector(SliderDoneSliding), for: [.touchUpInside, .touchUpOutside])
        
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
        PixelSizeTextBlock.inputAccessoryView = KeyboardBar
    }
    
    var KeyboardBar: UIToolbar?
    
    @objc func KeyboardDoneButtonHandler()
    {
        view.endEditing(true)
        FinalizePixelInput(TextBox: PixelSizeTextBlock)
    }
    
    //https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    
    func SliderSetMultiplier(Low: Int, High: Int) -> Float
    {
        let Range: Float = Float(High - Low + 1)
        return Float(1000.0) / Range
    }
    
    @objc func SliderDoneSliding()
    {
        let SliderRaw = PixelSizeSlider.value
        let NewValue = (SliderRaw * GetSliderMultiplier) + Float(SmallestBlockSize)
        PixelSizeTextBlock.text = "\(NewValue.Round(To: 1))"
        UpdateSettings(WithValue: NewValue)
    }
    
    @IBOutlet weak var PixelSizeSlider: UISlider!
    
    @IBAction func HandlePixelSizeTextBlockChanged(_ sender: Any)
    {
        FinalizePixelInput(TextBox: sender as! UITextField)
    }
    
    func FinalizePixelInput(TextBox: UITextField)
    {
        if let RawS = PixelSizeTextBlock.text
        {
            if var Raw = Float(RawS)
            {
                if Raw < Float(SmallestBlockSize)
                {
                    Raw = Float(SmallestBlockSize)
                    PixelSizeTextBlock.text = "\(Raw.Round(To: 1))"
                }
                if Raw > Float(LargestBlockSize)
                {
                    Raw = Float(LargestBlockSize)
                    PixelSizeTextBlock.text = "\(Raw.Round(To: 1))"
                }
                let NewSliderValue = Float((Raw - Float(SmallestBlockSize)) * SetSliderMultiplier)
                PixelSizeSlider.value = NewSliderValue
                UpdateSettings(WithValue: Raw)
            }
        }
        else
        {
            SetDefaultBlockSize(To: 20.0)
        }
    }
    
    func SetDefaultBlockSize(To: Float)
    {
        PixelSizeTextBlock.text = "\(To)"
        PixelSizeSlider.value = Float((To - Float(SmallestBlockSize)) * SetSliderMultiplier)
        UpdateSettings(WithValue: To)
    }
    
    @IBOutlet weak var PixelSizeTextBlock: UITextField!
    
    func UpdateSettings(WithValue: Float)
    {
        let NewSize: Double = Double(WithValue)
        ParameterManager.SetField(To: FilterManager.FilterInfoMap[Filter]!.0,
                                  Field: FilterManager.InputFields.Width, Value: NewSize as Any?)
        ParentDelegate?.NewRawValue()
    }
}
