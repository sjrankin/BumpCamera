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
        ToleranceSegments.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .MaskTolerance, Default: 0)
        UpdateUI()
    }
    
    func UpdateUI()
    {
        ToleranceLabel.isEnabled = MergeSwitch.isOn
        ToleranceSegments.isEnabled = MergeSwitch.isOn
    }
    
    @IBOutlet weak var MergeSwitch: UISwitch!
    
    @IBAction func HandleMergeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeSwitch.isOn, ToField: .SobelMergeWithBackground)
        ShowSampleView()
        UpdateUI()
    }
    
    @IBOutlet weak var ToleranceLabel: UILabel!
    
    @IBAction func HandleToleranceChanged(_ sender: Any)
    {
        let Index = ToleranceSegments.selectedSegmentIndex
        let Tolerance = [0, 10, 20, 30][Index]
        UpdateValue(WithValue: Tolerance, ToField: .MaskTolerance)
        ShowSampleView()
    }
    
    @IBOutlet weak var ToleranceSegments: UISegmentedControl!
}
