//
//  HelpUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HelpUICode: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    @IBAction func HandleBackButtonPressed(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
//        dismiss(animated: true, completion: nil)
    }
}
