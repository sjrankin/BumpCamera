//
//  CombinedFilterSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/22/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class CombinedfilterSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.NotSet)
        
        Quadrant1.layer.maskedCorners = [.layerMinXMinYCorner]
        Quadrant1.layer.cornerRadius = 5.0
        Quadrant1.layer.borderWidth = 0.5
        Quadrant1.layer.borderColor = UIColor.black.cgColor
        Quadrant1.backgroundColor = UIColor.white
        let Q1Tap = UITapGestureRecognizer(target: self, action: #selector(HandleQ1Tap))
        Quadrant1.addGestureRecognizer(Q1Tap)
        
        Quadrant2.layer.maskedCorners = [.layerMaxXMinYCorner]
        Quadrant2.layer.cornerRadius = 5.0
        Quadrant2.layer.borderWidth = 0.5
        Quadrant2.layer.borderColor = UIColor.black.cgColor
        Quadrant2.backgroundColor = UIColor.white
        let Q2Tap = UITapGestureRecognizer(target: self, action: #selector(HandleQ2Tap))
        Quadrant2.addGestureRecognizer(Q2Tap)
        
        Quadrant3.layer.maskedCorners = [.layerMaxXMaxYCorner]
        Quadrant3.layer.cornerRadius = 5.0
        Quadrant3.layer.borderWidth = 0.5
        Quadrant3.layer.borderColor = UIColor.black.cgColor
        Quadrant3.backgroundColor = UIColor.white
        let Q3Tap = UITapGestureRecognizer(target: self, action: #selector(HandleQ3Tap))
        Quadrant3.addGestureRecognizer(Q3Tap)
        
        Quadrant4.layer.maskedCorners = [.layerMinXMaxYCorner]
        Quadrant4.layer.cornerRadius = 5.0
        Quadrant4.layer.borderWidth = 0.5
        Quadrant4.layer.borderColor = UIColor.black.cgColor
        Quadrant4.backgroundColor = UIColor.white
        let Q4Tap = UITapGestureRecognizer(target: self, action: #selector(HandleQ4Tap))
        Quadrant4.addGestureRecognizer(Q4Tap)
    }
    
    @objc func HandleQ1Tap(Tap: UITapGestureRecognizer)
    {
        
    }
    
    @objc func HandleQ2Tap(Tap: UITapGestureRecognizer)
    {
        
    }
    
    @objc func HandleQ3Tap(Tap: UITapGestureRecognizer)
    {
        
    }
    
    @objc func HandleQ4Tap(Tap: UITapGestureRecognizer)
    {
        
    }
    
    @IBOutlet weak var Q4Label: UILabel!
    @IBOutlet weak var Q3Label: UILabel!
    @IBOutlet weak var Q2Label: UILabel!
    @IBOutlet weak var Q1Label: UILabel!
    @IBOutlet weak var Quadrant1: UIView!
    @IBOutlet weak var Quadrant2: UIView!
    @IBOutlet weak var Quadrant3: UIView!
    @IBOutlet weak var Quadrant4: UIView!
}
