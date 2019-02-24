//
//  DirectorySettings.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class DirectorySettings: UITableViewController
{
    let _Settings = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        ClearRuntimeSwitch.isOn = _Settings.bool(forKey: "ClearRuntimeAtStartup")
        ClearScratchSwitch.isOn = _Settings.bool(forKey: "ClearScratchAtStartup")
    }
    
    @IBAction func HandleClearRuntimeChanged(_ sender: Any)
    {
        _Settings.set(ClearRuntimeSwitch.isOn, forKey: "ClearRuntimeAtStartup")
    }
    
    @IBAction func HandleClearScratchChanged(_ sender: Any)
    {
        _Settings.set(ClearScratchSwitch.isOn, forKey: "ClearScratchAtStartup")
    }
    
    @IBOutlet weak var ClearRuntimeSwitch: UISwitch!

    @IBOutlet weak var ClearScratchSwitch: UISwitch!
    
    
    @IBAction func HandleClearRuntimeNow(_ sender: Any)
    {
        FileHandler.ClearDirectory(FileHandler.RuntimeDirectory)
        ShowClearedMessage("Runtime directory cleared.", WithTitle: "Directory Cleared")
    }
    
    @IBAction func ClearPerformanceNow(_ sender: Any)
    {
        FileHandler.ClearDirectory(FileHandler.PerformanceDirectory)
        ShowClearedMessage("Performance directory cleared.", WithTitle: "Directory Cleared")
    }
    
    @IBAction func ClearSamplesNow(_ sender: Any)
    {
        FileHandler.ClearDirectory(FileHandler.SampleDirectory)
        ShowClearedMessage("User sample image directory cleared.", WithTitle: "Directory Cleared")
    }
    
    @IBAction func ClearScratchNow(_ sender: Any)
    {
        FileHandler.ClearDirectory(FileHandler.ScratchDirectory)
        ShowClearedMessage("Scratch directory cleared.", WithTitle: "Directory Cleared")
    }
    
    func ShowClearedMessage(_ Message: String, WithTitle: String)
    {
        let Alert = UIAlertController(title: WithTitle, message: Message, preferredStyle: UIAlertController.Style.alert)
        Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        present(Alert, animated: true)
    }
}
