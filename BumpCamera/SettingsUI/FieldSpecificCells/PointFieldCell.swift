//
//  PointFieldCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class PointFieldCell: UITableViewCell
{
    public static var CellHeight: CGFloat = 140.0
    
    var ParentDelegate: NewFieldSettingProtocol? = nil
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
        OriginalBGColor = XLabel.backgroundColor
    }
    
    var OriginalBGColor: UIColor!
    
    public func Populate(InputField: RenderPacket.InputFields, InitialValue: CGPoint?, Title: String)
    {
        Field = InputField
        InputLabel.text = Title
        if InitialValue == nil
        {
            EnableCellSwitch.isOn = false
            UpdateforEnableChange(EnableState: false)
        }
        else
        {
            EnableCellSwitch.isOn = true
            UpdateforEnableChange(EnableState: true)
            Point = InitialValue!
            let IsCentered = Point.x < 0.0 && Point.y < 0.0
            UpdateUIForCentered(AutoCenter: IsCentered)
        }
    }
    
    var Point: CGPoint = CGPoint.zero
    
    @IBOutlet weak var YInput: UITextField!
    @IBOutlet weak var XInput: UITextField!
    @IBOutlet weak var YLabel: UILabel!
    @IBOutlet weak var XLabel: UILabel!
    @IBOutlet weak var InputLabel: UILabel!
    @IBOutlet weak var CenterInImageLabel: UILabel!
    
    @IBAction func HandleNewXValue(_ sender: Any)
    {
        if let TextValue = XInput.text
        {
            if let DValue = Double(TextValue)
            {
                let Final = CGFloat(DValue)
                Point.x = Final
                ParentDelegate?.NewFieldSetting(InputField: Field, NewValue: Point as Any?)
            }
            else
            {
                SetInvalidText(For: sender as! UITextView)
            }
        }
        else
        {
            SetInvalidText(For: sender as! UITextView)
        }
    }
    
    @IBAction func HandleNewYValue(_ sender: Any)
    {
        if let TextValue = YInput.text
        {
            if let DValue = Double(TextValue)
            {
                let Final = CGFloat(DValue)
                Point.y = Final
                ParentDelegate?.NewFieldSetting(InputField: Field, NewValue: Point as Any?)
            }
            else
            {
                SetInvalidText(For: sender as! UITextView)
            }
        }
        else
        {
            SetInvalidText(For: sender as! UITextView)
        }
    }
    
    func SetInvalidText(For: UITextView)
    {
        ForField = For
        For.text = ""
        For.backgroundColor = UIColor(named: "Pink")
        UIView.animate(withDuration: 1.0)
        {
            self.ForField.backgroundColor = self.OriginalBGColor
        }
    }
    
    var ForField: UITextView!
    
    @IBOutlet weak var CenterInImageSwitch: UISwitch!
    
    @IBAction func HandleCenterInImageChanged(_ sender: Any)
    {
        let DoAutoCenter = CenterInImageSwitch.isOn
        UpdateUIForCentered(AutoCenter: DoAutoCenter)
        if DoAutoCenter
        {
            ParentDelegate?.NewFieldSetting(InputField: Field, NewValue: CGPoint(x: -1, y: -1) as Any)
        }
        else
        {
            ParentDelegate?.NewFieldSetting(InputField: Field, NewValue: Point as Any)
        }
    }
    
    func UpdateUIForCentered(AutoCenter: Bool)
    {
        XInput.isEnabled = AutoCenter
        XLabel.isEnabled = AutoCenter
        YInput.isEnabled = AutoCenter
        YLabel.isEnabled = AutoCenter
        InputLabel.isEnabled = AutoCenter
    }
    
    @IBAction func HandleEnableCellChanged(_ sender: Any)
    {
        UpdateforEnableChange(EnableState: EnableCellSwitch.isOn)
        ParentDelegate?.NewFieldSetting(InputField: Field, NewValue: nil)
    }
    
    func UpdateforEnableChange(EnableState: Bool)
    {
        XInput.isEnabled = EnableState
        YInput.isEnabled = EnableState
        XLabel.isEnabled = EnableState
        YLabel.isEnabled = EnableState
        InputLabel.isEnabled = EnableState
        CenterInImageLabel.isEnabled = EnableState
        CenterInImageSwitch.isEnabled = EnableState
    }
    
    @IBOutlet weak var EnableCellSwitch: UISwitch!
    
    var Field: RenderPacket.InputFields!
}

extension UITextField
{
    //https://medium.com/swift2go/swift-add-keyboard-done-button-using-uitoolbar-c2bea50a12c7
    @IBInspectable var DoneAccessory: Bool
        {
        get
        {
            return self.DoneAccessory
        }
        set(HasDone)
        {
            if HasDone
            {
                AddDoneButton()
            }
        }
    }
    
    func AddDoneButton()
    {
        let DoneToolBar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        DoneToolBar.barStyle = .default
        let FlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let DoneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.DoneButtonPressed))
        let Items = [FlexSpace, DoneButton]
        DoneToolBar.items = Items
        DoneToolBar.sizeToFit()
        self.inputAccessoryView = DoneToolBar
    }
    
    @objc func DoneButtonPressed()
    {
        self.resignFirstResponder()
    }
}
