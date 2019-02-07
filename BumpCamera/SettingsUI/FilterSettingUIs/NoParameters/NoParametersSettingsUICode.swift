//
//  NoParametersSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/1/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class NoParametersSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        var WorkingType: FilterManager.FilterTypes!
        let TypeVal = _Settings.integer(forKey: "SetupForFilterType")
        if let VariableType: FilterManager.FilterTypes = FilterManager.FilterTypes(rawValue: TypeVal)
        {
            WorkingType = VariableType
        }
        else
        {
            WorkingType = FilterManager.FilterTypes.PassThrough
        }

        Initialize(FilterType: WorkingType)
        let FilterTitle = FilterManager.GetFilterTitle(WorkingType)
        title = FilterTitle!
        TextLabel.text = "The filter \((FilterTitle)!) has no parameters to set."
    }
   
    @IBOutlet weak var TextLabel: UILabel!
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
}
