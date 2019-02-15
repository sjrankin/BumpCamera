//
//  LicenseViewer.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class LicenseViewer: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        LicenseText.text = LicensingInfo?.LicenseText
        LicenseUse.text = LicensingInfo?.Usage
        LicenceTitle.text = LicensingInfo?.SoftwareTitle
        LicenseHolder.text = LicensingInfo?.LicenseHolder
    }
    
    var LicensingInfo: License? = nil
    
    func SetLicenseInfo(_ Info: License)
    {
        LicensingInfo = Info
    }
    
    @IBOutlet weak var LicenceTitle: UILabel!
    @IBOutlet weak var LicenseHolder: UILabel!
    @IBOutlet weak var LicenseText: UITextView!
    @IBOutlet weak var LicenseUse: UITextView!
}
