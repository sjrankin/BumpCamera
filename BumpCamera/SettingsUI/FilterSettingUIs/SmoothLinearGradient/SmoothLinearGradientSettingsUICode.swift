//
//  SmoothLinearGradientSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class SmoothLinearGradientSettingsUICode: FilterSettingUIBase, ColorPickerProtocol
{

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.SmoothLinearGradient)
        Color1XSlider.addTarget(self,
                                action: #selector(HandleColor1XStoppedSliding),
                                for: [.touchUpInside, .touchUpOutside])
        Color1YSlider.addTarget(self,
                                action: #selector(HandleColor1YStoppedSliding),
                                for: [.touchUpInside, .touchUpOutside])
        Color2XSlider.addTarget(self,
                                action: #selector(HandleColor2XStoppedSliding),
                                for: [.touchUpInside, .touchUpOutside])
        Color2YSlider.addTarget(self,
                                action: #selector(HandleColor2YStoppedSliding),
                                for: [.touchUpInside, .touchUpOutside])
        
        let Color0 = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.black)
        let Color1 = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.white)
        Color0Sample.layer.borderColor = UIColor.black.cgColor
        Color0Sample.layer.borderWidth = 0.5
        Color0Sample.layer.cornerRadius = 5.0
        Color0Sample.backgroundColor = Color0
        Color1Sample.layer.borderColor = UIColor.black.cgColor
        Color1Sample.layer.borderWidth = 0.5
        Color1Sample.layer.cornerRadius = 5.0
        Color1Sample.backgroundColor = Color1
        let V0 = ParameterManager.GetVector(From: FilterID, Field: .Point0, Default: CIVector(x: 0, y: 0))
        Color1XSlider.value = Float(V0.x * 1000.0)
        Color1YSlider.value = Float(V0.y * 1000.0)
        Color1XValue.text = "\(V0.x.Round(To: 3))"
                Color1YValue.text = "\(V0.y.Round(To: 3))"
        let V1 = ParameterManager.GetVector(From: FilterID, Field: .Point1, Default: CIVector(x: 0, y: 0))
        Color2XSlider.value = Float(V1.x * 1000.0)
        Color2YSlider.value = Float(V1.y * 1000.0)
        Color2XValue.text = "\(V1.x.Round(To: 3))"
        Color2YValue.text = "\(V1.y.Round(To: 3))"
    }
    
    /// Not implemented or used in this class.
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            if let TagString = Tag as? String
            {
                switch TagString
                {
                case "Color1":
                    Color0Sample.backgroundColor = NewColor
                    UpdateValue(WithValue: NewColor, ToField: .Color0)
                    ShowSampleView()
                    
                case "Color2":
                    Color1Sample.backgroundColor = NewColor
                    UpdateValue(WithValue: NewColor, ToField: .Color1)
                    ShowSampleView()
                    
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
    case "ToColor1ColorPicker":
        let EditMe = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.red)
        if let Dest = segue.destination as? ColorPicker
        {
            Dest.delegate = self
            Dest.ColorToEdit(EditMe, Tag: "Color1")
        }
        else
        {
            print("Error getting destination for color picker from segue.")
            return
        }
        
    case "ToColor2ColorPicker":
        let EditMe = ParameterManager.GetColor(From: FilterID, Field: .Color1, Default: UIColor.red)
        if let Dest = segue.destination as? ColorPicker
        {
            Dest.delegate = self
            Dest.ColorToEdit(EditMe, Tag: "Color2")
        }
        else
        {
            print("Error getting destination for color picker from segue.")
            return
        }
        
    default:
        break
        }
        
        super.prepare(for: segue, sender: self)
    }
    
    @objc func HandleColor1XStoppedSliding()
    {
        let SliderValue = Double(Color1XSlider.value / 1000.0)
        Color1XValue.text = "\(SliderValue.Round(To: 3))"
        let Y1SliderValue = CGFloat(Color1YSlider.value / 1000.0)
        UpdateValue(WithValue: CIVector(x: CGFloat(SliderValue), y: Y1SliderValue), ToField: .Point0)
        ShowSampleView()
    }
    
    @IBAction func HandleColor1XChanged(_ sender: Any)
    {
        let SliderValue = Double(Color1XSlider.value / 1000.0)
        Color1XValue.text = "\(SliderValue.Round(To: 3))"
    }
    
    @objc func HandleColor1YStoppedSliding()
    {
        let SliderValue = Double(Color1YSlider.value / 1000.0)
        Color1YValue.text = "\(SliderValue.Round(To: 3))"
        let X1SliderValue = CGFloat(Color1XSlider.value / 1000.0)
        UpdateValue(WithValue: CIVector(x: X1SliderValue, y: CGFloat(SliderValue)), ToField: .Point0)
        ShowSampleView()
    }
    
    @IBAction func HandleColor1YChanged(_ sender: Any)
    {
        let SliderValue = Double(Color1YSlider.value / 1000.0)
        Color1YValue.text = "\(SliderValue.Round(To: 3))"
    }
    
    @objc func HandleColor2XStoppedSliding()
    {
        let SliderValue = Double(Color2XSlider.value / 1000.0)
        Color2XValue.text = "\(SliderValue.Round(To: 3))"
        let Y2SliderValue = CGFloat(Color2YSlider.value / 1000.0)
        UpdateValue(WithValue: CIVector(x: CGFloat(SliderValue), y: Y2SliderValue), ToField: .Point0)
        ShowSampleView()
    }
    
    @IBAction func HandleColor2XChanged(_ sender: Any)
    {
        let SliderValue = Double(Color2XSlider.value / 1000.0)
        Color2XValue.text = "\(SliderValue.Round(To: 3))"
        
    }
    
    @objc func HandleColor2YStoppedSliding()
    {
        let SliderValue = Double(Color2XSlider.value / 1000.0)
        Color2XValue.text = "\(SliderValue.Round(To: 3))"
        let Y2SliderValue = CGFloat(Color2YSlider.value / 1000.0)
        UpdateValue(WithValue: CIVector(x: CGFloat(SliderValue), y: Y2SliderValue), ToField: .Point1)
        ShowSampleView()
    }
    
    @IBAction func HandleColor2YChanged(_ sender: Any)
    {
        let SliderValue = Double(Color2XSlider.value / 1000.0)
        Color2XValue.text = "\(SliderValue.Round(To: 3))"
    }
    
    @IBOutlet weak var Color0Sample: UIView!
    @IBOutlet weak var Color1Sample: UIView!
    @IBOutlet weak var Color1XSlider: UISlider!
    @IBOutlet weak var Color1YSlider: UISlider!
    @IBOutlet weak var Color2XSlider: UISlider!
    @IBOutlet weak var Color2YSlider: UISlider!
    @IBOutlet weak var Color1XValue: UILabel!
    @IBOutlet weak var Color1YValue: UILabel!
    @IBOutlet weak var Color2XValue: UILabel!
    @IBOutlet weak var Color2YValue: UILabel!
}
