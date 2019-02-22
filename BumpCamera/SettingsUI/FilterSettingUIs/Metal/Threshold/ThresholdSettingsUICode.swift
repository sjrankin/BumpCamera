//
//  ThresholdSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ThresholdSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Threshold)
        ThresholdSlider.addTarget(self, action: #selector(SliderStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        let TValue = ParameterManager.GetDouble(From: FilterID, Field: .ThresholdValue, Default: 0.5)
        ThresholdSlider.value = Float(TValue * 1000.0)
        ThresholdValue.text = "\(TValue.Round(To: 2))"
        ApplyIfGreaterSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .ApplyThresholdIfHigher, Default: false)
        ThresholdInputRGB.selectedSegmentIndex = UISegmentedControl.noSegment
        ThresholdInputHSB.selectedSegmentIndex = UISegmentedControl.noSegment
        ThresholdInputCMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        let InputType = ParameterManager.GetInt(From: FilterID, Field: .ThresholdInput, Default: 0)
        SetThresholdInput(InputType)
        LowColors[LowColor0] = [UIColor.black, UIColor.blue, UIColor.brown, UIColor.cyan]
        LowColors[LowColor1] = [UIColor.darkGray, UIColor.gray, UIColor.green, UIColor.lightGray]
        LowColors[LowColor2] = [UIColor.magenta, UIColor.orange, UIColor.purple, UIColor.red]
        LowColors[LowColor3] = [UIColor.white, UIColor.yellow, UIColor(named: "Gold"), UIColor(named: "Pistachio")] as? [UIColor]
        HighColors[HighColor0] = [UIColor.black, UIColor.blue, UIColor.brown, UIColor.cyan]
        HighColors[HighColor1] = [UIColor.darkGray, UIColor.gray, UIColor.green, UIColor.lightGray]
        HighColors[HighColor2] = [UIColor.magenta, UIColor.orange, UIColor.purple, UIColor.red]
        HighColors[HighColor3] = [UIColor.white, UIColor.yellow, UIColor(named: "Gold"), UIColor(named: "Pistachio")] as? [UIColor]
        ShowColors()
        ShowSampleView()
    }
    
    func ShowColors()
    {
        for (Segment, _) in LowColors
        {
            Segment.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        let LowColor = ParameterManager.GetColor(From: FilterID, Field: .LowThresholdColor, Default: UIColor.black)
        let (LowSeg, LowIndex) = GetColorSegment(ForLow: true, Color: LowColor)
        print("LowSeg.tag=\(LowSeg.tag), LowIndex=\(LowIndex)")
        LowSeg.selectedSegmentIndex = LowIndex
        
        for (Segment, _) in HighColors
        {
            Segment.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        let HighColor = ParameterManager.GetColor(From: FilterID, Field: .HighThresholdColor, Default: UIColor.white)
        let (HighSeg, HighIndex) = GetColorSegment(ForLow: false, Color: HighColor)
                print("HighSeg.tag=\(HighSeg.tag), HighIndex=\(HighIndex)")
        HighSeg.selectedSegmentIndex = HighIndex
    }
    
    func GetColorIndex(In: ControlColors, Color: UIColor) -> Int?
    {
        for (_, Colors) in In
        {
            var Index = 0
            for SomeColor in Colors
            {
                if SomeColor == Color
                {
                    return Index
                }
                Index = Index + 1
            }
        }
        return nil
    }
    
    func GetColorSegment(ForLow: Bool, Color: UIColor) -> (UISegmentedControl, Int)
    {
        if ForLow
        {
            if let (Segment, Index) = GetColorSegment(ForType: LowColors, Color: Color)
            {
                return (Segment, Index)
            }
            return (LowColor0, 0)
        }
        else
        {
            if let (Segment, Index) = GetColorSegment(ForType: HighColors, Color: Color)
            {
                return (Segment, Index)
            }
            return (HighColor3, 0)
        }
    }
    
    func GetColorSegment(ForType: ControlColors, Color: UIColor) -> (UISegmentedControl, Int)?
    {
        for (Segment, Colors) in ForType
        {
            var Index = 0
            for SomeColor in Colors
            {
                if SomeColor == Color
                {
                    return (Segment, Index)
                }
                Index = Index + 1
            }
        }
        return nil
    }
    
    typealias ControlColors = [UISegmentedControl: [UIColor]]
    
    var LowColors = ControlColors()
    var HighColors = ControlColors()
    
    func SetThresholdInput(_ Value: Int)
    {
        switch Value
        {
        case 0:
            ThresholdInputHSB.selectedSegmentIndex = 0
            
        case 1:
            ThresholdInputHSB.selectedSegmentIndex = 1
            
        case 2:
            ThresholdInputHSB.selectedSegmentIndex = 2
            
        case 3:
            ThresholdInputRGB.selectedSegmentIndex = 0
            
        case 4:
            ThresholdInputRGB.selectedSegmentIndex = 1
            
        case 5:
            ThresholdInputRGB.selectedSegmentIndex = 2
            
        case 6:
            ThresholdInputCMYK.selectedSegmentIndex = 0
            
        case 7:
            ThresholdInputCMYK.selectedSegmentIndex = 1
            
        case 8:
            ThresholdInputCMYK.selectedSegmentIndex = 2
            
        case 9:
            ThresholdInputCMYK.selectedSegmentIndex = 3
            
        default:
            fatalError("Unexpected input type (\(Value)) encountered.")
        }
    }
    
    @objc func SliderStoppedSliding()
    {
        let SliderValue = ThresholdSlider.value / 1000.0
        ThresholdValue.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: Double(SliderValue), ToField: .ThresholdValue)
        ShowSampleView()
    }
    
    @IBAction func ThresholdSliderChanged(_ sender: Any)
    {
        let SliderValue = ThresholdSlider.value / 1000.0
        ThresholdValue.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBAction func HandleApplyIfGreaterChanged(_ sender: Any)
    {
        UpdateValue(WithValue: ApplyIfGreaterSwitch.isOn, ToField: .ApplyThresholdIfHigher)
    }
    
    @IBAction func HandleRGBChanged(_ sender: Any)
    {
        ThresholdInputHSB.selectedSegmentIndex = UISegmentedControl.noSegment
        ThresholdInputCMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        let Index = ThresholdInputRGB.selectedSegmentIndex + 3
        UpdateValue(WithValue: Index, ToField: .ThresholdInput)
        ShowSampleView()
    }
    
    @IBAction func HandleHSBChanged(_ sender: Any)
    {
        ThresholdInputRGB.selectedSegmentIndex = UISegmentedControl.noSegment
        ThresholdInputCMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        let Index = ThresholdInputHSB.selectedSegmentIndex
        UpdateValue(WithValue: Index, ToField: .ThresholdInput)
        ShowSampleView()
    }
    
    @IBAction func HandleCMYKChanged(_ sender: Any)
    {
        ThresholdInputRGB.selectedSegmentIndex = UISegmentedControl.noSegment
        ThresholdInputHSB.selectedSegmentIndex = UISegmentedControl.noSegment
        let Index = ThresholdInputCMYK.selectedSegmentIndex + 6
        UpdateValue(WithValue: Index, ToField: .ThresholdInput)
        ShowSampleView()
    }
    
    func GetSegmentIndex(ForSegment: UISegmentedControl, InLowColors: Bool) -> Int?
    {
        var Index = 0
        if InLowColors
        {
            for (Seg, _) in LowColors
            {
                if Seg == ForSegment
                {
                    return Index
                }
                Index = Index + 1
            }
            return nil
        }
        else
        {
            for (Seg, _) in HighColors
            {
                if Seg == ForSegment
                {
                    return Index
                }
                Index = Index + 1
            }
            return nil
        }
    }
    
    @IBAction func LowColorChanged(_ sender: Any)
    {
        let SomeSegment = sender as! UISegmentedControl
        for (Seg, _) in LowColors
        {
            if Seg != SomeSegment
            {
                Seg.selectedSegmentIndex = UISegmentedControl.noSegment
            }
        }
        let LowSegColors = LowColors[SomeSegment]
        let Color = LowSegColors![SomeSegment.selectedSegmentIndex]
        UpdateValue(WithValue: Color, ToField: .LowThresholdColor)
        ShowSampleView()
    }
    
    @IBAction func HighColorChanged(_ sender: Any)
    {
        let SomeSegment = sender as! UISegmentedControl
        for (Seg, _) in HighColors
        {
            if Seg != SomeSegment
            {
                Seg.selectedSegmentIndex = UISegmentedControl.noSegment
            }
        }
        let HighSegColors = HighColors[SomeSegment]
        let Color = HighSegColors![SomeSegment.selectedSegmentIndex]
        UpdateValue(WithValue: Color, ToField: .HighThresholdColor)
        ShowSampleView()
    }
    
    @IBOutlet weak var ThresholdInputCMYK: UISegmentedControl!
    @IBOutlet weak var ThresholdInputHSB: UISegmentedControl!
    @IBOutlet weak var ThresholdInputRGB: UISegmentedControl!
    @IBOutlet weak var ApplyIfGreaterSwitch: UISwitch!
    @IBOutlet weak var ThresholdSlider: UISlider!
    @IBOutlet weak var ThresholdValue: UILabel!
    
    @IBOutlet weak var HighColor0: UISegmentedControl!
    @IBOutlet weak var HighColor1: UISegmentedControl!
    @IBOutlet weak var HighColor2: UISegmentedControl!
    @IBOutlet weak var HighColor3: UISegmentedControl!
    @IBOutlet weak var LowColor0: UISegmentedControl!
    @IBOutlet weak var LowColor1: UISegmentedControl!
    @IBOutlet weak var LowColor2: UISegmentedControl!
    @IBOutlet weak var LowColor3: UISegmentedControl!
    
    @IBAction func HandleBackButtonpressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
    }
    
    @IBAction func HandleChangeImageSize(_ sender: Any)
    {
        #if false
        ChangeImageSize()
        #endif
    }
}
