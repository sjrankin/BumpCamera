//
//  ConditionalSilhouetteSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ConditionalSilhouetteSettingsUICode: FilterSettingUIBase, ColorPickerProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Silhouette)
        ColorSample.layer.cornerRadius = 5.0
        ColorSample.layer.borderColor = UIColor.black.cgColor
        ColorSample.layer.borderWidth = 0.5
        ColorSample.backgroundColor = ParameterManager.GetColor(From: FilterID, Field: .SilhouetteColor, Default: UIColor.black)
        SetUI(ParameterManager.GetInt(From: FilterID, Field: .SilhouetteTrigger, Default: 2))
        
        let HueThresh = ParameterManager.GetDouble(From: FilterID, Field: .SHueThreshold, Default: 0.5)
        let HueRange = ParameterManager.GetDouble(From: FilterID, Field: .SHueRange, Default: 0.05)
        let SatThresh = ParameterManager.GetDouble(From: FilterID, Field: .SSaturationThreshold, Default: 0.5)
        let SatRange = ParameterManager.GetDouble(From: FilterID, Field: .SSaturationRange, Default: 0.05)
        let BriThresh = ParameterManager.GetDouble(From: FilterID, Field: .SBrightnessThreshold, Default: 0.5)
        
        HueThresholdSlider.value = Float(HueThresh * 1000.0)
        HueRangeSlider.value = Float(HueRange * 1000.0)
        SaturationThresholdSlider.value = Float(SatThresh * 1000.0)
        SaturationRangeSlider.value = Float(SatRange * 1000.0)
        BrightnessThresholdSlider.value = Float(BriThresh * 1000.0)
        SetValueLabel(To: HueThresh, Label: HueThresholdValue)
        SetValueLabel(To: HueRange, Label: HueRangeValue)
        SetValueLabel(To: SatThresh, Label: SaturationThresholdValue)
        SetValueLabel(To: SatRange, Label: SaturationRangeValue)
        SetValueLabel(To: BriThresh, Label: BrightnessValue)
    }
    
    func SetUI(_ Trigger: Int)
    {
        //Hue items
        HueTitle.isEnabled = Trigger == 0
        HThresholdLabel.isEnabled = Trigger == 0
        HRangeLabel.isEnabled = Trigger == 0
        HueThresholdSlider.isEnabled = Trigger == 0
        HueRangeSlider.isEnabled = Trigger == 0
        HueThresholdValue.isEnabled = Trigger == 0
        HueRangeValue.isEnabled = Trigger == 0
        //Saturation items
        SaturationTitle.isEnabled = Trigger == 1
        SThresholdLabel.isEnabled = Trigger == 1
        SRangeLabel.isEnabled = Trigger == 1
        SaturationThresholdSlider.isEnabled = Trigger == 1
        SaturationRangeSlider.isEnabled = Trigger == 1
        SaturationThresholdValue.isEnabled = Trigger == 1
        SaturationRangeValue.isEnabled = Trigger == 1
        //Brightness controls
        BrightnessTitle.isEnabled = Trigger == 2
        BThresholdLabel.isEnabled = Trigger == 2
        BGTLabel.isEnabled = Trigger == 2
        BrightnessThresholdSlider.isEnabled = Trigger == 2
        BrightnessValue.isEnabled = Trigger == 2
        GreaterThanSwitch.isEnabled = Trigger == 2
    }
    
    func SetValueLabel(To: Double, Label: UILabel)
    {
        Label.text = "\(To.Round(To: 2))"
    }
    
    /// Not used by this class.
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            if let TagValue = Tag as? String
            {
                switch TagValue
                {
                case "SilhouetteColor":
                    UpdateValue(WithValue: NewColor, ToField: .SilhouetteColor)
                    ShowSampleView()
                    ColorSample.backgroundColor = NewColor
                    
                default:
                    break
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColorPicker":
            if let Dest = segue.destination as? ColorPicker
            {
                Dest.delegate = self
                let Color = ParameterManager.GetColor(From: FilterID, Field: .SilhouetteColor, Default: UIColor.black)
                Dest.ColorToEdit(Color, Tag: "SilhouetteColor")
            }
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
    
    @IBAction func HandleTriggerChanged(_ sender: Any)
    {
        let Segment = TriggerSegment.selectedSegmentIndex
        SetUI(Segment)
        UpdateValue(WithValue: Segment, ToField: .SilhouetteTrigger)
        ShowSampleView()
    }
    
    @IBAction func HandleGreaterThanChanged(_ sender: Any)
    {
        UpdateValue(WithValue: GreaterThanSwitch.isOn, ToField: .SGreaterThan)
        ShowSampleView()
    }
    
    @IBAction func HandleNewHueThreshold(_ sender: Any)
    {
        let SliderValue = Double(HueThresholdSlider.value / 1000.0)
        SetValueLabel(To: SliderValue, Label: HueThresholdValue)
        UpdateValue(WithValue: SliderValue, ToField: .SHueThreshold)
        ShowSampleView()
    }
    
    @IBAction func HandleNewHueRange(_ sender: Any)
    {
        let SliderValue = Double(HueRangeSlider.value / 1000.0)
        SetValueLabel(To: SliderValue, Label: HueRangeValue)
        UpdateValue(WithValue: SliderValue, ToField: .SHueRange)
        ShowSampleView()
    }
    
    @IBAction func HandleNewSaturationThresholdValue(_ sender: Any)
    {
        let SliderValue = Double(SaturationThresholdSlider.value / 1000.0)
        SetValueLabel(To: SliderValue, Label: SaturationThresholdValue)
        UpdateValue(WithValue: SliderValue, ToField: .SSaturationThreshold)
        ShowSampleView()
    }
    
    @IBAction func HandleNewSaturationRangeValue(_ sender: Any)
    {
        let SliderValue = Double(SaturationRangeSlider.value / 1000.0)
        SetValueLabel(To: SliderValue, Label: SaturationRangeValue)
        UpdateValue(WithValue: SliderValue, ToField: .SSaturationRange)
        ShowSampleView()
    }
    
    @IBAction func HandleNewBrightnessThreshold(_ sender: Any)
    {
        let SliderValue = Double(BrightnessThresholdSlider.value / 1000.0)
        SetValueLabel(To: SliderValue, Label: BrightnessValue)
        UpdateValue(WithValue: SliderValue, ToField: .SBrightnessThreshold)
        ShowSampleView()
    }
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
    
    @IBOutlet weak var TriggerSegment: UISegmentedControl!
    @IBOutlet weak var ColorSample: UIView!
    //Hue controls
    @IBOutlet weak var HueTitle: UILabel!
    @IBOutlet weak var HThresholdLabel: UILabel!
    @IBOutlet weak var HRangeLabel: UILabel!
    @IBOutlet weak var HueThresholdSlider: UISlider!
    @IBOutlet weak var HueRangeSlider: UISlider!
    @IBOutlet weak var HueThresholdValue: UILabel!
    @IBOutlet weak var HueRangeValue: UILabel!
    //Saturation controls
    @IBOutlet weak var SaturationTitle: UILabel!
    @IBOutlet weak var SThresholdLabel: UILabel!
    @IBOutlet weak var SRangeLabel: UILabel!
    @IBOutlet weak var SaturationThresholdSlider: UISlider!
    @IBOutlet weak var SaturationRangeSlider: UISlider!
    @IBOutlet weak var SaturationThresholdValue: UILabel!
    @IBOutlet weak var SaturationRangeValue: UILabel!
    //Brightness controls
    @IBOutlet weak var BrightnessTitle: UILabel!
    @IBOutlet weak var BThresholdLabel: UILabel!
    @IBOutlet weak var BGTLabel: UILabel!
    @IBOutlet weak var BrightnessThresholdSlider: UISlider!
    @IBOutlet weak var BrightnessValue: UILabel!
    @IBOutlet weak var GreaterThanSwitch: UISwitch!
}
