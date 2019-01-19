//
//  BoolFieldCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class BoolFieldCell: UITableViewCell
{
    public static var CellHeight: CGFloat = 100.0
    
    var ParentDelegate: NewFieldSettingProtocol? = nil
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
    }
    
    public func Populate(InputField: RenderPacket.InputFields, InitialValue: Bool?, Title: String)
    {
        Field = InputField
        BooleanLabel.text = Title
        if InitialValue == nil
        {
            EnableCellSwitch.isOn = false
            UpdateUIForEnable(IsEnabled: false)
        }
        else
        {
            EnableCellSwitch.isOn = true
            UpdateUIForEnable(IsEnabled: true)
            BooleanValueSwitch.isOn = InitialValue!
        }
    }
    
    var Field: RenderPacket.InputFields!
    
    @IBOutlet weak var BooleanValueSwitch: UISwitch!
    
    @IBAction func HandleBooleanValueChanged(_ sender: Any)
    {
        let IsOn = BooleanValueSwitch.isOn
        ParentDelegate?.NewFieldSetting(InputField: Field, NewValue: IsOn as Any?)
    }
    
    @IBOutlet weak var BooleanLabel: UILabel!
    
    @IBAction func HandleEnableCellChanged(_ sender: Any)
    {
        let IsEnabled = EnableCellSwitch.isOn
        UpdateUIForEnable(IsEnabled: IsEnabled)
        if IsEnabled
        {
            ParentDelegate?.NewFieldSetting(InputField: Field, NewValue: BooleanValueSwitch.isOn as Any?)
        }
        else
        {
            ParentDelegate?.NewFieldSetting(InputField: Field, NewValue: nil as Any?)
        }
    }
    
    func UpdateUIForEnable(IsEnabled: Bool)
    {
        BooleanLabel.isEnabled = IsEnabled
        BooleanValueSwitch.isEnabled = IsEnabled
    }
    
    @IBOutlet weak var EnableCellSwitch: UISwitch!
}
