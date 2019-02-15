//
//  DilateErodeSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/14/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class DilateErodeSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.DilateErode)
        let WindowSize = ParameterManager.GetInt(From: FilterID, Field: .WindowSize, Default: 5)
        WindowSizeSlider.value = Float(WindowSize * 100)
        WindowSizeLabel.text = "\(WindowSize)"
        WindowSizeSlider.addTarget(self, action: #selector(SliderStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        let ValDet = ParameterManager.GetInt(From: FilterID, Field: .ValueDetermination, Default: 0)
        SetValueDetermination(ValDet)
    }
    
    func SetValueDetermination(_ Value: Int)
    {
        if Value >= 0 && Value <= 2
        {
            RGBSegment.selectedSegmentIndex = Value
            HSBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
            CMYKSegment.selectedSegmentIndex = UISegmentedControl.noSegment
            return
        }
        if Value >= 3 && Value <= 5
        {
            RGBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
            HSBSegment.selectedSegmentIndex = Value - 3
            CMYKSegment.selectedSegmentIndex = UISegmentedControl.noSegment
            return
        }
        RGBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        HSBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        CMYKSegment.selectedSegmentIndex = Value - 6
    }
    
    @IBAction func HandleOperationChanged(_ sender: Any)
    {
        let NewOp = [0: 1, 1: 0][OperationSegment.selectedSegmentIndex]
        UpdateValue(WithValue: NewOp!, ToField: .Operation)
        ShowSampleView()
    }
    
    @IBOutlet weak var OperationSegment: UISegmentedControl!
    
    @objc func SliderStoppedSliding()
    {
        var SliderValue = Int(WindowSizeSlider.value / 100.0)
        if SliderValue % 2 == 0
        {
            SliderValue = SliderValue + 1
            if SliderValue > Int(WindowSizeSlider.maximumValue)
            {
                SliderValue = SliderValue - 2
            }
        }
        WindowSizeLabel.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .WindowSize)
        ShowSampleView()
    }
    
    @IBAction func HandleWindowSizeChanged(_ sender: Any)
    {
    }
    
    @IBOutlet weak var WindowSizeSlider: UISlider!
    
    @IBOutlet weak var WindowSizeLabel: UILabel!
    
    
    @IBAction func HandleRGBChanged(_ sender: Any)
    {
        HSBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
                CMYKSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        let ValDet = RGBSegment.selectedSegmentIndex
        SetValueDetermination(ValDet)
        UpdateValue(WithValue: ValDet, ToField: .ValueDetermination)
        ShowSampleView()
    }
    
    @IBAction func HandleHSBChanged(_ sender: Any)
    {
        RGBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        CMYKSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        let ValDet = HSBSegment.selectedSegmentIndex + 3
        SetValueDetermination(ValDet)
        UpdateValue(WithValue: ValDet, ToField: .ValueDetermination)
        ShowSampleView()
    }
    
    @IBAction func HandleCMYKChanged(_ sender: Any)
    {
        HSBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        RGBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        let ValDet = CMYKSegment.selectedSegmentIndex + 6
        SetValueDetermination(ValDet)
        UpdateValue(WithValue: ValDet, ToField: .ValueDetermination)
        ShowSampleView()
    }
    
    @IBOutlet weak var RGBSegment: UISegmentedControl!
    @IBOutlet weak var HSBSegment: UISegmentedControl!
    @IBOutlet weak var CMYKSegment: UISegmentedControl!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomeButton(_ sender: Any)
    {
    }
}
