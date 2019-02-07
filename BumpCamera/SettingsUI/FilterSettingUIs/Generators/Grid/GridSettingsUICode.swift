//
//  GridSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GridSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

        Initialize(FilterType: FilterManager.FilterTypes.Grid)
        PopulateUI()
        
        AlphaSlider.addTarget(self, action: #selector(AlphaDoneSliding), for: [.touchUpInside, .touchUpOutside])
        LineWidthSlider.addTarget(self, action: #selector(LineWidthDoneSliding), for: [.touchUpInside, .touchUpOutside])
        HorizontalSpacingSlider.addTarget(self, action: #selector(WidthDoneSliding), for: [.touchUpInside, .touchUpOutside])
        VerticalSpacingSlider.addTarget(self, action: #selector(HeightDoneSliding), for: [.touchUpInside, .touchUpOutside])
    }
    
    func PopulateUI()
    {
        let RawLineColor = ParameterManager.GetColor(From: FilterID, Field: .GridColor, Default: UIColor.black)
        let (LineColor, LineAlpha) = ParseColor(RawLineColor)
        if ParameterManager.GetBool(From: FilterID, Field: .InvertColor, Default: false)
        {
            LineColorSegment0.selectedSegmentIndex = UISegmentedControl.noSegment
            LineColorSegment1.selectedSegmentIndex = 3
        }
        else
        {
            let LineColorIndices = LineColorIndex(For: LineColor)
            switch LineColorIndices!.0
            {
            case 0:
                LineColorSegment0.selectedSegmentIndex = LineColorIndices!.1
                LineColorSegment1.selectedSegmentIndex = UISegmentedControl.noSegment
                
            case 1:
                LineColorSegment1.selectedSegmentIndex = LineColorIndices!.1
                LineColorSegment0.selectedSegmentIndex = UISegmentedControl.noSegment
                
            default:
                LineColorSegment0.selectedSegmentIndex = 0
                LineColorSegment1.selectedSegmentIndex = UISegmentedControl.noSegment
            }
        }
        let FinalAlpha = LineAlpha.Round(To: 2)
        AlphaLabel.text = "\(FinalAlpha)"
        AlphaSlider.value = Float(FinalAlpha) * 1000.0
        let RawBGColor = ParameterManager.GetColor(From: FilterID, Field: .GridBackground, Default: UIColor.clear)
        if ParameterManager.GetBool(From: FilterID, Field: .InvertBackgroundColor, Default: false)
        {
            BackgroundColorSegment0.selectedSegmentIndex = 1
            BackgroundColorSegment1.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        else
        {
            let BGColorIndices = BackgroundColorIndex(For: RawBGColor)
            switch BGColorIndices!.0
            {
            case 0:
                BackgroundColorSegment0.selectedSegmentIndex = BGColorIndices!.1
                BackgroundColorSegment1.selectedSegmentIndex = UISegmentedControl.noSegment
                
            case 1:
                BackgroundColorSegment0.selectedSegmentIndex = UISegmentedControl.noSegment
                BackgroundColorSegment1.selectedSegmentIndex = BGColorIndices!.1
                
            default:
                BackgroundColorSegment0.selectedSegmentIndex = 0
                BackgroundColorSegment1.selectedSegmentIndex = UISegmentedControl.noSegment
            }
        }
        let LWidth = ParameterManager.GetInt(From: FilterID, Field: .LineWidth, Default: 1)
        LineWidthLabel.text = "\(LWidth)"
        let FLWidth: Float = Float(LWidth) * 100.0
        LineWidthSlider.value = FLWidth
        let HSpacing = ParameterManager.GetInt(From: FilterID, Field: .GridX, Default: 32)
        HorizontalSpacingLabel.text = "\(HSpacing)"
        let FHSpacing: Float = Float(HSpacing) * 50.0
        HorizontalSpacingSlider.value = FHSpacing
        let VSpacing = ParameterManager.GetInt(From: FilterID, Field: .GridY, Default: 32)
        VerticalSpacingLabel.text = "\(VSpacing)"
        let FVSpacing: Float = Float(VSpacing) * 50.0
        VerticalSpacingSlider.value = FVSpacing
    }
    
    func ParseColor(_ Source: UIColor) -> (UIColor, CGFloat)
    {
        let (R, G, B, A) = Source.AsRGBA()
        let NewColor = UIColor(red: R, green: G, blue: B, alpha: 1.0)
        return (NewColor, A)
    }
    
    let LineColorMap: [UIColor.Colors: (Int, Int)] =
        [
            .Black: (0, 0),
            .White: (0, 1),
            .Red: (0, 2),
            .Green: (0, 3),
            .Blue: (0, 4),
            .Cyan: (1, 0),
            .Magenta: (1, 1),
            .Yellow: (1, 2)
    ]
    
    func LineColorIndex(For: UIColor) -> (Int, Int)?
    {
        let AbstractColor = For.Symbol()
        if let (S0, S1) = LineColorMap[AbstractColor]
        {
            return (S0, S1)
        }
        return nil
    }
    
    let BGColorMap: [UIColor.Colors: (Int, Int)] =
        [
            .Clear: (0, 0),
            .Red: (0, 2),
            .Green: (0, 3),
            .Blue: (0, 4),
            .Cyan: (1, 0),
            .Magenta: (1, 1),
            .Yellow: (1, 2),
            .Black: (1, 3),
            .White: (1, 4)
    ]
    
    func BackgroundColorIndex(For: UIColor) -> (Int, Int)?
    {
        let AbstractColor = For.Symbol()
        if let (S0, S1) = BGColorMap[AbstractColor]
        {
            return (S0, S1)
        }
        return nil
    }
    
    func GetLineColor(IncludeAlpha: Bool) -> UIColor?
    {
        var UseAlpha: CGFloat = 1.0
        if IncludeAlpha
        {
            UseAlpha = CGFloat(AlphaSlider.value / 1000.0)
        }
        if LineColorSegment0.selectedSegmentIndex != UISegmentedControl.noSegment
        {
            switch LineColorSegment0.selectedSegmentIndex
            {
            case 0:
                return UIColor.black.ChangeAlpha(To: UseAlpha)
                
            case 1:
                return UIColor.white.ChangeAlpha(To: UseAlpha)
                
            case 2:
                return UIColor.red.ChangeAlpha(To: UseAlpha)
                
            case 3:
                return UIColor.green.ChangeAlpha(To: UseAlpha)
                
            case 4:
                return UIColor.blue.ChangeAlpha(To: UseAlpha)
                
            default:
                return UIColor.black.ChangeAlpha(To: UseAlpha)
            }
        }
        switch LineColorSegment1.selectedSegmentIndex
        {
        case 0:
            return UIColor.cyan.ChangeAlpha(To: UseAlpha)
            
        case 1:
            return UIColor.magenta.ChangeAlpha(To: UseAlpha)
            
        case 2:
            return UIColor.yellow.ChangeAlpha(To: UseAlpha)
            
        case 3:
            return nil
            
        default:
            return UIColor.cyan.ChangeAlpha(To: UseAlpha)
        }
    }
    
    func GetBackgroundColor() -> UIColor?
    {
        if         BackgroundColorSegment0.selectedSegmentIndex != UISegmentedControl.noSegment
        {
            switch BackgroundColorSegment0.selectedSegmentIndex
            {
            case 0:
                return UIColor.clear
                
            case 1:
                return nil
                
            case 2:
                return UIColor.red
                
            case 3:
                return UIColor.green
                
            case 4:
                return UIColor.blue
                
            default:
                return UIColor.clear
            }
        }
        switch BackgroundColorSegment1.selectedSegmentIndex
        {
        case 0:
            return UIColor.cyan
            
        case 1:
            return UIColor.magenta
            
        case 2:
            return UIColor.yellow
            
        case 3:
            return UIColor.black
            
        case 4:
            return UIColor.white
            
        default:
            return UIColor.clear
        }
    }
    
    @objc func AlphaDoneSliding()
    {
        let SliderValue: Double = Double(AlphaSlider.value / 1000.0)
        AlphaLabel.text = "\(SliderValue.Round(To: 2))"
        if let LineColor = GetLineColor(IncludeAlpha: true)
        {
            UpdateValue(WithValue: LineColor, ToField: .GridColor)
            UpdateValue(WithValue: SliderValue, ToField: .Angle)
        }
        ShowSampleView()
    }
    
    @objc func LineWidthDoneSliding()
    {
        let SliderValue: Int = Int(LineWidthSlider.value / 100.0)
        LineWidthLabel.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .LineWidth)
        ShowSampleView()
    }
    
    @objc func WidthDoneSliding()
    {
        let SliderValue: Int = Int(HorizontalSpacingSlider.value / 50.0)
        HorizontalSpacingLabel.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .GridX)
        ShowSampleView()
    }
    
    @objc func HeightDoneSliding()
    {
        let SliderValue: Int = Int(VerticalSpacingSlider.value / 50.0)
        VerticalSpacingLabel.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .GridY)
        ShowSampleView()
    }
    
    @IBAction func HandleAlphaSliderChanged(_ sender: Any)
    {
        let SliderValue: Double = Double(AlphaSlider.value / 1000.0)
        AlphaLabel.text = "\(SliderValue.Round(To: 2))"
    }
    
    @IBAction func HandleLineWidthSliderChanged(_ sender: Any)
    {
        let SliderValue: Int = Int(LineWidthSlider.value / 100.0)
        LineWidthLabel.text = "\(SliderValue)"
    }
    
    @IBAction func HandleHorizontalSpacingChanged(_ sender: Any)
    {
        let SliderValue: Int = Int(HorizontalSpacingSlider.value / 50.0)
        HorizontalSpacingLabel.text = "\(SliderValue)"
    }
    
    @IBAction func HandleVerticalSpacingChanged(_ sender: Any)
    {
        let SliderValue: Int = Int(VerticalSpacingSlider.value / 50.0)
        VerticalSpacingLabel.text = "\(SliderValue)"
    }
    
    @IBAction func HandleLineColor0Changed(_ sender: Any)
    {
        LineColorSegment1.selectedSegmentIndex = UISegmentedControl.noSegment
        let NewLineColor = GetLineColor(IncludeAlpha: true)
        UpdateValue(WithValue: false, ToField: .InvertColor)
        UpdateValue(WithValue: NewLineColor!, ToField: .GridColor)
        ShowSampleView()
    }
    
    @IBAction func HandleLineColor1Changed(_ sender: Any)
    {
        LineColorSegment0.selectedSegmentIndex = UISegmentedControl.noSegment
        let NewLineColor = GetLineColor(IncludeAlpha: true)
        if NewLineColor == nil
        {
            UpdateValue(WithValue: true, ToField: .InvertColor)
        }
        else
        {
            UpdateValue(WithValue: NewLineColor!, ToField: .GridColor)
            UpdateValue(WithValue: false, ToField: .InvertColor)
        }
        ShowSampleView()
    }
    
    @IBAction func HandleBackgroundColor0Changed(_ sender: Any)
    {
        BackgroundColorSegment1.selectedSegmentIndex = UISegmentedControl.noSegment
        let NewBGColor = GetBackgroundColor()
        if NewBGColor == nil
        {
            UpdateValue(WithValue: true, ToField: .InvertBackgroundColor)
        }
        else
        {
            UpdateValue(WithValue: NewBGColor!, ToField: .GridBackground)
            UpdateValue(WithValue: false, ToField: .InvertBackgroundColor)
        }
        ShowSampleView()
    }
    
    @IBAction func HandleBackgroundColor1Changed(_ sender: Any)
    {
        BackgroundColorSegment0.selectedSegmentIndex = UISegmentedControl.noSegment
        let NewBGColor = GetBackgroundColor()
        if NewBGColor == nil
        {
            UpdateValue(WithValue: true, ToField: .InvertBackgroundColor)
        }
        else
        {
            UpdateValue(WithValue: NewBGColor!, ToField: .GridBackground)
            UpdateValue(WithValue: false, ToField: .InvertBackgroundColor)
        }
        ShowSampleView()
    }
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var AlphaLabel: UILabel!
    @IBOutlet weak var VerticalSpacingLabel: UILabel!
    @IBOutlet weak var HorizontalSpacingLabel: UILabel!
    @IBOutlet weak var LineWidthLabel: UILabel!
    @IBOutlet weak var LineWidthSlider: UISlider!
    @IBOutlet weak var HorizontalSpacingSlider: UISlider!
    @IBOutlet weak var VerticalSpacingSlider: UISlider!
    @IBOutlet weak var AlphaSlider: UISlider!
    @IBOutlet weak var LineColorSegment0: UISegmentedControl!
    @IBOutlet weak var LineColorSegment1: UISegmentedControl!
    @IBOutlet weak var BackgroundColorSegment0: UISegmentedControl!
    @IBOutlet weak var BackgroundColorSegment1: UISegmentedControl!
}
