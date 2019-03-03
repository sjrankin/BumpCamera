//
//  MetalCheckerboardGeneratorSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MetalCheckerboardGeneratorSettingsUICode: FilterSettingUIBase, UIActivityItemSource,
    ColorPickerProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.MetalCheckerboard)
        
        QuadrantContainer.layer.borderColor = UIColor.black.cgColor
        QuadrantContainer.layer.borderWidth = 1.0
        QuadrantContainer.layer.cornerRadius = 5.0
        QuadrantContainer.clipsToBounds = true
        QuadrantIButton.layer.borderColor = UIColor.black.cgColor
        QuadrantIButton.layer.borderWidth = 0.5
        QuadrantIIButton.layer.borderColor = UIColor.black.cgColor
        QuadrantIIButton.layer.borderWidth = 0.5
        QuadrantIIIButton.layer.borderColor = UIColor.black.cgColor
        QuadrantIIIButton.layer.borderWidth = 0.5
        QuadrantIVButton.layer.borderColor = UIColor.black.cgColor
        QuadrantIVButton.layer.borderWidth = 0.5
        
        let Color1 = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.black)
        let Color2 = ParameterManager.GetColor(From: FilterID, Field: .Color1, Default: UIColor.white)
        let Color3 = ParameterManager.GetColor(From: FilterID, Field: .Color2, Default: UIColor.black)
        let Color4 = ParameterManager.GetColor(From: FilterID, Field: .Color3, Default: UIColor.white)
        SetQuadrantColor(1, Color1)
        SetQuadrantColor(2, Color2)
        SetQuadrantColor(3, Color3)
        SetQuadrantColor(4, Color4)
        
        let BlockWidth = ParameterManager.GetDouble(From: FilterID, Field: .PatternBlockWidth, Default: 32.0)
        BlockSizeValue.text = "\(BlockWidth.Round(To: 0))"
        BlockSizeSlider.value = Float(BlockWidth * 100.0)
        
        let ImageWidth = ParameterManager.GetInt(From: FilterID, Field: .IWidth, Default: 1024)
        let ImageHeight = ParameterManager.GetInt(From: FilterID, Field: .IHeight, Default: 1024)
        let WidthSegmentValue = IndexOfClosestTo(ImageWidth, [256, 512, 1024, 2048, 4096])
        let HeightSegmentValue = IndexOfClosestTo(ImageHeight, [256, 512, 1024, 2048, 4096])
        WidthSegment.selectedSegmentIndex = WidthSegmentValue
        HeightSegment.selectedSegmentIndex = HeightSegmentValue
        
        ShowSampleView()
    }
    
    func SetQuadrantColor(_ Quadrant: Int, _ Color: UIColor)
    {
        switch Quadrant
        {
        case 1:
            QuadrantIButton.backgroundColor = Color
            let TintColor = Color.HighestContrastTo(Method: .Brightness)
            QuadrantIButton.tintColor = TintColor
            
        case 2:
            QuadrantIIButton.backgroundColor = Color
            let TintColor = Color.HighestContrastTo(Method: .Brightness)
            QuadrantIIButton.tintColor = TintColor
            
        case 3:
            QuadrantIIIButton.backgroundColor = Color
            let TintColor = Color.HighestContrastTo(Method: .Brightness)
            QuadrantIIIButton.tintColor = TintColor
            
        case 4:
            QuadrantIVButton.backgroundColor = Color
            let TintColor = Color.HighestContrastTo(Method: .Brightness)
            QuadrantIVButton.tintColor = TintColor
            
        default:
            break
        }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColorPicker":
            var ColorField: FilterManager.InputFields = .Color0
            switch QuadrantPressed
            {
            case 1:
                ColorField = .Color0
                
            case 2:
                ColorField = .Color1
                
            case 3:
                ColorField = .Color2
                
            case 4:
                ColorField = .Color3
                
            default:
                ColorField = .Color0
            }
            let EditMe = ParameterManager.GetColor(From: FilterID, Field: ColorField, Default: UIColor.red)
            if let Dest = segue.destination as? ColorPicker2
            {
                Dest.ParentDelegate = self
                let Tag = "Quadrant" + "\(QuadrantPressed)"
                Dest.ColorToEdit(EditMe, Tag: Tag)
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
    
    var QuadrantPressed = -1
    
    @IBAction func QuadrantIPressed(_ sender: Any)
    {
        QuadrantPressed = 1
        performSegue(withIdentifier: "ToColorPicker", sender: self)
    }
    
    @IBAction func QuadrantIIPressed(_ sender: Any)
    {
        QuadrantPressed = 2
        performSegue(withIdentifier: "ToColorPicker", sender: self)
    }
    
    @IBAction func QuadrantIIIPressed(_ sender: Any)
    {
        QuadrantPressed = 3
        performSegue(withIdentifier: "ToColorPicker", sender: self)
    }
    
    @IBAction func QuadrantIVPressed(_ sender: Any)
    {
        QuadrantPressed = 4
        performSegue(withIdentifier: "ToColorPicker", sender: self)
    }
    
    /// Not used in this class.
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            if let TagValue = Tag as? String
            {
                switch TagValue
                {
                case "Quadrant1":
                    SetQuadrantColor(1, NewColor)
                    UpdateValue(WithValue: NewColor, ToField: .Color0)
                    ShowSampleView()
                    
                case "Quadrant2":
                    SetQuadrantColor(2, NewColor)
                    UpdateValue(WithValue: NewColor, ToField: .Color1)
                    ShowSampleView()
                    
                case "Quadrant3":
                    SetQuadrantColor(3, NewColor)
                    UpdateValue(WithValue: NewColor, ToField: .Color2)
                    ShowSampleView()
                    
                case "Quadrant4":
                    SetQuadrantColor(4, NewColor)
                    UpdateValue(WithValue: NewColor, ToField: .Color3)
                    ShowSampleView()
                    
                default:
                    break
                }
            }
        }
    }
    
    @objc func BlockSizeStoppedSliding()
    {
        let SliderValue = Double(BlockSizeSlider.value / 100.0)
        BlockSizeValue.text = "\(SliderValue.Round(To: 0))"
        UpdateValue(WithValue: SliderValue, ToField: .PatternBlockWidth)
        ShowSampleView()
    }
    
    @IBAction func HandleBlockSizeChanged(_ sender: Any)
    {
        let SliderValue = Double(BlockSizeSlider.value / 100.0)
        BlockSizeValue.text = "\(SliderValue.Round(To: 0))"
        UpdateValue(WithValue: SliderValue, ToField: .PatternBlockWidth)
        ShowSampleView()
    }
    
    @IBAction func HandleNewWidth(_ sender: Any)
    {
        let WidthIndex = WidthSegment.selectedSegmentIndex
        let ImageWidth: Int = Int((pow(Double(2), Double(8 + WidthIndex))))
        UpdateValue(WithValue: ImageWidth, ToField: .IWidth)
        ShowSampleView()
    }
    
    @IBAction func HandleNewHeight(_ sender: Any)
    {
        let HeightIndex = HeightSegment.selectedSegmentIndex
        let ImageHeight: Int = Int((pow(Double(2), Double(8 + HeightIndex))))
        UpdateValue(WithValue: ImageHeight, ToField: .IHeight)
        ShowSampleView()
    }
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
    
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
    
    @IBOutlet weak var WidthSegment: UISegmentedControl!
    @IBOutlet weak var HeightSegment: UISegmentedControl!
    @IBOutlet weak var BlockSizeSlider: UISlider!
    @IBOutlet weak var BlockSizeValue: UILabel!
    @IBOutlet weak var QuadrantContainer: UIView!
    @IBOutlet weak var QuadrantIButton: UIButton!
    @IBOutlet weak var QuadrantIIButton: UIButton!
    @IBOutlet weak var QuadrantIIIButton: UIButton!
    @IBOutlet weak var QuadrantIVButton: UIButton!
}
