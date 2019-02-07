//
//  LineOverlaySettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class LineOverlaySettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.LineOverlay)
        
        InitializeSlider(ContrastSlider, Action: #selector(ContrastStoppedSliding))
        InitializeSlider(SharpnessSlider, Action: #selector(SharpnessStoppedSliding))
        InitializeSlider(ThresholdSlider, Action: #selector(ThresholdStoppedSliding))
        InitializeSlider(EdgeSlider, Action: #selector(EdgeStoppedSliding))
        InitializeSlider(NoiseSlider, Action: #selector(NoiseStoppedSliding))
        
        PopulateUI()
    }
    
    func InitializeSlider(_ Slider: UISlider, Action: Selector)
    {
        Slider.addTarget(self, action: Action, for: [.touchUpInside, .touchUpOutside])
    }
    
    func PopulateUI()
    {
        let Contrast = ParameterManager.GetDouble(From: FilterID, Field: .InputContrast, Default: 50.0)
        let Sharpness = ParameterManager.GetDouble(From: FilterID, Field: .NRSharpness, Default: 0.71)
        let Threshold = ParameterManager.GetDouble(From: FilterID, Field: .InputThreshold, Default: 0.0)
        let Edge = ParameterManager.GetDouble(From: FilterID, Field: .EdgeIntensity, Default: 1.0)
        let Noise = ParameterManager.GetDouble(From: FilterID, Field: .NRNoiseLevel, Default: 0.07)
        
        ContrastLabel.text = "\(Contrast.Round(To: 1))"
        ContrastSlider.value = Float(Contrast * 10.0)
        SharpnessLabel.text = "\(Sharpness.Round(To: 2))"
        SharpnessSlider.value = Float(Sharpness * 100.0)
        ThresholdLabel.text = "\(Threshold.Round(To: 2))"
        ThresholdSlider.value = Float(Threshold * 1000.0)
        EdgeLabel.text = "\(Edge.Round(To: 2))"
        EdgeSlider.value = Float(Edge * 1000.0)
        NoiseLabel.text = "\(Noise.Round(To: 2))"
        NoiseSlider.value = Float(Noise * 1000.0)
    }
    
    @objc func ContrastStoppedSliding()
    {
        let SliderValue: Double = Double(ContrastSlider.value / 50.0)
        ContrastLabel.text = "\(SliderValue.Round(To: 1))"
        UpdateValue(WithValue: SliderValue, ToField: .InputContrast)
        ShowSampleView()
    }
    
    @IBAction func HandleContrastChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(ContrastSlider.value / 50.0)
        ContrastLabel.text = "\(SliderValue.Round(To: 1))"
    }
    
    @objc func SharpnessStoppedSliding()
    {
        let SliderValue: Double = Double(SharpnessSlider.value / 100.0)
        SharpnessLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .NRSharpness)
        ShowSampleView()
    }
    
    @IBAction func HandleSharpnessChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(SharpnessSlider.value / 50.0)
        SharpnessLabel.text = "\(SliderValue.Round(To: 1))"
    }
    
    @objc func ThresholdStoppedSliding()
    {
        let SliderValue: Double = Double(ThresholdSlider.value / 1000.0)
        ThresholdLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .InputThreshold)
        ShowSampleView()
    }
    
    @IBAction func HandleThresholdChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(ThresholdSlider.value / 1000.0)
        ThresholdLabel.text = "\(SliderValue.Round(To: 2))"
    }
    
    @objc func EdgeStoppedSliding()
    {
        let SliderValue: Double = Double(EdgeSlider.value / 1000.0)
        EdgeLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .EdgeIntensity)
        ShowSampleView()
    }
    
    @IBAction func HandleEdgeChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(EdgeSlider.value / 1000.0)
        EdgeLabel.text = "\(SliderValue.Round(To: 2))"
    }
    
    @objc func NoiseStoppedSliding()
    {
        let SliderValue: Double = Double(NoiseSlider.value / 1000.0)
        NoiseLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .NRNoiseLevel)
        ShowSampleView()
    }
    
    @IBAction func HandleNoiseChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(NoiseSlider.value / 1000.0)
        NoiseLabel.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBAction func HandleMergeSwitchChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeSwitch.isOn, ToField: .MergeWithBackground)
        ShowSampleView()
    }
    
    @IBOutlet weak var MergeSwitch: UISwitch!
    @IBOutlet weak var NoiseLabel: UILabel!
    @IBOutlet weak var NoiseSlider: UISlider!
    @IBOutlet weak var EdgeLabel: UILabel!
    @IBOutlet weak var EdgeSlider: UISlider!
    @IBOutlet weak var ThresholdLabel: UILabel!
    @IBOutlet weak var ThresholdSlider: UISlider!
    @IBOutlet weak var SharpnessLabel: UILabel!
    @IBOutlet weak var SharpnessSlider: UISlider!
    @IBOutlet weak var ContrastLabel: UILabel!
    @IBOutlet weak var ContrastSlider: UISlider!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomeButton(_ sender: Any)
    {
    }
}
