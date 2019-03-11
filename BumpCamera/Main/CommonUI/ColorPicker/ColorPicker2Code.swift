//
//  ColorPicker2Code.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorPicker2: UITableViewController, GSliderProtocol, ColorPickerProtocol
{
    let _Settings = UserDefaults.standard
    weak var ParentDelegate: ColorPickerProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        SampleColorView.layer.borderWidth = 0.5
        SampleColorView.layer.borderColor = UIColor.black.cgColor
        SampleColorView.layer.cornerRadius = 5.0
        SampleColorView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        
        LeftLabel.text = "Red"
        RightLabel.text = "Blue"
        BottomLabel.text = "Green"
        
        LeftSlider.ParentDelegate = self
        LeftSlider.Name = "Red"
        RightSlider.ParentDelegate = self
        RightSlider.Name = "Blue"
        BottomSlider.ParentDelegate = self
        BottomSlider.Name = "Green"
        
        UpdateColor(WithColor: SourceColor!)
        UpdateSliders(WithColor: SourceColor!)
        
        let Colorspace = _Settings.integer(forKey: "ColorPickerColorspace")
        ColorspaceSegment.selectedSegmentIndex = Colorspace
        UpdateColorspace()
        BottomSlider.SetHueGradient(InitialSaturation: 1.0, InitialBrightness: 1.0, Steps: 36)
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        LeftSlider.Refresh(SliderName: LeftSlider.Name, WithRect: LeftSlider.frame)
        RightSlider.Refresh(SliderName: RightSlider.Name, WithRect: RightSlider.frame)
        BottomSlider.Refresh(SliderName: BottomSlider.Name, WithRect: BottomSlider.frame)
    }
    
    func UpdateColorspace()
    {
        switch _Settings.integer(forKey: "ColorPickerColorspace")
        {
        case 0:
            SetRGB()
            
        case 1:
            SetHSB()
            
        case 2:
            SetYUV()
            
        default:
            break
        }
    }
    
    func SetRGB()
    {
        LeftLabel.text = "Red"
        LeftSlider.GradientStart = UIColor.red
        LeftSlider.GradientEnd = UIColor.black
        BottomLabel.text = "Green"
        BottomSlider.GradientStart = UIColor.green
        BottomSlider.GradientEnd = UIColor.black
        RightLabel.text = "Blue"
        RightSlider.GradientStart = UIColor.blue
        RightSlider.GradientEnd = UIColor.black
    }
    
    func SetHSB()
    {
        LeftLabel.text = "Sat."
        BottomLabel.text = "Hue"
        RightLabel.text = "Bri."
    }
    
    func SetYUV()
    {
        LeftLabel.text = "Y"
        BottomLabel.text = "U"
        RightLabel.text = "V"
    }
    
    func NewSliderValue(Name: String, NewValue: Double)
    {
        print("New slider value \(NewValue) from \(Name).")
        let rvalue = CGFloat(1.0 - LeftSlider.Value)
        let gvalue = CGFloat(1.0 - BottomSlider.Value)
        let bvalue = CGFloat(1.0 - RightSlider.Value)
        let SampleColor = UIColor(red: rvalue, green: gvalue, blue: bvalue, alpha: 1.0)
        UpdateColor(WithColor: SampleColor)
    }
    
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
        ParentTag = Tag
        SourceColor = Color
    }
    
    var ParentTag: Any? = nil
    var SourceColor: UIColor? = nil
    
    func UpdateColor(WithColor: UIColor)
    {
        SampleColorView.backgroundColor = WithColor
        ColorValueLabel.text = "#" + String(format: "%02x", Int(WithColor.r * 255.0)) +
            String(format: "%02x", Int(WithColor.g * 255.0)) + String(format: "%02x", Int(WithColor.b * 255.0))
    }
    
    func UpdateSliders(WithColor: UIColor)
    {
        LeftSlider.Value = Double(WithColor.r)
        BottomSlider.Value = Double(WithColor.g)
        RightSlider.Value = Double(WithColor.b)
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            SourceColor = NewColor
            UpdateColor(WithColor: SourceColor!)
            UpdateSliders(WithColor: SourceColor!.Inverted())
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColorChipPicker":
            break
            
        case "ToColorListPicker":
            if let Dest = segue.destination as? ColorListPickerCode
            {
                Dest.ParentDelegate = self
                Dest.ColorToEdit(SourceColor!, Tag: "PickerColor")
            }
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
    
    @IBAction func HandleCancelButton(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func HandleDoneButton(_ sender: Any)
    {
        ParentDelegate?.EditedColor(SourceColor!, Tag: ParentTag)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func HandleColorNamesButton(_ sender: Any)
    {
        performSegue(withIdentifier: "ToColorListPicker", sender: self)
    }
    
    @IBAction func HandleColorChipsButton(_ sender: Any)
    {
        performSegue(withIdentifier: "ToColorChipPicker", sender: self)
    }
    
    @IBAction func HandleColorspaceChanged(_ sender: Any)
    {
        _Settings.set(ColorspaceSegment.selectedSegmentIndex, forKey: "ColorPickerColorspace")
        UpdateColorspace()
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
    @IBOutlet weak var ColorspaceSegment: UISegmentedControl!
}
