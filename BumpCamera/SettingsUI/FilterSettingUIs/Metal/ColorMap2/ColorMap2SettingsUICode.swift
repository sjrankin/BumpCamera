//
//  ColorMap2SettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorMap2SettingsUICode: FilterSettingUIBase, UIPickerViewDelegate, UIPickerViewDataSource, GradientPickerProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.ColorMap2)
        
        GradientSample.layer.borderColor = UIColor.black.cgColor
        GradientSample.layer.borderWidth = 0.5
        GradientSample.layer.cornerRadius = 5.0
        
        GradientPicker.delegate = self
        GradientPicker.dataSource = self
        
        InvertGradientSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .InvertColorMapGradient, Default: false)
        InvertSourceColorSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .InvertColorMapSourceColor, Default: false)
        UserGradient = _Settings.string(forKey: "UserGradient")!
        GradientsForPicker.append(("User", UserGradient))
        SelectItem(ParameterManager.GetString(From: FilterID, Field: .ColorMapGradient, Default: ""))
        LoadUIContents()
    }
    
    func SelectItem(_ RawValue: String)
    {
        var Index = 0
        for (_, Gradient) in GradientsForPicker
        {
            if Gradient.lowercased() == RawValue.lowercased()
            {
                GradientPicker.selectRow(Index, inComponent: 0, animated: true)
                StandardIndex = Index
                return
            }
            Index = Index + 1
        }
        GradientPicker.selectRow(0, inComponent: 0, animated: true)
    }
    
    var UserGradient: String = ""
    var StandardIndex: Int = 0
    
    /// Neede to make sure the sample gradient fits in the provided view.
    override func viewDidLayoutSubviews()
    {
        LoadUIContents()
    }
    
    func LoadUIContents()
    {
        let DoInvert = InvertGradientSwitch.isOn
        let (Name, RawGradient) = GradientsForPicker[StandardIndex]
        if Name == "User"
        {
            if UserGradient.isEmpty
            {
                UserGradient = "(Green)@(0.0),(Brown)@(1.0)"
                _Settings.set(UserGradient, forKey: "UserGradient")
            }
                let SampleGradient = GradientParser.CreateGradientImage(From: UserGradient,
                                                                        WithFrame: GradientSample.bounds,
                                                                        IsVertical: true, ReverseColors: DoInvert)
                GradientSample.image = SampleGradient
        }
        else
        {
            let SampleGradient = GradientParser.CreateGradientImage(From: RawGradient,
                                                                    WithFrame: GradientSample.bounds,
                                                                    IsVertical: true, ReverseColors: DoInvert)
            GradientSample.image = SampleGradient
        }
    }
    
    var GradientsForPicker: [(String, String)] =
        [
            ("White to Black", "(White)@(0.0),(Black)@(1.0)"),
            ("White to Red", "(White)@(0.0),(Red)@(1.0)"),
            ("White to Green", "(White)@(0.0),(Green)@(1.0)"),
            ("White to Blue", "(White)@(0.0),(Blue)@(1.0)"),
            ("White to Cyan", "(White)@(0.0),(Cyan)@(1.0)"),
            ("White to Magenta", "(White)@(0.0),(Magenta)@(1.0)"),
            ("White to Yellow", "(White)@(0.0),(Yellow)@(1.0)"),
            ("White to Orange", "(White)@(0.0),(Orange)@(1.0)"),
            ("White to Indigo", "(White)@(0.0),(Indigo)@(1.0)"),
            ("White to Violet", "(White)@(0.0),(Violet)@(1.0)"),
            ("Black to Red", "(Black)@(0.0),(Red)@(1.0)"),
            ("Black to Green", "(Black)@(0.0),(Green)@(1.0)"),
            ("Black to Blue", "(Black)@(0.0),(Blue)@(1.0)"),
            ("Black to Cyan", "(Black)@(0.0),(Cyan)@(1.0)"),
            ("Black to Magenta", "(Black)@(0.0),(Magenta)@(1.0)"),
            ("Black to Yellow", "(Black)@(0.0),(Yellow)@(1.0)"),
            ("Red to Yellow", "(Red)@(0.0),(Yellow)@(1.0)"),
            ("Red to Orange", "(Red)@(0.0),(Orange)@(1.0)"),
            ("Gold to Yellow", "(Gold)@(0.0),(Yellow)@(1.0)"),
            ("Blue to Green", "(Blue)@(0.0),(Green)@(1.0)"),
            ("Red Green Blue", "(Red)@(0.0),(Green)@(0.5),(Blue)@(1.0)"),
            ("Metallic", "(White)@(0.0),(DarkGray)@(0.25),(White)@(0.5),(DarkGray)@(0.75),(White)@(1.0)"),
            ("Cyan Magenta Yellow Black", "(Cyan)@(0.0),(Magenta)@(0.33),(Yellow)@(0.66),(Black)@(1.0)"),
            ("Rainbow", "(Red)@(0.0),(Orange)@(0.18),(Yellow)@(0.36),(Green)@(0.52),(Blue)@(0.68),(Indigo)@(0.84),(Violet)@(1.0)"),
    ]
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return GradientsForPicker[row].0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return GradientsForPicker.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        StandardIndex = row
            UpdateValue(WithValue: GradientsForPicker[StandardIndex].1, ToField: .ColorMapGradient)
        ShowSampleView()
        LoadUIContents()
    }
    
    @IBAction func HandleInversionChanged(_ sender: Any)
    {
        UpdateValue(WithValue: InvertGradientSwitch.isOn, ToField: .InvertColorMapGradient)
        ShowSampleView()
        LoadUIContents()
    }
    
    @IBAction func HandleSourceInversionChanged(_ sender: Any)
    {
        UpdateValue(WithValue: InvertSourceColorSwitch.isOn, ToField: .InvertColorMapSourceColor)
        ShowSampleView()
        LoadUIContents()
    }
    
    func EditedGradient(_ Edited: String?, Tag: Any?)
    {
        if let EditedGradient = Edited
        {
            if let PassedTag = Tag as? String
            {
                if PassedTag == "ColorMap2"
                {
                    GradientsForPicker.removeLast()
                    GradientsForPicker.append(("User", EditedGradient))
                }
            }
        }
    }
    
    func GradientToEdit(_ EditMe: String?, Tag: Any?)
    {
        //Not used in this class.
    }
    
    func SetStop(StopColor: UIColor?, StopLocation: Double?)
    {
        //Not used in this class.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToGradientDesigner":
            if let Dest = segue.destination as? GradientEditorUICode
            {
                Dest.ParentDelegate = self
                Dest.GradientToEdit(UserGradient, Tag: "ColorMap2")
            }
            
        default:
            break
        }
        super.prepare(for: segue, sender: self)
    }
    
    @IBOutlet weak var GradientPicker: UIPickerView!
    @IBOutlet weak var GradientSample: UIImageView!
    @IBOutlet weak var InvertGradientSwitch: UISwitch!
    @IBOutlet weak var InvertSourceColorSwitch: UISwitch!
}
