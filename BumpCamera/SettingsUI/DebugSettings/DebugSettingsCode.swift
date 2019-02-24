//
//  DebugSettingsCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class DebugSettingsCode: UITableViewController
{
    #if DEBUG
    let _Settings = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        FramerateSwitch.isOn = _Settings.bool(forKey: "ShowFramerateOverlay")
        IgnorePreviousCrashSwitch.isOn = _Settings.bool(forKey: "IgnorePriorCrashes")
        var LastBadFilter = (UIApplication.shared.delegate as? AppDelegate)?.CrashedFilterName
        if (LastBadFilter?.isEmpty)!
        {
            LastBadFilter = "not recorded"
        }
        LastCrashedFilterName.text = LastBadFilter
        self.tableView.tableFooterView = UIView()
    }
    
    @IBAction func HandleFramerateChanged(_ sender: Any)
    {
        _Settings.set(FramerateSwitch.isOn, forKey: "ShowFramerateOverlay")
    }
    
    @IBOutlet weak var FramerateSwitch: UISwitch!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleIgnorePreviousCrashChanged(_ sender: Any)
    {
        _Settings.set(IgnorePreviousCrashSwitch.isOn, forKey: "IgnorePriorCrashes")
    }
    
    @IBOutlet weak var IgnorePreviousCrashSwitch: UISwitch!
    
    @IBOutlet weak var LastCrashedFilterName: UILabel!
    
    #endif
}
