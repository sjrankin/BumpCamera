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
        SegmentCountSlider.value = Float(SegmentCount * 50)
        SegmentCountLabel.text = "\(SegmentCount)"
        let SegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .HueSelectedSegment, Default: 0)
        SegmentIndexSlider.value = Float(SegmentIndex * 50)
        SegmentIndexValue.text = "\(SegmentIndex)"
        SegmentCountSlider.addTarget(self, action: #selector(SegmentCountStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        SegmentIndexSlider.addTarget(self, action: #selector(SegmentIndexStoppedSliding), for: [.touchUpInside, .touchUpOutside])
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
        SegmentCountSlider.isEnabled = Colorspace == 2
        SegmentCountLabel.isEnabled = Colorspace == 2
        IndexLabel.isEnabled = Colorspace == 2
        SegmentIndexSlider.isEnabled = Colorspace == 2
        SegmentIndexValue.isEnabled = Colorspace == 2
    }
    
    func CoordinateSlidersFromCount(_ NewSegmentCount: Int)
    {
        let IndexValue = Int(SegmentIndexSlider.value / 50.0)
        if IndexValue <= NewSegmentCount
        {
            return
        }
        SegmentIndexSlider.value = Float(NewSegmentCount * 50)
        SegmentIndexValue.text = "\(NewSegmentCount)"
        UpdateValue(WithValue: NewSegmentCount, ToField: .HueSelectedSegment)
    }
    
    @IBAction func HandleSegmentCountChanged(_ sender: Any)
    {
        let SliderValue = Int(SegmentCountSlider.value / 50.0)
        SegmentCountLabel.text = "\(SliderValue)"
        CoordinateSlidersFromCount(SliderValue)
    }
    
    func CoordinateSlidersFromIndex(_ NewIndexCount: Int)
    {
        let SegmentCount = Int(SegmentCountSlider.value / 50.0)
        if NewIndexCount <= SegmentCount
        {
            SnapIndexBack = false
            SegmentIndexSlider.tintColor = self.view.tintColor
            SegmentIndexValue.textColor = UIColor.black
            return
        }
        SegmentIndexSlider.tintColor = UIColor.red
        SegmentIndexValue.textColor = UIColor.red
        SnapIndexBack = true
    }
    
    var SnapIndexBack = false
    
    @objc func SegmentCountStoppedSliding()
    {
        let SliderValue = Int(SegmentCountSlider.value / 50.0)
        SegmentCountLabel.text = "\(SliderValue)"
        CoordinateSlidersFromCount(SliderValue)
        UpdateValue(WithValue: SliderValue, ToField: .HueSegmentCount)
        ShowSampleView()
    }
    
    @IBAction func HandleSegmentIndexChanged(_ sender: Any)
    {
        let SliderValue = Int(SegmentIndexSlider.value / 50.0)
        SegmentIndexValue.text = "\(SliderValue)"
        CoordinateSlidersFromIndex(SliderValue)
    }
    
    @objc func SegmentIndexStoppedSliding()
    {
        if SnapIndexBack
        {
            SnapIndexBack = false
            let SegmentCount = Int(SegmentCountSlider.value / 50.0)
            SegmentIndexSlider.tintColor = self.view.tintColor
            SegmentIndexValue.textColor = UIColor.black
            SegmentIndexSlider.value = Float(SegmentCount * 50)
        }
        let SliderValue = Int(SegmentIndexSlider.value / 50.0)
        SegmentIndexValue.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .HueSelectedSegment)
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
    @IBOutlet weak var SegmentCountSlider: UISlider!
    @IBOutlet weak var SegmentCountLabel: UILabel!
    @IBOutlet weak var IndexLabel: UILabel!
    @IBOutlet weak var SegmentIndexSlider: UISlider!
    @IBOutlet weak var SegmentIndexValue: UILabel!
}
