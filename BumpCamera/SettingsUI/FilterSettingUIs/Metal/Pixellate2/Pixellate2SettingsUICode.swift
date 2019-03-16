//
//  Pixellate2SettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class Pixellate2SettingsUICode: FilterSettingUIBase, DescendentDelta
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.PixellateMetal)
        let BWidth = ParameterManager.GetInt(From: FilterID, Field: .BlockWidth, Default: 32)
        BlockWidthSlider.value = Float(BWidth * 10)
        WidthOut.text = "\(BWidth)"
        let BHeight = ParameterManager.GetInt(From: FilterID, Field: .BlockHeight, Default: 32)
        BlockWidthSlider.value = Float(BHeight * 10)
        HeightOut.text = "\(BHeight)"
        BlockWidthSlider.addTarget(self, action: #selector(HandleWidthStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        BlockHeightSlider.addTarget(self, action: #selector(HandleHeightStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        let DoMerge = ParameterManager.GetBool(From: FilterID, Field: .MergeWithBackground, Default: true)
        MergeSwitch.isOn = DoMerge
        let CondPix = ParameterManager.GetBool(From: FilterID, Field: .ConditionalPixellation, Default: false)
        ConditionalLabel.text = CondPix ? "enabled" : "disabled"
        let PixelSelector = ParameterManager.GetInt(From: FilterID, Field: .PixellationHighlighting, Default: 3)
        HighlightSegment.selectedSegmentIndex = PixelSelector
        UpdateForHighlighting(PixelSelector)
        ShowSampleView()
    }
    
    func UpdatedFrom(_ DescendentName: String, Field: FilterManager.InputFields)
    {
        
    }
    
    func UpdateForHighlighting(_ PixelSelector: Int)
    {
        HueEnabledLabel.text = ""
        HueLabel.isEnabled = false
        SaturationEnabledLabel.text = ""
        SaturationLabel.isEnabled = false
        BrightnessEnabledLabel.text = ""
        BrightnessLabel.isEnabled = false
        switch PixelSelector
        {
        case 0:
            HueEnabledLabel.text = "enabled"
            HueLabel.isEnabled = true
            
        case 1:
            SaturationEnabledLabel.text = "enabled"
            SaturationLabel.isEnabled = true
            
        case 2:
            BrightnessEnabledLabel.text = "enabled"
            BrightnessLabel.isEnabled = true
            
        default:
            break
        }
    }
    
    @objc func HandleWidthStoppedSliding()
    {
        let SliderValue = Int(BlockWidthSlider.value / 10.0)
        WidthOut.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .BlockWidth)
        ShowSampleView()
    }
    
    @IBAction func HandleWidthChanged(_ sender: Any)
    {
        let SliderValue = Int(BlockWidthSlider.value / 10.0)
        WidthOut.text = "\(SliderValue)"
    }
    
    @objc func HandleHeightStoppedSliding()
    {
        let SliderValue = Int(BlockHeightSlider.value / 10.0)
        HeightOut.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .BlockHeight)
        ShowSampleView()
    }
    
    @IBAction func HandleHeightChanged(_ sender: Any)
    {
        let SliderValue = Int(BlockHeightSlider.value / 10.0)
        HeightOut.text = "\(SliderValue)"
    }
    
    @IBAction func HandleMergeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeSwitch.isOn, ToField: .MergeWithBackground)
        ShowSampleView()
    }
    
    @IBAction func HandlePixelHighlightingChanged(_ sender: Any)
    {
        let PixelSelector = HighlightSegment.selectedSegmentIndex
        UpdateForHighlighting(PixelSelector)
        UpdateValue(WithValue: PixelSelector, ToField: .PixellationHighlighting)
        ShowSampleView()
    }
    
    @IBOutlet weak var ConditionalLabel: UILabel!
    @IBOutlet weak var BlockWidthSlider: UISlider!
    @IBOutlet weak var BlockHeightSlider: UISlider!
    @IBOutlet weak var MergeSwitch: UISwitch!
    @IBOutlet weak var HighlightSegment: UISegmentedControl!
    @IBOutlet weak var WidthOut: UILabel!
    @IBOutlet weak var HeightOut: UILabel!
    @IBOutlet weak var HueLabel: UILabel!
    @IBOutlet weak var SaturationLabel: UILabel!
    @IBOutlet weak var BrightnessLabel: UILabel!
    @IBOutlet weak var HueEnabledLabel: UILabel!
    @IBOutlet weak var SaturationEnabledLabel: UILabel!
    @IBOutlet weak var BrightnessEnabledLabel: UILabel!
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHome(_ sender: Any)
    {
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        let PixelSelector = HighlightSegment.selectedSegmentIndex
        switch identifier
        {
        case "ToConditionalPixellation":
            return true
            
        case "ToHighlightHue":
            return PixelSelector == 0
            
        case "ToHighlightSaturation":
            return PixelSelector == 1
            
        case "ToHighlightBrightness":
            return PixelSelector == 2
            
        default:
            break
        }
        
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToConditionalPixellation":
            let Dest = segue.destination as? Pixellate2ConditionalUI
            Dest?.delegate = self
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
}
