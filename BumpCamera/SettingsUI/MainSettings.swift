//
//  MainSettings.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MainSettings: UITableViewController
{
    let _Settings = UserDefaults.standard
    var FilterName: String = ""
    let Filters = FilterManager()
    var CurrentFilter: FilterManager.FilterTypes? = FilterManager.FilterTypes.NotSet
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let FilterIDString = _Settings.string(forKey: "CurrentFilter")
        let FilterID = UUID(uuidString: FilterIDString!)
        CurrentFilter = Filters.GetFilterFrom(ID: FilterID!)
        if CurrentFilter == nil
        {
            CurrentFilter = FilterManager.FilterTypes.NotSet
        }
        FilterName = Filters.GetFilterTitle(CurrentFilter!)
        #if true
        FilterTitleLabel.text = "Settings for " + FilterName
        #else
        if Filters.FilterHasParameters(CurrentFilter!)
        {
            if CurrentFilter == FilterManager.FilterTypes.NotSet
            {
                FilterTitleLabel.text = "Unknown Filter"
            }
            else
            {
                FilterTitleLabel.text = "Settings for " + FilterName
            }
        }
        else
        {
            FilterTitleLabel.text = "\"" + FilterName + "\" has no settings"
            FilterTitleLabel.isEnabled = false
        }
        #endif
        HideFilterNameSwitch.isOn = _Settings.bool(forKey: "HideFilterName")
        SaveOriginalSwitch.isOn = _Settings.bool(forKey: "SaveOriginalImage")
        ConfirmSaveSwitch.isOn = _Settings.bool(forKey: "ShowSaveAlert")
        HideFiltersSwitch.isOn = _Settings.bool(forKey: "HideFilterSelectionUI")
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
    
    @IBAction func HandleDoneButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var FilterTitleLabel: UILabel!
    
    @IBAction func HideFiltersChanged(_ sender: Any)
    {
        _Settings.set(HideFiltersSwitch.isOn, forKey: "HideFilterSelectionUI")
    }
    
    @IBOutlet weak var HideFiltersSwitch: UISwitch!
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        return true
    }
}
