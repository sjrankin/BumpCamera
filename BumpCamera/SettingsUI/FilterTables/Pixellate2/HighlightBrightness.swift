//
//  HighlightBrightness.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/30/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HighlightBrightness: UIViewController
{
    let Filter = FilterManager.FilterTypes.PixellateMetal
    var FilterID: UUID!
    var ParentDelegate: NewFieldSettingProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        FilterID = FilterManager.FilterInfoMap[Filter]!.0
        let IsEnabled = ParameterManager.GetBool(From: FilterID, Field: .HighlightBrightness, Default: false)
        UpdateUIForEnable(IsEnabled: IsEnabled)
        ParamBlock.backgroundColor = UIColor.clear
        ParamBlock.layer.borderColor = UIColor.black.cgColor
        ParamBlock.layer.borderWidth = 0.5
        ParamBlock.layer.cornerRadius = 5.0
        EnableBlock.backgroundColor = UIColor.clear
        EnableBlock.layer.borderColor = UIColor.black.cgColor
        EnableBlock.layer.borderWidth = 0.5
        EnableBlock.layer.cornerRadius = 5.0
    }
    
    func UpdateUIForEnable(IsEnabled: Bool)
    {
        
    }
    
    func UpdateEnableStatus(To: Bool)
    {
        ParameterManager.SetField(To: FilterID, Field: .HighlightBrightness, Value: To)
        ParentDelegate?.NewRawValue(For: .HighlightBrightness)
    }
    
    @IBAction func HandleEnableSwitchChanged(_ sender: Any)
    {
        UpdateUIForEnable(IsEnabled: EnableBrightnessSwitch.isOn)
        UpdateEnableStatus(To: EnableBrightnessSwitch.isOn)
    }
    
    @IBOutlet weak var EnableBrightnessSwitch: UISwitch!
    @IBOutlet weak var EnableBlock: UIView!
    @IBOutlet weak var ParamBlock: UIView!
}
