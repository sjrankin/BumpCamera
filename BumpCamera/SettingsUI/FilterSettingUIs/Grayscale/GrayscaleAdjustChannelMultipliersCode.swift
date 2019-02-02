//
//  GrayscaleAdjustChannelMultipliersCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GrayscaleAdjustChannelMultipliersCode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(DefaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
        SampleView = UIImageView(image: UIImage(named: "Norio"))
        SampleView.contentMode = .scaleAspectFit
        Initialize(FilterType: FilterManager.FilterTypes.GrayscaleKernel)
        ShowSampleView()
        
        RedSlider.addTarget(self, action: #selector(RedSliderDoneSliding), for: [.touchUpInside, .touchUpOutside])
        GreenSlider.addTarget(self, action: #selector(GreenSliderDoneSliding), for: [.touchUpInside, .touchUpOutside])
        
        let RedMul = ParameterManager.GetDouble(From: FilterID, Field: .RAdjustment, Default: 0.3)
        let GreenMul = ParameterManager.GetDouble(From: FilterID, Field: .GAdjustment, Default: 0.5)
        let BlueMul = max(1.0 - (RedMul + GreenMul), 0.0)
        ShowEquation(Red: RedMul, Green: GreenMul, Blue: BlueMul)
        SetSliderValuesTo(Red: RedMul, Green: GreenMul)
        DisplayMultiplierValues(Red: RedMul, Green: GreenMul, Blue: BlueMul)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
        super.viewWillDisappear(animated)
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
    
    func SetSliderValuesTo(Red: Double, Green: Double, Blue: Double = 1.0)
    {
        RedSlider.value = Float(Red * 1000.0)
        GreenSlider.value = Float((Green + Red) * 1000.0)
        BlueSlider.value = Float(Blue * 1000.0)
    }
    
    func DisplayMultiplierValues(Red: Double, Green: Double, Blue: Double)
    {
        RedValue.text = ToString(Red, ToPlace: 3)
        GreenValue.text = ToString(Green, ToPlace: 3)
        BlueValue.text = ToString(Blue, ToPlace: 3)
    }
    
    func ShowEquation(Red: Double, Green: Double, Blue: Double)
    {
        let Eq = "Gray = (red * \(ToString(Red, ToPlace: 4)) + green * \(ToString(Green, ToPlace: 4)) + blue * \(ToString(Blue, ToPlace: 4)))"
        Equation.text = Eq
    }
    
    func UpdateValuesFromSliders(SaveValues: Bool)
    {
        let RVal = Double(RedSlider.value / 1000.0)
        var GVal = Double(GreenSlider.value / 1000.0)
        GVal = GVal - RVal
        let BVal = 1.0 - (RVal + GVal)
        DisplayMultiplierValues(Red: RVal, Green: GVal, Blue: BVal)
        if SaveValues
        {
            ShowEquation(Red: RVal, Green: GVal, Blue: BVal)
            UpdateValue(WithValue: RVal, ToField: .RAdjustment)
            UpdateValue(WithValue: GVal, ToField: .GAdjustment)
            UpdateValue(WithValue: BVal, ToField: .BAdjustment)
            ShowSampleView()
        }
    }
    
    func CoordinateRedGreen(RedMoving: Bool)
    {
        if RedMoving
        {
            if RedSlider.value > GreenSlider.value
            {
                GreenSlider.value = RedSlider.value
                UpdateValuesFromSliders(SaveValues: false)
            }
        }
        else
        {
            if GreenSlider.value < RedSlider.value
            {
                RedSlider.value = GreenSlider.value
                UpdateValuesFromSliders(SaveValues: false)
            }
        }
    }
    
    @objc func RedSliderDoneSliding()
    {
        CoordinateRedGreen(RedMoving: true)
        UpdateValuesFromSliders(SaveValues: true)
    }
    
    @objc func GreenSliderDoneSliding()
    {
        CoordinateRedGreen(RedMoving: false)
        UpdateValuesFromSliders(SaveValues: true)
    }
    
    @IBAction func HandleRedSliderChanged(_ sender: Any)
    {
        CoordinateRedGreen(RedMoving: true)
        UpdateValuesFromSliders(SaveValues: false)
    }
    
    @IBAction func HandleGreenSliderChanged(_ sender: Any)
    {
        CoordinateRedGreen(RedMoving: false)
        UpdateValuesFromSliders(SaveValues: false)
    }
    
    @IBOutlet weak var BlueValue: UILabel!
    @IBOutlet weak var GreenValue: UILabel!
    @IBOutlet weak var RedValue: UILabel!
    @IBOutlet weak var RedSlider: UISlider!
    @IBOutlet weak var GreenSlider: UISlider!
    @IBOutlet weak var BlueSlider: UISlider!
    @IBOutlet weak var Equation: UILabel!
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
}
