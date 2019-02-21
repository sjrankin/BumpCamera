//
//  AboutCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class AboutCode: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        
        VersionLabel.text = Versioning.MakeVersionString()
        #if DEBUG
        VersionLabel.textColor = UIColor.red
        #endif
        BuildLabel.text = "\(Versioning.Build)"
        BuildDateLabel.text = Versioning.BuildDate + " " + Versioning.BuildTime
        BuildIDLabel.text = Versioning.BuildID
    }
    
    @IBOutlet weak var VersionLabel: UILabel!
    @IBOutlet weak var BuildLabel: UILabel!
    @IBOutlet weak var BuildDateLabel: UILabel!
    @IBOutlet weak var BuildIDLabel: UILabel!
}
