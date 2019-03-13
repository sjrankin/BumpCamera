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
        
        GradientsForPicker = GradientManager.GradientList
        
        GradientSample.layer.borderColor = UIColor.black.cgColor
        GradientSample.layer.borderWidth = 0.5
        GradientSample.layer.cornerRadius = 5.0
        
        GradientPicker.delegate = self
        GradientPicker.dataSource = self
        
        MergeSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .MergeColorMapWithSource, Default: false)
        InvertGradientSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .InvertColorMapGradient, Default: false)
        InvertSourceColorSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .InvertColorMapSourceColor, Default: false)
        UserGradient = _Settings.string(forKey: "UserGradient")!
        GradientsForPicker?.append((Gradients.User, "User", UserGradient))
        SelectItem(ParameterManager.GetString(From: FilterID, Field: .ColorMapGradient, Default: ""))
        LoadUIContents()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        let GradientIndex = IndexOfGradient(_Settings.string(forKey: "LastGradient")!)
        if GradientIndex >= 0
        {
            GradientPicker.selectRow(GradientIndex, inComponent: 0, animated: true)
        }
        else
        {
            GradientPicker.selectRow(0, inComponent: 0, animated: true)
        }
        super.viewWillAppear(animated)
    }
    
    func IndexOfGradient(_ Gradient: String) -> Int
    {
        if Gradient.isEmpty
        {
            return -1
        }
        print("Looking for index of \(Gradient)")
        for Index in 0 ..< GradientsForPicker!.count
        {
            if GradientsForPicker![Index].2 == Gradient
            {
                print("   Found at \(Index)")
                return Index
            }
        }
        print("   Not found.")
        return -1
    }
    
    func SelectItem(_ RawValue: String)
    {
        var Index = 0
        for (_, _, Gradient) in GradientsForPicker!
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
        let (_, Name, RawGradient) = GradientsForPicker![StandardIndex]
        if Name == "User"
        {
            if UserGradient.isEmpty
            {
                UserGradient = "(Green)@(0.0),(Brown)@(1.0)"
                _Settings.set(UserGradient, forKey: "UserGradient")
            }
            let SampleGradient = GradientManager.CreateGradientImage(From: UserGradient,
                                                                     WithFrame: GradientSample.bounds,
                                                                     IsVertical: true, ReverseColors: DoInvert)
            GradientSample.image = SampleGradient
        }
        else
        {
            let SampleGradient = GradientManager.CreateGradientImage(From: RawGradient,
                                                                     WithFrame: GradientSample.bounds,
                                                                     IsVertical: true, ReverseColors: DoInvert)
            GradientSample.image = SampleGradient
        }
    }
    
    var GradientsForPicker: [(Gradients, String, String)]? = nil
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return GradientsForPicker![row].1
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return GradientsForPicker!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        StandardIndex = row
        CurrentGradientContainsWhite = GradientManager.HasWhite(GradientsForPicker![row].2)
        if CurrentGradientContainsWhite
        {
            MergeSwitch.isEnabled = true
            MergeSwitchLabel.isEnabled = true
        }
        else
        {
            MergeSwitch.isEnabled = false
            MergeSwitch.isOn = false
            MergeSwitchLabel.isEnabled = false
            UpdateValue(WithValue: false, ToField: .MergeColorMapWithSource)
        }
        _Settings.set(GradientsForPicker![StandardIndex].2, forKey: "LastGradient")
        UpdateValue(WithValue: GradientsForPicker![StandardIndex].2, ToField: .ColorMapGradient)
        ShowSampleView()
        LoadUIContents()
    }
    
    var CurrentGradientContainsWhite: Bool = false
    
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
                    GradientsForPicker?.removeLast()
                    GradientsForPicker?.append((Gradients.User, "User", EditedGradient))
                    UserGradient = EditedGradient
                    _Settings.set(EditedGradient, forKey: "UserGradient")
                    ShowSampleView()
                    LoadUIContents()
                }
            }
        }
    }
    
    func GradientToEdit(_ EditMe: String?, Tag: Any?)
    {
        //Not used in this class.
    }
    
    func SetStop(StopColorIndex StopIndex: Int)
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
    
    @IBAction func HandleMergeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeSwitch.isOn, ToField: .MergeColorMapWithSource)
        ShowSampleView()
    }
    
    @IBOutlet weak var MergeSwitchLabel: UILabel!
    @IBOutlet weak var MergeSwitch: UISwitch!
    @IBOutlet weak var GradientPicker: UIPickerView!
    @IBOutlet weak var GradientSample: UIImageView!
    @IBOutlet weak var InvertGradientSwitch: UISwitch!
    @IBOutlet weak var InvertSourceColorSwitch: UISwitch!
}
