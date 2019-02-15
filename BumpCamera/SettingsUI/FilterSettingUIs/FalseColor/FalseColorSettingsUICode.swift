//
//  FalseColorSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class FalseColorSettingsUICode: FilterSettingUIBase, ColorPickerProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.FalseColor)
        let Color1 = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.red)
        print("Color1=\(Color1)")
        let Color2 = ParameterManager.GetColor(From: FilterID, Field: .Color1, Default: UIColor.yellow)
        print("Color2=\(Color2)")
        MakeNiceSample(Color1Sample, WithColor: Color1)
        MakeNiceSample(Color2Sample, WithColor: Color2)
        ShowSampleView()
    }
    
    func MakeNiceSample(_ Sample: UIView, WithColor: UIColor)
    {
        Sample.layer.borderColor = UIColor.black.cgColor
        Sample.layer.borderWidth = 0.5
        Sample.layer.cornerRadius = 5.0
        Sample.backgroundColor = WithColor
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColor1ColorPicker":
            let EditMe = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.red)
            print("Edit color 1 = \(EditMe)")
            if let Dest = segue.destination as? ColorPicker
            {
                Dest.delegate = self
                Dest.ColorToEdit(EditMe, Tag: "Color1")
            }
            else
            {
                print("Error getting destination from segue.")
                return
            }
            
        case "ToColor2ColorPicker":
            let EditMe = ParameterManager.GetColor(From: FilterID, Field: .Color1, Default: UIColor.red)
            print("Edit color 2 = \(EditMe)")
            if let Dest = segue.destination as? ColorPicker
            {
                Dest.delegate = self
                Dest.ColorToEdit(EditMe, Tag: "Color2")
            }
            else
            {
                print("Error getting destination from segue.")
                return
            }
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
    
    //Not implemented.
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            if let TagString = Tag as? String
            {
                switch TagString
                {
                case "Color1":
                    Color1Sample.backgroundColor = NewColor
                    MakeNiceSample(Color1Sample, WithColor: NewColor)
                    UpdateValue(WithValue: NewColor, ToField: .Color0)
                    ShowSampleView()
                    
                case "Color2":
                    Color2Sample.backgroundColor = NewColor
                    MakeNiceSample(Color2Sample, WithColor: NewColor)
                    UpdateValue(WithValue: NewColor, ToField: .Color1)
                    ShowSampleView()
                    
                default:
                    break
                }
            }
        }
    }
    
    @IBOutlet weak var Color1Sample: UIView!
    @IBOutlet weak var Color2Sample: UIView!
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomeButton(_ sender: Any)
    {
    }
}
