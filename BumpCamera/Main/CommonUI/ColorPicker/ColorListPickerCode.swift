//
//  ColorListPickerCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/14/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorListPickerCode: UITableViewController, ColorPickerProtocol, UIPickerViewDelegate, UIPickerViewDataSource
{
    let _Settings = UserDefaults.standard
    var ParentDelegate: ColorPickerProtocol? = nil
    var SelectedColor: UIColor!
    var ParentTag: Any? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        NearestColorSwitch.isOn = _Settings.bool(forKey: "ShowClosestColor")
        tableView.tableFooterView = UIView()
        ColorSample.layer.borderColor = UIColor.black.cgColor
        ColorSample.layer.borderWidth = 0.5
        ColorSample.layer.cornerRadius = 5.0
        UpdateSelectedColor(WithColor: UIColor.yellow)
        ColorGroups = PredefinedColors.GetColorGroupNames()
        ColorGroupColors = PredefinedColors.GetColorsIn(Group: ColorGroups[0])
        ColorGroupColors = PredefinedColors.SortColorList(ColorGroupColors, By: PredefinedColors.ColorOrders.Name)
        ColorPickerView.delegate = self
        ColorPickerView.dataSource = self
        ColorPickerView.reloadAllComponents()
        if _Settings.bool(forKey: "ShowClosestColor")
        {
            SelectClosestColor(SelectedColor)
        }
    }
    
    var ColorGroups: [String]!
    var ColorGroupColors: [PredefinedColor]!
    
    func SelectClosestColor(_ Color: UIColor)
    {
        var GroupCloseness = [String: (Int, Double)]()
        for GroupName in ColorGroups
        {
            let Colors = PredefinedColors.GetColorsIn(Group: GroupName)
            if let (Index, Distance) = PredefinedColors.GetClosestColorInEx(Group: Colors, ToColor: Color)
            {
                GroupCloseness[GroupName] = (Index, Distance)
            }
        }
        var ShortestIndex = Int.max
        var ShortestName = ""
        var ShortestDistance = Double.greatestFiniteMagnitude
        for (Name, Values) in GroupCloseness
        {
            if Values.1 < ShortestDistance
            {
                ShortestName = Name
                ShortestDistance = Values.1
                ShortestIndex = Values.0
            }
        }
        if let FullColor = PredefinedColors.GetColorIn(Group: ShortestName, At: ShortestIndex)
        {
            print("Cloest color to \(Utility.ColorToString(Color)) is \(FullColor.ColorName) in \(ShortestName)")
            let GroupIndex = ColorGroups.index(of: ShortestName)
            ColorPickerView.selectRow(GroupIndex!, inComponent: 0, animated: true)
            ColorGroupColors = PredefinedColors.GetColorsIn(Group: ColorGroups[GroupIndex!])
            ColorGroupColors = PredefinedColors.SortColorList(ColorGroupColors, By: PredefinedColors.ColorOrders.Name)
            ColorPickerView.reloadComponent(1)
            var Index = 0
            for SomeColor in ColorGroupColors
            {
                if SomeColor.Color == Color
                {
                    ColorPickerView.selectRow(Index, inComponent: 1, animated: true)
                    UpdateSelectedColor(WithColor: SomeColor)
                }
                Index = Index + 1
            }
        }
    }
    
    func UpdateColorValues(_ Color: UIColor)
    {
        var Red: CGFloat = 0.0
        var Green: CGFloat = 0.0
        var Blue: CGFloat = 0.0
        var NotUsed: CGFloat = 0.0
        Color.getRed(&Red, green: &Green, blue: &Blue, alpha: &NotUsed)
        let IRed = Int(Red * 255.0)
        let IGreen = Int(Green * 255.0)
        let IBlue = Int(Blue * 255.0)
        let RGBString = "\(IRed),\(IGreen),\(IBlue)"
        RGBout.text = RGBString
        let RedX = String(format: "%02x", IRed)
        let GreenX = String(format: "%02x", IGreen)
        let BlueX = String(format: "%02x", IBlue)
        let HexString = "0x\(RedX)\(GreenX)\(BlueX)"
        HexOut.text = HexString
    }
    
    func UpdateSelectedColor(WithColor: UIColor)
    {
        SelectedColor = WithColor
        ColorSample.backgroundColor = SelectedColor
        ColorSampleName.text = "not found in color list"
        UpdateColorValues(WithColor)
    }
    
    func UpdateSelectedColor(WithColor: PredefinedColor)
    {
        SelectedColor = WithColor.Color
        ColorSample.backgroundColor = SelectedColor
        ColorSampleName.text = WithColor.ColorName
        UpdateColorValues(WithColor.Color)
    }
    
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
        SelectedColor = Color
        ParentTag = Tag
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        //Not used here.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
    {
        let FullWidth = ColorPickerView.frame.width
        if component == 0
        {
            return FullWidth * 0.35
        }
        else
        {
            return FullWidth * 0.65
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if component == 0
        {
            return ColorGroups.count
        }
        return ColorGroupColors.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if component == 0
        {
            return ColorGroups[row]
        }
        else
        {
            return ColorGroupColors[row].ColorName
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if component == 0
        {
            ColorGroupColors = PredefinedColors.GetColorsIn(Group: ColorGroups[row])
            ColorGroupColors = PredefinedColors.SortColorList(ColorGroupColors, By: PredefinedColors.ColorOrders.Name)
            pickerView.reloadComponent(1)
            if _Settings.bool(forKey: "ShowClosestColor")
            {
                let NewColorIndex = PredefinedColors.GetClosestColorIn(Group: ColorGroupColors, ToColor: SelectedColor)
                ColorPickerView.selectRow(NewColorIndex!, inComponent: 1, animated: true)
                UpdateSelectedColor(WithColor: ColorGroupColors[NewColorIndex!])
            }
        }
        else
        {
            let SelectedColor = ColorGroupColors[row]
            UpdateSelectedColor(WithColor: SelectedColor)
        }
    }
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        ParentDelegate?.EditedColor(SelectedColor, Tag: ParentTag)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func HandleCancelButton(_ sender: Any)
    {
        ParentDelegate?.EditedColor(nil, Tag: ParentTag)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func HandleNearestColorSwitchChanged(_ sender: Any)
    {
        _Settings.set(NearestColorSwitch.isOn, forKey: "ShowClosestColor")
    }
    
    @IBOutlet weak var NearestColorSwitch: UISwitch!
    @IBOutlet weak var RGBout: UILabel!
    @IBOutlet weak var HexOut: UILabel!
    @IBOutlet weak var ColorSampleName: UILabel!
    @IBOutlet weak var ColorSample: UIView!
    @IBOutlet weak var ColorPickerView: UIPickerView!
}
