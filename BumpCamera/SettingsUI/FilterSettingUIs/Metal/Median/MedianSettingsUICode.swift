//
//  MedianSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MedianSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Median)
        MedianChannelSegment.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .MedianSwitchOn, Default: 0)
        let MedianWindow = ParameterManager.GetInt(From: FilterID, Field: .MedianSize, Default: 3)
        switch MedianWindow
        {
        case 3:
            MedianWindowSegment.selectedSegmentIndex = 0
            
        case 5:
            MedianWindowSegment.selectedSegmentIndex = 1
            
        case 7:
            MedianWindowSegment.selectedSegmentIndex = 2
            
        case 9:
            MedianWindowSegment.selectedSegmentIndex = 3
            
        default:
            MedianWindowSegment.selectedSegmentIndex = 0
        }
    }
    
    @IBAction func HandleMedianChannelChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MedianChannelSegment.selectedSegmentIndex, ToField: .MedianSwitchOn)
        ShowSampleView()
    }
    
    @IBOutlet weak var MedianChannelSegment: UISegmentedControl!
    
    @IBAction func HandleMedianWindowChanged(_ sender: Any)
    {
        var Size = 3
        switch MedianWindowSegment.selectedSegmentIndex
        {
        case 0:
            Size = 3
            
        case 1:
            Size = 5
            
        case 2:
            Size = 7
            
        case 3:
            Size = 9
            
        default:
            Size = 3
        }
        UpdateValue(WithValue: Size, ToField: .MedianSize)
        ShowSampleView()
    }
    
    @IBOutlet weak var MedianWindowSegment: UISegmentedControl!
}
