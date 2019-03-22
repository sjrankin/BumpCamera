//
//  ExternalViewControllerCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/22/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ExternalViewControllerCode: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        FramesBox.backgroundColor = UIColor.clear
        FramesBox.layer.borderColor = UIColor.black.cgColor
        FramesBox.layer.borderWidth = 0.5
        FramesBox.layer.cornerRadius = 5.0
        
        ThermalStatusIndicator.backgroundColor = UIColor(named: "Pistachio")
        ThermalStatusIndicator.layer.borderWidth = 2.0
        ThermalStatusIndicator.layer.borderColor = UIColor.black.cgColor
        ThermalStatusIndicator.layer.cornerRadius = 5.0
    }
    
    @IBOutlet weak var FramesBox: UIView!
    @IBOutlet weak var CurrentFPS: UILabel!
    @IBOutlet weak var OverallFPS: UILabel!
    @IBOutlet weak var FrameCountLabel: UILabel!
    @IBOutlet weak var HeartBeatDisplay: UIImageView!
    @IBOutlet weak var ThermalStatusIndicator: UIView!
    @IBOutlet weak var ThermalStatusText: UILabel!
}
