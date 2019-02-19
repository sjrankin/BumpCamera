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
        let V1 = ParameterManager.GetVector(From: FilterID, Field: .Point1, Default: CIVector(x: 0, y: 0))
    }
    
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
    }
    
    @objc func HandleColor1XStoppedSliding()
    {
        
    }
    
    @IBAction func HandleColor1XChanged(_ sender: Any)
    {
    }
    
    @objc func HandleColor1YStoppedSliding()
    {
        
    }
    
    @IBAction func HandleColor1YChanged(_ sender: Any)
    {
    }
    
    @objc func HandleColor2XStoppedSliding()
    {
        
    }
    
    @IBAction func HandleColor2XChanged(_ sender: Any)
    {
    }
    
    @objc func HandleColor2YStoppedSliding()
    {
        
    }
    
    @IBAction func HandleColor2YChanged(_ sender: Any)
    {
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
