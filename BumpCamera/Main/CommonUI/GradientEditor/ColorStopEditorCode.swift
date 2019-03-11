//
//  ColorStopEditorCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorStopEditor: UIViewController, ColorPickerProtocol, GradientPickerProtocol
{
    weak var ParentDelegate: GradientPickerProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        GradientSample.layer.borderColor = UIColor.black.cgColor
        GradientSample.layer.borderWidth = 0.5
        GradientSample.layer.cornerRadius = 5.0
        
        ColorSample.layer.borderWidth = 0.5
        ColorSample.layer.borderColor = UIColor.black.cgColor
        ColorSample.layer.cornerRadius = 5.0
        ColorSample.backgroundColor = StopColorToEdit
        
        LocationSlider.value = Float(StopLocationToEdit * 1000.0)
        LocationBox.text = "\(StopLocationToEdit.Round(To: 2))"
        
        let Tap = UITapGestureRecognizer(target: self, action: #selector(HandleTapOnSample))
        GradientSample.addGestureRecognizer(Tap)
        
        UpdateUI()
    }
    
    @objc func HandleTapOnSample(TapGesture: UITapGestureRecognizer)
    {
        if TapGesture.state == .ended
        {
            IsVertical = !IsVertical
            UpdateUI()
        }
    }
    
    func UpdateUI()
    {
        let SampleGradient = GradientParser.InsertGradientStop(Into: OriginalGradient, StopColorToEdit, CGFloat(StopLocationToEdit))
        let GradientImage = GradientParser.CreateGradientImage(From: SampleGradient,
                                                               WithFrame: GradientSample.bounds,
                                                               IsVertical: IsVertical, ReverseColors: false)
        GradientSample.image = GradientImage
    }
    
    var IsVertical: Bool = false
    
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
        //Not used in this class.
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            if let CallerTag = Tag as? String
            {
                if CallerTag == "StopColor"
                {
                    ToColorPicker = false
                    ColorSample.backgroundColor = NewColor
                    UpdateGradient(WithColor: NewColor)
                    UpdateUI()
                }
            }
        }
    }
    
    func EditedGradient(_ Edited: String?, Tag: Any?)
    {
        //Not used in this class.
    }
    
    var OriginalGradient: String = ""
    var ParentTag: Any?
    
    func GradientToEdit(_ EditMe: String?, Tag: Any?)
    {
        OriginalGradient = EditMe == nil ? "" : EditMe!
        ParentTag = Tag
    }
    
    func SetStop(StopColor: UIColor?, StopLocation: Double?)
    {
        if let Color = StopColor
        {
            StopColorToEdit = Color
            OriginalColor = Color
        }
        if let Where = StopLocation
        {
            StopLocationToEdit = Where
            OriginalLocation = Where
        }
    }
    
    func UpdateGradient(WithLocation: Double)
    {
        StopLocationToEdit = WithLocation
        UpdateUI()
    }
    
    func UpdateGradient(WithColor: UIColor)
    {
        StopColorToEdit = WithColor
        UpdateUI()
    }
    
    @IBAction func HandleNewTextLocation(_ sender: Any)
    {
        guard let Value = Double(LocationBox.text!) else
        {
            LocationBox.text = "0.5"
            LocationSlider.value = 500.0
            StopLocationToEdit = 0.5
            UpdateUI()
            return
        }
        let Position = Value.Clamp(0.0, 1.0)
        LocationSlider.value = Float(Position * 1000.0)
        StopLocationToEdit = Position
        UpdateUI()
    }
    
    var OriginalColor: UIColor = UIColor.black
    var StopColorToEdit: UIColor = UIColor.black
    var OriginalLocation: Double = 0.0
    var StopLocationToEdit: Double = 0.0
    
    @IBAction func HandleLocationSliderChanged(_ sender: Any)
    {
        let SliderValue = Double(LocationSlider.value / 1000.0)
        UpdateGradient(WithLocation: SliderValue)
        LocationBox.text = "\(SliderValue.Round(To: 2))"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColorPicker":
            if let Dest = segue.destination as? ColorPicker2
            {
                ToColorPicker = true
                Dest.ColorToEdit(StopColorToEdit, Tag: "StopColor")
                Dest.ParentDelegate = self
            }
            
        default:
            break
        }
        super.prepare(for: segue, sender: self)
    }
    
    var ToColorPicker: Bool = false
    
    override func viewWillDisappear(_ animated: Bool)
    {
        if !ToColorPicker
        {
            if DidCancel
            {
                ParentDelegate?.EditedGradient(nil, Tag: ParentTag)
            }
            else
            {
                let Final = GradientParser.InsertGradientStop(Into: OriginalGradient, StopColorToEdit, CGFloat(StopLocationToEdit))
                ParentDelegate?.EditedGradient(Final, Tag: ParentTag)
            }
        }
        super.viewWillDisappear(animated)
    }
    
    var DidCancel = false
    
    @IBAction func HandleCancelPressed(_ sender: Any)
    {
        DidCancel = true
        //ParentDelegate?.EditedGradient(nil, Tag: ParentTag)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func HandleResetButton(_ sender: Any)
    {
        StopLocationToEdit = OriginalLocation
        StopColorToEdit = OriginalColor
        UpdateUI()
    }
    
    @IBOutlet weak var LocationBox: UITextField!
    @IBOutlet weak var LocationSlider: UISlider!
    @IBOutlet weak var ColorSample: UIView!
    @IBOutlet weak var GradientSample: UIImageView!
}
