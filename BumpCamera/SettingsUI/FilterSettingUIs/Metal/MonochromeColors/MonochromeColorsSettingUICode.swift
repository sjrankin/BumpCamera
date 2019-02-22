//
//  MonochromeColorsSettingUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MonochromeColorsSettingUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.MonochromeColor)
        SetupUI()
        ShowSampleView()
    }
    
    func SetupUI()
    {
        let MCColorspace = ParameterManager.GetInt(From: FilterID, Field: .MonochromeColorspace, Default: 0)
        ColorspaceSegment.selectedSegmentIndex = MCColorspace
        SetColorspace(MCColorspace)
        BrightColorSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .BrightChannels, Default: true)
        RedSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .ForRed, Default: true)
        GreenSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .ForGreen, Default: true)
        BlueSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .ForBlue, Default: true)
        CyanSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .ForCyan, Default: true)
        MagentaSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .ForMagenta, Default: true)
        YellowSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .ForYellow, Default: true)
        BlackSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .ForBlack, Default: false)
        let SegmentCount = ParameterManager.GetInt(From: FilterID, Field: .HueSegmentCount, Default: 10)
        let SegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .HueSelectedSegment, Default: 0)
        SetSegmentCount(To: SegmentCount)
        SetSegmentIndex(To: SegmentIndex)
        SetDisabledIndices(SegmentCount)
    }
    
    func SetSegmentCount(To: Int)
    {
        if To < 1
        {
            return
        }
        if To > 10
        {
            return
        }
        if To >= 1 && To <= 5
        {
            SegmentCount1.selectedSegmentIndex = UISegmentedControl.noSegment
            SegmentCount0.selectedSegmentIndex = To - 1
        }
        else
        {
            SegmentCount0.selectedSegmentIndex = UISegmentedControl.noSegment
            SegmentCount1.selectedSegmentIndex = To - 6
        }
    }
    
    func GetSegmentCount() -> Int
    {
        if SegmentCount1.selectedSegmentIndex == UISegmentedControl.noSegment
        {
            return SegmentCount0.selectedSegmentIndex + 1
        }
        else
        {
            return SegmentCount1.selectedSegmentIndex + 6
        }
    }
    
    func SetSegmentIndex(To: Int)
    {
        if To < 1
        {
            return
        }
        if To > 10
        {
            return
        }
        print("Setting segment index to \(To)")
        if To >= 1 && To <= 5
        {
            SegmentIndex1.selectedSegmentIndex = UISegmentedControl.noSegment
            SegmentIndex0.selectedSegmentIndex = To - 1
        }
        else
        {
            SegmentIndex0.selectedSegmentIndex = UISegmentedControl.noSegment
            SegmentIndex1.selectedSegmentIndex = To - 6
        }
    }
    
    func GetSegmentIndex() -> Int
    {
        var Index = 0
        if SegmentIndex1.selectedSegmentIndex == UISegmentedControl.noSegment
        {
            Index = SegmentIndex0.selectedSegmentIndex + 1
        }
        else
        {
            Index = SegmentIndex1.selectedSegmentIndex + 6
        }
        print("Selected segment index: \(Index)")
        return Index
    }
    
    func SetColorspace(_ Colorspace: Int)
    {
        RGBLabel.isEnabled = Colorspace == 0
        RedLabel.isEnabled = Colorspace == 0
        RedSwitch.isEnabled = Colorspace == 0
        GreenLabel.isEnabled = Colorspace == 0
        GreenSwitch.isEnabled = Colorspace == 0
        BlueLabel.isEnabled = Colorspace == 0
        BlueSwitch.isEnabled = Colorspace == 0
        CMYKLabel.isEnabled = Colorspace == 1
        CyanLabel.isEnabled = Colorspace == 1
        CyanSwitch.isEnabled = Colorspace == 1
        MagentaLabel.isEnabled = Colorspace == 1
        MagentaSwitch.isEnabled = Colorspace == 1
        YellowLabel.isEnabled = Colorspace == 1
        YellowSwitch.isEnabled = Colorspace == 1
        BlackLabel.isEnabled = Colorspace == 1
        BlackSwitch.isEnabled = Colorspace == 1
        HueLabel.isEnabled = Colorspace == 2
        SegmentLabel.isEnabled = Colorspace == 2
        SegmentCount0.isEnabled = Colorspace == 2
        SegmentCount1.isEnabled = Colorspace == 2
        SegmentIndex0.isEnabled = Colorspace == 2
        SegmentIndex1.isEnabled = Colorspace == 2
        IndexLabel.isEnabled = Colorspace == 2
    }
    
    func EnableIndexAt(_ IndexValue: Int, To: Bool)
    {
        if IndexValue < 1
        {
            return
        }
        if IndexValue > 10
        {
            return
        }
        if IndexValue < 6
        {
            SegmentIndex0.setEnabled(To, forSegmentAt: IndexValue - 1)
        }
        else
        {
            SegmentIndex1.setEnabled(To, forSegmentAt: IndexValue - 6)
        }
    }
    
    func SetDisabledIndices(_ ToValid: Int)
    {
        print("SetDisabledIndices(\(ToValid))")
        let Final = ToValid
        if Final >= 10
        {
            for i in 1 ... 5
            {
                SegmentIndex0.setEnabled(true, forSegmentAt: i - 1)
                SegmentIndex1.setEnabled(true, forSegmentAt: i - 1)
            }
            return
        }
        for i in 1 ... Final
        {
            EnableIndexAt(i, To: true)
        }
        for i in Final + 1 ... 10
        {
            EnableIndexAt(i, To: false)
        }
    }
    
    func UpdateIndices(WithCount: Int)
    {
        let CurrentIndex = GetSegmentIndex()
        if CurrentIndex > WithCount
        {
            print("Index \(CurrentIndex) > segment count \(WithCount)")
            SetSegmentIndex(To: WithCount)
            
        }
        SetDisabledIndices(WithCount)
    }
    
    func UpdateSegmentCount()
    {
        let NewCount = GetSegmentCount()
        UpdateIndices(WithCount: NewCount)
        UpdateValue(WithValue: NewCount, ToField: .HueSegmentCount)
        ShowSampleView()
    }
    
    @IBAction func HandleSegment0Changed(_ sender: Any)
    {
        SegmentCount1.selectedSegmentIndex = UISegmentedControl.noSegment
        UpdateSegmentCount()
    }
    
    @IBAction func HandleSegment1Changed(_ sender: Any)
    {
        SegmentCount0.selectedSegmentIndex = UISegmentedControl.noSegment
        UpdateSegmentCount()
    }
    
    @IBAction func HandleIndex0Changed(_ sender: Any)
    {
        SegmentIndex1.selectedSegmentIndex = UISegmentedControl.noSegment
        UpdateValue(WithValue: SegmentIndex0.selectedSegmentIndex + 1, ToField: .HueSelectedSegment)
        ShowSampleView()
    }
    
    @IBAction func HandleIndex1Changed(_ sender: Any)
    {
        SegmentIndex0.selectedSegmentIndex = UISegmentedControl.noSegment
        UpdateValue(WithValue: SegmentIndex1.selectedSegmentIndex + 1, ToField: .HueSelectedSegment)
        ShowSampleView()
    }
    
    @IBAction func HandleColorSpaceChange(_ sender: Any)
    {
        let NewColorspace = ColorspaceSegment.selectedSegmentIndex
        SetColorspace(NewColorspace)
        UpdateValue(WithValue: NewColorspace, ToField: .MonochromeColorspace)
        ShowSampleView()
    }
    
    @IBOutlet weak var ColorspaceSegment: UISegmentedControl!
    
    @IBAction func HandleBrightColorsChanged(_ sender: Any)
    {
        UpdateValue(WithValue: BrightColorSwitch.isOn, ToField: .BrightChannels)
        ShowSampleView()
    }
    
    @IBOutlet weak var BrightColorSwitch: UISwitch!
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomeButton(_ sender: Any)
    {
    }
    
    @IBAction func HandleRedChanged(_ sender: Any)
    {
        UpdateValue(WithValue: RedSwitch.isOn, ToField: .ForRed)
        ShowSampleView()
    }
    
    @IBAction func HandleGreenChanged(_ sender: Any)
    {
        UpdateValue(WithValue: GreenSwitch.isOn, ToField: .ForGreen)
        ShowSampleView()
    }
    
    @IBAction func HandleBlueChanged(_ sender: Any)
    {
        UpdateValue(WithValue: BlueSwitch.isOn, ToField: .ForBlue)
        ShowSampleView()
    }
    
    @IBAction func HandleCyanChanged(_ sender: Any)
    {
        UpdateValue(WithValue: CyanSwitch.isOn, ToField: .ForCyan)
        ShowSampleView()
    }
    
    @IBAction func HandleMagentaChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MagentaSwitch.isOn, ToField: .ForMagenta)
        ShowSampleView()
    }
    
    @IBAction func HandleYellowChanged(_ sender: Any)
    {
        UpdateValue(WithValue: YellowSwitch.isOn, ToField: .ForYellow)
        ShowSampleView()
    }
    
    @IBAction func HandleBlackChanged(_ sender: Any)
    {
        UpdateValue(WithValue: BlackSwitch.isOn, ToField: .ForBlack)
        ShowSampleView()
    }
    
    @IBOutlet weak var RGBLabel: UILabel!
    @IBOutlet weak var RedLabel: UILabel!
    @IBOutlet weak var GreenLabel: UILabel!
    @IBOutlet weak var BlueLabel: UILabel!
    @IBOutlet weak var RedSwitch: UISwitch!
    @IBOutlet weak var GreenSwitch: UISwitch!
    @IBOutlet weak var BlueSwitch: UISwitch!
    @IBOutlet weak var CMYKLabel: UILabel!
    @IBOutlet weak var CyanLabel: UILabel!
    @IBOutlet weak var MagentaLabel: UILabel!
    @IBOutlet weak var YellowLabel: UILabel!
    @IBOutlet weak var BlackLabel: UILabel!
    @IBOutlet weak var CyanSwitch: UISwitch!
    @IBOutlet weak var MagentaSwitch: UISwitch!
    @IBOutlet weak var YellowSwitch: UISwitch!
    @IBOutlet weak var BlackSwitch: UISwitch!
    @IBOutlet weak var HueLabel: UILabel!
    @IBOutlet weak var SegmentLabel: UILabel!
    @IBOutlet weak var IndexLabel: UILabel!
    @IBOutlet weak var SegmentCount0: UISegmentedControl!
    @IBOutlet weak var SegmentCount1: UISegmentedControl!
    @IBOutlet weak var SegmentIndex0: UISegmentedControl!
    @IBOutlet weak var SegmentIndex1: UISegmentedControl!
}
