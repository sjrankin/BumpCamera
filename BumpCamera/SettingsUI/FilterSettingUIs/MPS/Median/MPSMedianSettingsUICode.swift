//
//  MPSMedianSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MPSMedianSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.MPSMedian)
        let Diameter = ParameterManager.GetInt(From: FilterID, Field: .MedianSize, Default: 3)
        DiameterSegment.selectedSegmentIndex = [3: 0, 5: 1, 7: 2, 9: 3][Diameter]!
    }
    
    @IBAction func HandleDiameterChanged(_ sender: Any)
    {
        let Diameter = [3, 5, 7, 9][DiameterSegment.selectedSegmentIndex]
        print("New median diameter is \(Diameter)")
        UpdateValue(WithValue: Diameter, ToField: .MedianSize)
        ShowSampleView()
    }
    
    @IBOutlet weak var DiameterSegment: UISegmentedControl!
}
