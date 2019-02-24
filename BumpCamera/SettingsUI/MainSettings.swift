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
        CurrentFilter = Filters.GetFilterTypeFrom(ID: FilterID!)
        if CurrentFilter == nil
        {
            CurrentFilter = FilterManager.FilterTypes.NotSet
        }
        FilterName = Filters.GetFilterTitle(CurrentFilter!)
        CurrentFilterLabel.text = "Current: " + FilterName

        if PrivacyManager.InMaximumPrivacy()
        {
            SaveUserImagesTitle.isEnabled = false
            CanSaveUserSampleImagesSwitch.isEnabled = false
            CanSaveUserSampleImagesSwitch.isOn = false
        }
        
        let Cells = tableView.visibleCells 
        for Cell in Cells
        {
            if Cell.tag == 1010
            {
                Cell.selectionStyle = .none
                break
            }
        }
        
        #if false
        #else
        self.tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: UITableView.RowAnimation.automatic)
        self.tableView.reloadData()
        #endif
    }
    
    @IBAction func HandleDoneButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var FilterTitleLabel: UILabel!
    
    @IBOutlet weak var CurrentFilterLabel: UILabel!
    
    @IBOutlet weak var SaveUserImagesTitle: UILabel!
    @IBOutlet weak var CanSaveUserSampleImagesSwitch: UISwitch!
    
    @IBAction func HandleSaveUserImagesChanged(_ sender: Any)
    {
        _Settings.set(CanSaveUserSampleImagesSwitch.isOn, forKey: "AllowUserSampleImages")
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let Cell = tableView.cellForRow(at: indexPath)
        if Cell!.tag == 1010
        {
            if let StoryboardName = FilterManager.StoryboardFor(CurrentFilter!)
            {
                let Storyboard = UIStoryboard(name: StoryboardName, bundle: nil)
                if let Controller = Storyboard.instantiateViewController(withIdentifier: StoryboardName) as? UINavigationController
                {
                    _Settings.set(CurrentFilter!.rawValue, forKey: "SetupForFilterType")
                    self.present(Controller, animated: true, completion: nil)
                }
            }
        }
    }
}
