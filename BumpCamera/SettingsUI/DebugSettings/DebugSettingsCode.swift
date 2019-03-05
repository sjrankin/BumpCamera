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
        
        ActivityLogSwitch.isOn = _Settings.bool(forKey: "UseActivityLog")
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
    
    @IBAction func HandleActivityLogChanged(_ sender: Any)
    {
        _Settings.set(ActivityLogSwitch.isOn, forKey: "UseActivityLog")
    }
    
    @IBOutlet weak var ActivityLogSwitch: UISwitch!
    
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
    
    @IBAction func HandleClearDebugDirectoryButtonPressed(_ sender: Any)
    {
        FileHandler.ClearDirectory(FileHandler.DebugDirectory)
        let Alert = UIAlertController(title: "Completed",
                                      message: "The directory \(FileHandler.DebugDirectory) was cleared.",
                                      preferredStyle: UIAlertController.Style.alert)
        Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    }
    
    #endif
}
