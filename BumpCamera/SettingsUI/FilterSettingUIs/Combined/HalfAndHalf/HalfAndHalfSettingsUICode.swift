//
//  HalfAndHalfSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HalfAndHalfSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.HalfAndHalf)
        
        FormatSegment.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .HaHOrientation, Default: 0)
        BlendingSegment.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .HaHBlending, Default: 0)
        
        LeftView.backgroundColor = UIColor.white
        LeftView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        LeftView.layer.cornerRadius = 5.0
        LeftView.layer.borderColor = UIColor.black.cgColor
        LeftView.layer.borderWidth = 0.5
        
        RightView.backgroundColor = UIColor.white
        RightView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMinYCorner]
        RightView.layer.cornerRadius = 5.0
        RightView.layer.borderColor = UIColor.black.cgColor
        RightView.layer.borderWidth = 0.5
        
        TopView.backgroundColor = UIColor.white
        TopView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        TopView.layer.cornerRadius = 5.0
        TopView.layer.borderColor = UIColor.black.cgColor
        TopView.layer.borderWidth = 0.5
        
        BottomView.backgroundColor = UIColor.white
        BottomView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        BottomView.layer.cornerRadius = 5.0
        BottomView.layer.borderColor = UIColor.black.cgColor
        BottomView.layer.borderWidth = 0.5
        
        SetUI()
    }
    
    @objc func LeftTapped(Tapped: UITapGestureRecognizer)
    {
        if FormatSegment.selectedSegmentIndex != 0
        {
            return
        }
    }
    
    @objc func RightTapped(Tapped: UITapGestureRecognizer)
    {
        if FormatSegment.selectedSegmentIndex != 0
        {
            return
        }
    }
    
    @objc func TopTapped(Tapped: UITapGestureRecognizer)
    {
        if FormatSegment.selectedSegmentIndex != 1
        {
            return
        }
    }
    
    @objc func BottomTapped(Tapped: UITapGestureRecognizer)
    {
        if FormatSegment.selectedSegmentIndex != 1
        {
            return
        }
    }
    
    func SetUI()
    {
        let IsHorizontal = FormatSegment.selectedSegmentIndex == 0
        LeftLabel.isEnabled = IsHorizontal
        RightLabel.isEnabled = IsHorizontal
        TopLabel.isEnabled = !IsHorizontal
        BottomLabel.isEnabled = !IsHorizontal
    }
    
    @IBAction func HandleOrientationChanged(_ sender: Any)
    {
        UpdateValue(WithValue: FormatSegment.selectedSegmentIndex, ToField: .HaHOrientation)
        SetUI()
    }
    
    @IBOutlet weak var FormatSegment: UISegmentedControl!
    
    @IBAction func HandleBlendingChanged(_ sender: Any)
    {
        UpdateValue(WithValue: BlendingSegment.selectedSegmentIndex, ToField: .HaHBlending)
    }
    
    @IBOutlet weak var BlendingSegment: UISegmentedControl!
    
    @IBOutlet weak var LeftView: UIView!
    @IBOutlet weak var RightView: UIView!
    @IBOutlet weak var TopView: UIView!
    @IBOutlet weak var BottomView: UIView!
    @IBOutlet weak var LeftLabel: UILabel!
    @IBOutlet weak var RightLabel: UILabel!
    @IBOutlet weak var TopLabel: UILabel!
    @IBOutlet weak var BottomLabel: UILabel!
}
