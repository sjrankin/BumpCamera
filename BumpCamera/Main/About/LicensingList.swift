//
//  LicensingList.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class LicensingList: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let Cell = tableView.cellForRow(at: indexPath)
        {
            LicenseIndex = Cell.tag
            performSegue(withIdentifier: "ToLicenseViewer", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let Title = LicenseMap[LicenseIndex]
        {
            if let LicenseInfo = Licenses.GetLicense(For: Title)
            {
                if let Dest = segue.destination as? LicenseViewer
                {
                    Dest.SetLicenseInfo(LicenseInfo)
                }
            }
            else
            {
                print("Could not find licensing information for \(Title)")
            }
        }
        else
        {
            print("LicenseMap does not contain key \(LicenseIndex)")
        }
        super.prepare(for: segue, sender: self)
    }
    
    var LicenseIndex: Int = 0
    
    let LicenseMap: [Int: String] =
        [
            1: "SystemKit",
            2: "Filterpedia"
    ]
}
