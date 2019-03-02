//
//  ColorPicker2Code.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorPicker2: UITableViewController, GSliderProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        SampleColorView.layer.borderWidth = 0.5
        SampleColorView.layer.borderColor = UIColor.black.cgColor
        SampleColorView.layer.cornerRadius = 5.0
        
        LeftLabel.text = "Red"
        RightLabel.text = "Blue"
        BottomLabel.text = "Green"
        
        LeftSlider.ParentDelegate = self
        LeftSlider.Name = "Red"
        RightSlider.ParentDelegate = self
        RightSlider.Name = "Blue"
        BottomSlider.ParentDelegate = self
        BottomSlider.Name = "Green"
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        LeftSlider.Refresh(SliderName: LeftSlider.Name, WithRect: LeftSlider.frame)
        RightSlider.Refresh(SliderName: RightSlider.Name, WithRect: RightSlider.frame)
        BottomSlider.Refresh(SliderName: BottomSlider.Name, WithRect: BottomSlider.frame)
    }
    
    func NewSliderValue(Name: String, NewValue: Double)
    {
        print("New slider value \(NewValue) from \(Name).")
    }
    
    @IBAction func HandleCancelButton(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
        //dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleDoneButton(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
        //dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var LeftSlider: GSlider!
    @IBOutlet weak var RightSlider: GSlider!
    @IBOutlet weak var BottomSlider: GSlider!
    @IBOutlet weak var SampleColorView: UIView!
    @IBOutlet weak var ColorNameLabel: UILabel!
    @IBOutlet weak var ColorValueLabel: UILabel!
    @IBOutlet weak var LeftLabel: UILabel!
    @IBOutlet weak var RightLabel: UILabel!
    @IBOutlet weak var BottomLabel: UILabel!
    
    @IBOutlet weak var Test: UIView!
}
