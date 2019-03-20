//
//  SobelSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class SobelSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Sobel)
        
        MergeSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .SobelMergeWithBackground, Default: true)
    }
    
    @IBOutlet weak var MergeSwitch: UISwitch!
    
    @IBAction func HandleMergeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeSwitch.isOn, ToField: .SobelMergeWithBackground)
        ShowSampleView()
    }
}
