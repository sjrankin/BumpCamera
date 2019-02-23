//
//  GaussianBlurSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GaussianBlurSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.GaussianBlur)
        
        let Sigma = ParameterManager.GetDouble(From: FilterID, Field: .Sigma, Default: 5.0)
        SigmaValueLabel.text = "\(Sigma.Round(To: 2))"
        SigmaSlider.value = Float(Sigma * 1000.0)
        
        SigmaSlider.addTarget(self,
                              action: #selector(HandleSigmaStoppedSliding),
                              for: [.touchUpInside, .touchUpOutside])
    }
    
    @objc func HandleSigmaStoppedSliding()
    {
        let SliderValue = Double(SigmaSlider.value / 1000.0)
        SigmaValueLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .Sigma)
        ShowSampleView()
    }
    
    @IBAction func HandleSigmaChanged(_ sender: Any)
    {
        let SliderValue = Double(SigmaSlider.value / 1000.0)
        SigmaValueLabel.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBOutlet weak var SigmaValueLabel: UILabel!
    @IBOutlet weak var SigmaSlider: UISlider!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
}
