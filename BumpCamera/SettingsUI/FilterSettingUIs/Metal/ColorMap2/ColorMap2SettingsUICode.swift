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
        
        MergeSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .MergeColorMapWithSource, Default: false)
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
    
    var GradientsForPicker: [(String, String)] =
        [
            ("White to Black", GradientManager.Gradients.WhiteBlackGradient),
            ("White to Red", GradientManager.Gradients.WhiteRedGradient),
            ("White to Green", GradientManager.Gradients.WhiteGreenGradient),
            ("White to Blue", GradientManager.Gradients.WhiteBlueGradient),
            ("White to Cyan", GradientManager.Gradients.WhiteCyanGradient),
            ("White to Magenta", GradientManager.Gradients.WhiteMagentaGradient),
            ("White to Yellow", GradientManager.Gradients.WhiteYellowGradient),
            ("Red to Black", GradientManager.Gradients.RedBlackGradient),
            ("Green to Black", GradientManager.Gradients.GreenBlackGradient),
            ("Blue to Black", GradientManager.Gradients.BlueBlackGradient),
            ("Cyan to Black", GradientManager.Gradients.CyanBlackGradient),
            ("Magenta to Black", GradientManager.Gradients.MagentaBlackGradient),
            ("Yellow to Black", GradientManager.Gradients.YellowBlackGradient),
            ("Cyan to Blue", GradientManager.Gradients.CyanBlueGradient),
            ("Cyan-Blue-Black", GradientManager.Gradients.CyanBlueBlackGradient),
            ("Red to Orange", GradientManager.Gradients.RedOrangeGradient),
            ("Yellow to Red", GradientManager.Gradients.YellowRedGradient),
            ("Pistachio to Green", GradientManager.Gradients.PistachioGreenGradient),
            ("Pistachio to Black", GradientManager.Gradients.PistachioBlackGradient),
            ("Tomato to Red", GradientManager.Gradients.TomatoRedGradient),
            ("Tomato to Black", GradientManager.Gradients.TomatoBlackGradient),
            ("Metallic", GradientManager.Gradients.MetallicGradient),
            ("Red Green Blue", GradientManager.Gradients.RGBGradient),
            ("Cyan Magenta Yellow Black", GradientManager.Gradients.CMYKGradient),
            ("Hues", GradientManager.Gradients.HueGradient),
            ("Rainbow", GradientManager.Gradients.RainbowGradient),
            ("Pastel 1", GradientManager.Gradients.PastelGradient1),
            ("Stripes 1", GradientManager.Gradients.Stripes1),
            ("Stripes 2", GradientManager.Gradients.Stripes2),
            ("Stripes 3", GradientManager.Gradients.Stripes3),
            ("Stripes 4", GradientManager.Gradients.Stripes4),
            ("Stripes 5", GradientManager.Gradients.Stripes5),
            ("Blueprints", GradientManager.Gradients.Blueprint),
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
    
    @IBOutlet weak var MergeSwitch: UISwitch!
    @IBOutlet weak var GradientPicker: UIPickerView!
    @IBOutlet weak var GradientSample: UIImageView!
    @IBOutlet weak var InvertGradientSwitch: UISwitch!
    @IBOutlet weak var InvertSourceColorSwitch: UISwitch!
}
