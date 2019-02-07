//
//  KuwaharaFilterSettingsCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/30/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class KuwaharaFilterSettingsCode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

        Initialize(FilterType: FilterManager.FilterTypes.Kuwahara)
        WarningLabel.layer.borderColor = UIColor.red.cgColor
        WarningLabel.layer.borderWidth = 2.0
        WarningLabel.layer.cornerRadius = 5.0
        BusyIndicator.layer.cornerRadius = 5.0
        RenderTimeLabel.text = "now rendering"
        RadiusSlider.addTarget(self, action: #selector(WidthDoneSliding), for: [.touchUpInside, .touchUpOutside])
        let Radius = ParameterManager.GetDouble(From: FilterID, Field: .Radius, Default: 1.0)
        RadialValueLabel.text = "\(Radius.Round(To: 2))"
        RadiusSlider.value = Float(Radius) * 50.0
        /*
        let _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block:
        {
            Tmr in
            self.ShowSampleView()
        })
 */
    }
    
    @IBAction func HandleRadiusSliderChanged(_ sender: Any)
    {
        let Value = Double(RadiusSlider.value / 50.0)
        RadialValueLabel.text = "\(Value.Round(To: 2))"
    }
    
    @objc func WidthDoneSliding()
    {
        let SliderValue: Double = Double(RadiusSlider.value / 50.0)
        RadialValueLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateRadius(WithValue: SliderValue)
        ShowSampleView()
    }
    
    func UpdateRadius(WithValue: Double)
    {
        ParameterManager.SetField(To: FilterID, Field: .Radius, Value: WithValue as Any?)
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var RenderTimeLabel: UILabel!
    @IBOutlet weak var WarningLabel: UIView!
    @IBOutlet weak var RadialValueLabel: UILabel!
    @IBOutlet weak var RadiusSlider: UISlider!
    @IBOutlet weak var BusyIndicator: UIActivityIndicatorView!
}
