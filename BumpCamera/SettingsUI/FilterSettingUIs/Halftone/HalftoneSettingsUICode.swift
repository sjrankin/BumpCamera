//
//  HalftoneSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/31/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HalftoneSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var WorkingType: FilterManager.FilterTypes!
        let TypeVal = _Settings.integer(forKey: "SetupForFilterType")
        if let VariableType: FilterManager.FilterTypes = FilterManager.FilterTypes(rawValue: TypeVal)
        {
            WorkingType = VariableType
        }
        else
        {
            WorkingType = FilterManager.FilterTypes.LineScreen
        }
        let FilterTitle = FilterManager.GetFilterTitle(WorkingType)
        title = FilterTitle! + " Settings"
        
        SampleView = UIImageView(image: UIImage(named: "Norio"))
        SampleView.contentMode = .scaleAspectFit
        
        NotificationCenter.default.addObserver(self, selector: #selector(DefaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
        Initialize(FilterType: WorkingType)
        
        PopulateUI()
        AngleSlider.addTarget(self, action: #selector(AngleDoneSliding), for: [.touchUpInside, .touchUpOutside])
        WidthSlider.addTarget(self, action: #selector(WidthDoneSliding), for: [.touchUpInside, .touchUpOutside])
        
        let _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block:
        {
            Tmr in
            self.ShowSampleView()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
        super.viewWillDisappear(animated)
    }
    
    /// Populate the UI with saved values.
    func PopulateUI()
    {
        let W = ParameterManager.GetDouble(From: FilterID, Field: .Width, Default: 10.0)
        let A = ParameterManager.GetDouble(From: FilterID, Field: .Angle, Default: 90.0)
        let C = ParameterManager.GetPoint(From: FilterID, Field: .Center, Default: CGPoint(x: 0.0, y: 0.0))
        let CenterInImage = ParameterManager.GetBool(From: FilterID, Field: .CenterInImage, Default: true)
        let Merge = ParameterManager.GetBool(From: FilterID, Field: .MergeWithBackground, Default: true)
        let Adjust = ParameterManager.GetBool(From: FilterID, Field: .AdjustInLandscape, Default: true)
        
        WidthLabel.text = "\(W.Round(To: 1))"
        WidthSlider.value = Float(W) * 50.0
        AngleLabel.text = "\(A.Round(To: 1))°"
        AngleSlider.value = Float(A) * 10.0
        CenterXInput.text = "\(C.x.Round(To: 1))"
        CenterYInput.text = "\(C.y.Round(To: 1))"
        CenterInImageSwitch.isOn = CenterInImage
        MergeWithOriginalSwitch.isOn = Merge
        AdjustForLandscapeSwitch.isOn = Adjust
        
        XLabel.isEnabled = CenterInImageSwitch.isOn
        YLabel.isEnabled = CenterInImageSwitch.isOn
        CenterXInput.isEnabled = CenterInImageSwitch.isOn
        CenterYInput.isEnabled = CenterInImageSwitch.isOn
    }
    
    @objc func DefaultsChanged(notification: NSNotification)
    {
        if let Defaults = notification.object as? UserDefaults
        {
            let NewName = Defaults.value(forKey: "SampleImage") as? String
            if NewName != PreviousImage
            {
                PreviousImage = NewName!
                ShowSampleView()
            }
        }
    }
    
    var PreviousImage = ""
    
    let ViewLock = NSObject()
    
    func ShowSampleView()
    {
        objc_sync_enter(ViewLock)
        defer{objc_sync_exit(ViewLock)}
        
        let ImageName = _Settings.string(forKey: "SampleImage")
        SampleView.image = nil
        var SampleImage = UIImage(named: ImageName!)
        SampleImage = SampleFilter?.Render(Image: SampleImage!)
        SampleView.image = SampleImage
    }
    
    @objc func AngleDoneSliding()
    {
        let SliderValue: Double = Double(AngleSlider.value / 10.0)
        AngleLabel.text = "\(SliderValue.Round(To: 1))°"
        UpdateValue(WithValue: SliderValue, ToField: .Angle)
        ShowSampleView()
    }
    
    @objc func WidthDoneSliding()
    {
        let SliderValue: Double = Double(WidthSlider.value / 20.0)
        WidthLabel.text = "\(SliderValue.Round(To: 1))"
        UpdateValue(WithValue: SliderValue, ToField: .Width)
        ShowSampleView()
    }
    
    @IBAction func HandleAngleSliderChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(AngleSlider.value / 10.0)
        AngleLabel.text = "\(SliderValue.Round(To: 1))°"
        UpdateValue(WithValue: SliderValue, ToField: .Angle)
    }
    
    @IBAction func HandleWidthSliderChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(WidthSlider.value / 20.0)
        WidthLabel.text = "\(SliderValue.Round(To: 1))"
        UpdateValue(WithValue: SliderValue, ToField: .Width)
    }
    
    @IBAction func HandleCenterXChanged(_ sender: Any)
    {
        ValidatePoint()
    }
    
    @IBAction func HandleCenterYChanged(_ sender: Any)
    {
        ValidatePoint()
    }
    
    func ValidatePoint()
    {
        let X = GetTextFieldValue(CenterXInput)
        let Y = GetTextFieldValue(CenterYInput)
        let NewPoint = CGPoint(x: CGFloat(X), y: CGFloat(Y))
        UpdateValue(WithValue: NewPoint, ToField: .Center)
        ShowSampleView()
    }
    
    func GetTextFieldValue(_ Input: UITextField, Min: Double? = nil, Max: Double? = nil, Default: Double = 0.0) -> Double
    {
        if let RawValue = Input.text
        {
            if var DValue = Double(RawValue)
            {
                if let MinVal = Min
                {
                    if DValue < MinVal
                    {
                        DValue = MinVal
                    }
                }
                if let MaxVal = Max
                {
                    if DValue > MaxVal
                    {
                        DValue = MaxVal
                    }
                }
                return DValue
            }
            else
            {
                return Default
            }
        }
        else
        {
            return Default
        }
    }
    
    @IBAction func HandleCenterInImageChanged(_ sender: Any)
    {
        UpdateValue(WithValue: CenterInImageSwitch.isOn, ToField: .CenterInImage)
        XLabel.isEnabled = CenterInImageSwitch.isOn
        YLabel.isEnabled = CenterInImageSwitch.isOn
        CenterXInput.isEnabled = CenterInImageSwitch.isOn
        CenterYInput.isEnabled = CenterInImageSwitch.isOn
        ShowSampleView()
    }
    
    @IBAction func HandleMergeWithOriginalChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeWithOriginalSwitch.isOn, ToField: .MergeWithBackground)
        ShowSampleView()
    }
    
    @IBAction func HandleAdjustForLandscapeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: AdjustForLandscapeSwitch.isOn, ToField: .AdjustInLandscape)
        ShowSampleView()
    }
    
    @IBOutlet weak var AngleLabel: UILabel!
    @IBOutlet weak var WidthLabel: UILabel!
    @IBOutlet weak var YLabel: UILabel!
    @IBOutlet weak var XLabel: UILabel!
    @IBOutlet weak var WidthSlider: UISlider!
    @IBOutlet weak var AngleSlider: UISlider!
    @IBOutlet weak var CenterXInput: UITextField!
    @IBOutlet weak var CenterYInput: UITextField!
    @IBOutlet weak var CenterInImageSwitch: UISwitch!
    @IBOutlet weak var MergeWithOriginalSwitch: UISwitch!
    @IBOutlet weak var AdjustForLandscapeSwitch: UISwitch!
    
    @IBAction func HandleBackButtonPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomeButtonPressed(_ sender: Any)
    {
    }
}
