//
//  Privacy.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class Privacy: UITableViewController
{
    let _Settings = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        PrivacySwitch.isOn = _Settings.bool(forKey: "MaximumPrivacy")
    }
    
    @IBOutlet weak var PrivacySwitch: UISwitch!
    
    @IBAction func HandlePrivacySwitchChanged(_ sender: Any)
    {
        let IsOn = PrivacySwitch.isOn
        if !IsOn
        {
            let Alert = UIAlertController(title: "Warning",
                                          message: "You disabled maximum privacy. Depending on your other settings, some identifying information may be saved on your device or in your images.",
                                          preferredStyle: UIAlertController.Style.alert)
            Alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.destructive, handler: HandlePrivacyChange))
            Alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: HandlePrivacyChange))
            present(Alert, animated: true)
        }
        else
        {
            PrivacySwitch.isOn = IsOn
            PrivacyManager.SetMaximumPrivacy(To: true)
        }
    }
    
    @objc func HandlePrivacyChange(_ Action: UIAlertAction)
    {
        switch Action.title
        {
        case "Continue":
            PrivacyManager.SetMaximumPrivacy(To: false)
            
        case "Cancel":
            PrivacyManager.SetMaximumPrivacy(To: true)
            
        default:
            break
        }
    }
}
