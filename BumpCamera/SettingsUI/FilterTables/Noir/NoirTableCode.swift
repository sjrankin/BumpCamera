//
//  NoirTableCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class NoirTableCode: FilterTableBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
}
