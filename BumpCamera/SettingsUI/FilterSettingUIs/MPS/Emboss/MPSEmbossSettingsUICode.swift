//
//  MPSEmbossSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MPSEmbossSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.MPSEmboss)
        let EmbossType = ParameterManager.GetInt(From: FilterID, Field: .EmbossType, Default: 0)
        EmbossTypeSegment.selectedSegmentIndex = EmbossType
    }
    
    @IBAction func HandleEmbossTypeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: EmbossTypeSegment.selectedSegmentIndex, ToField: .EmbossType)
        ShowSampleView()
    }
    
    @IBOutlet weak var EmbossTypeSegment: UISegmentedControl!
}
