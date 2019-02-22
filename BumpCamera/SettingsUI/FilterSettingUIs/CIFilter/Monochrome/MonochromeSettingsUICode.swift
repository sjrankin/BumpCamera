//
//  MonochromeSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/22/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MonochromeSettingsUICode: FilterSettingUIBase, ColorPickerProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Monochrome)
        
        ColorSample.layer.borderColor = UIColor.black.cgColor
        ColorSample.layer.borderWidth = 0.5
        ColorSample.layer.cornerRadius = 5.0
        
        let Color = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.red)
        ColorSample.backgroundColor = Color
        
        let Intensity = ParameterManager.GetDouble(From: FilterID, Field: .Intensity, Default: 1.0)
        IntensityValueLabel.text = "\(Intensity.Round(To: 2))"
        IntensitySlider.value = Float(Intensity * 1000.0)
        IntensitySlider.addTarget(self,
                                  action: #selector(IntensityStoppedSliding),
                                  for: [.touchUpInside, .touchUpOutside])
    }
    
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            if let Tagged = Tag as? String
            {
                if Tagged == "MonochromeColor"
                {
                    ColorSample.backgroundColor = NewColor
                    UpdateValue(WithValue: NewColor, ToField: .Color0)
                    ShowSampleView()
                }
            }
        }
    }
    
    @objc func IntensityStoppedSliding()
    {
        let SliderValue = Double(IntensitySlider.value / 1000.0)
        IntensityValueLabel.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .Intensity)
        ShowSampleView()
    }
    
    @IBAction func HandleIntensityChanged(_ sender: Any)
    {
        let SliderValue = Double(IntensitySlider.value / 1000.0)
        IntensityValueLabel.text = "\(SliderValue.Round(To: 2))"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColorPicker":
            if let Dest = segue.destination as? ColorPicker
            {
                let Color = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.red)
                Dest.delegate = self
                Dest.ColorToEdit(Color, Tag: "MonochromeColor")
            }
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
    
    @IBOutlet weak var IntensityValueLabel: UILabel!
    @IBOutlet weak var IntensitySlider: UISlider!
    @IBOutlet weak var ColorSample: UIView!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
}
