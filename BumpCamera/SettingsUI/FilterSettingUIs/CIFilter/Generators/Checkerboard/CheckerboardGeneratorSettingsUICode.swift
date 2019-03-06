//
//  CheckerboardGeneratorSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class CheckerboardGeneratorSettingsUICode: FilterSettingUIBase, ColorPickerProtocol//UIActivityItemSource, ColorPickerProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.Checkerboard)
        let Color0 = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.black)
        let Color1 = ParameterManager.GetColor(From: FilterID, Field: .Color1, Default: UIColor.white)
        Color1Sample.layer.borderColor = UIColor.black.cgColor
        Color1Sample.layer.borderWidth = 0.5
        Color1Sample.layer.cornerRadius = 5.0
        Color1Sample.backgroundColor = Color0
        Color2Sample.layer.borderColor = UIColor.black.cgColor
        Color2Sample.layer.borderWidth = 0.5
        Color2Sample.layer.cornerRadius = 5.0
        Color2Sample.backgroundColor = Color1
        let ImageWidth = ParameterManager.GetInt(From: FilterID, Field: .IWidth, Default: 1024)
        let ImageHeight = ParameterManager.GetInt(From: FilterID, Field: .IHeight, Default: 1024)
        let WidthSegmentValue = IndexOfClosestTo(ImageWidth, [256, 512, 1024, 2048, 4096])
        let HeightSegmentValue = IndexOfClosestTo(ImageHeight, [256, 512, 1024, 2048, 4096])
        WidthSegment.selectedSegmentIndex = WidthSegmentValue
        HeightSegment.selectedSegmentIndex = HeightSegmentValue
        BlockWidthSlider.addTarget(self, action: #selector(BlockWidthStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        SharpnessSlider.addTarget(self, action: #selector(SharpnessStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        let Sharpness = ParameterManager.GetDouble(From: FilterID, Field: .Sharpness, Default: 1.0)
        SharpnessValue.text = "\(Sharpness.Round(To: 2))"
        SharpnessSlider.value = Float(Sharpness * 1000.0)
        let BlockWidth = ParameterManager.GetDouble(From: FilterID, Field: .PatternBlockWidth, Default: 80.0)
        BlockWidthValue.text = "\(BlockWidth.Round(To: 1))"
        BlockWidthSlider.value = Float(BlockWidth * 10.0)
        
        ShowSampleView()
    }
    
    func IndexOfClosestTo(_ Find: Int, _ List: [Int]) -> Int
    {
        var Delta = Int.max
        var ClosestIndex = 0
        
        var Index = 0
        for Value in List
        {
            let LoopDelta = abs(Value - Find)
            if LoopDelta < Delta
            {
                Delta = LoopDelta
                ClosestIndex = Index
            }
            Index = Index + 1
        }
        return ClosestIndex
    }
    
    /// Not implemented or used in this class.
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
                    UpdateValue(WithValue: NewColor, ToField: .Color0)
                    ShowSampleView()
                    
                case "Color2":
                    Color2Sample.backgroundColor = NewColor
                    UpdateValue(WithValue: NewColor, ToField: .Color1)
                    ShowSampleView()
                    
                default:
                    break
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColor1Picker":
            let EditMe = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.red)
            if let Dest = segue.destination as? ColorPicker
            {
                Dest.delegate = self
                Dest.ColorToEdit(EditMe, Tag: "Color1")
            }
            else
            {
                print("Error getting destination for color picker from segue.")
                return
            }
            
        case "ToColor2Picker":
            let EditMe = ParameterManager.GetColor(From: FilterID, Field: .Color1, Default: UIColor.red)
            if let Dest = segue.destination as? ColorPicker
            {
                Dest.delegate = self
                Dest.ColorToEdit(EditMe, Tag: "Color2")
            }
            else
            {
                print("Error getting destination for color picker from segue.")
                return
            }
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
    
    @objc func BlockWidthStoppedSliding()
    {
        let SliderValue = Double(BlockWidthSlider.value / 10.0)
        BlockWidthValue.text = "\(SliderValue.Round(To: 1))"
        UpdateValue(WithValue: SliderValue, ToField: .PatternBlockWidth)
        ShowSampleView()
    }
    
    @IBAction func HandleBlockWidthChanged(_ sender: Any)
    {
        let SliderValue = Double(BlockWidthSlider.value / 10.0)
        BlockWidthValue.text = "\(SliderValue.Round(To: 1))"
        UpdateValue(WithValue: SliderValue, ToField: .PatternBlockWidth)
        ShowSampleView()
    }
    
    @objc func SharpnessStoppedSliding()
    {
        let SliderValue = Double(SharpnessSlider.value / 1000.0)
        SharpnessValue.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .Sharpness)
        ShowSampleView()
    }
    
    @IBAction func HandleSharpnessChanged(_ sender: Any)
    {
        let SliderValue = Double(SharpnessSlider.value / 1000.0)
        SharpnessValue.text = "\(SliderValue.Round(To: 2))"
        UpdateValue(WithValue: SliderValue, ToField: .Sharpness)
        ShowSampleView()
    }
    
    @IBAction func HandleWidthChanged(_ sender: Any)
    {
        let WidthIndex = WidthSegment.selectedSegmentIndex
        let ImageWidth: Int = Int((pow(Double(2), Double(8 + WidthIndex))))
        UpdateValue(WithValue: ImageWidth, ToField: .IWidth)
        ShowSampleView()
    }
    
    @IBAction func HandleHeightChanged(_ sender: Any)
    {
        let HeightIndex = HeightSegment.selectedSegmentIndex
        let ImageHeight: Int = Int((pow(Double(2), Double(8 + HeightIndex))))
        UpdateValue(WithValue: ImageHeight, ToField: .IHeight)
        ShowSampleView()
    }
    
    @IBOutlet weak var Color1Sample: UIView!
    @IBOutlet weak var Color2Sample: UIView!
    @IBOutlet weak var BlockWidthValue: UILabel!
    @IBOutlet weak var SharpnessValue: UILabel!
    @IBOutlet weak var WidthSegment: UISegmentedControl!
    @IBOutlet weak var HeightSegment: UISegmentedControl!
    @IBOutlet weak var BlockWidthSlider: UISlider!
    @IBOutlet weak var SharpnessSlider: UISlider!
    
    //@IBAction func HandleBackButton(_ sender: Any)
    //{
    //    dismiss(animated: true, completion: nil)
    //}
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
    
    #if false
    @IBAction func HandleActionButton(_ sender: Any)
    {
        let Items: [Any] = [self]
        let ACV = UIActivityViewController(activityItems: Items, applicationActivities: nil)
        present(ACV, animated: true)
    }
    
    @objc func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return UIImage()
    }
    
    @objc func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return "Checkerboard Generator Output"
    }
    
    @objc func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        let Generated: UIImage = GetLastGeneratedImage()!
        
        switch activityType!
        {
        case .postToTwitter:
            return Generated
            
        case .airDrop:
            return Generated
            
        case .copyToPasteboard:
            return Generated
            
        case .mail:
            return Generated
            
        case .postToTencentWeibo:
            return Generated
            
        case .postToWeibo:
            return Generated
            
        case .print:
            return Generated
            
        case .markupAsPDF:
            return Generated
            
        case .message:
            return Generated
            
        default:
            return Generated
        }
    }
    #endif
}
