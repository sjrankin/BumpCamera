//
//  GeneralSettings.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GeneralSettings: UITableViewController
{
    let _Settings = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        HideFilterNameSwitch.isOn = _Settings.bool(forKey: "HideFilterName")
        SaveOriginalSwitch.isOn = _Settings.bool(forKey: "SaveOriginalImage")
        ConfirmSaveSwitch.isOn = _Settings.bool(forKey: "ShowSaveAlert")
        HideFiltersSwitch.isOn = _Settings.bool(forKey: "HideFilterSelectionUI")
        SaveFilterDataSwitch.isOn = _Settings.bool(forKey: "CollectPerformanceStatistics")
        if PrivacyManager.InMaximumPrivacy()
        {
            SaveFilterDataSwitch.isOn = false
            SaveFilterDataSwitch.isEnabled = false
            SaveFilterDataTitle.isEnabled = false
        }
    }
    
    @IBAction func HandleHideFilterNameChanged(_ sender: Any)
    {
        _Settings.set(HideFilterNameSwitch.isOn, forKey: "HideFilterName")
    }
    
    @IBOutlet weak var HideFilterNameSwitch: UISwitch!
    
    @IBAction func HandleSaveOriginalChanged(_ sender: Any)
    {
        _Settings.set(SaveOriginalSwitch.isOn, forKey: "SaveOriginalImage")
    }
    
    @IBOutlet weak var SaveOriginalSwitch: UISwitch!
    
    @IBAction func HandleConfirmSaveChanged(_ sender: Any)
    {
        _Settings.set(ConfirmSaveSwitch.isOn, forKey: "ShowSaveAlert")
    }
    
    @IBOutlet weak var ConfirmSaveSwitch: UISwitch!
    
    @IBOutlet weak var SaveFilterDataSwitch: UISwitch!
    
    @IBOutlet weak var SaveFilterDataTitle: UILabel!
    
    @IBAction func HandleSaveFilterDataChanged(_ sender: Any)
    {
        _Settings.set(SaveFilterDataSwitch.isOn, forKey: "CollectPerformanceStatistics")
    }
    
    @IBAction func HideFiltersChanged(_ sender: Any)
    {
        _Settings.set(HideFiltersSwitch.isOn, forKey: "HideFilterSelectionUI")
    }
    
    @IBOutlet weak var HideFiltersSwitch: UISwitch!
}
