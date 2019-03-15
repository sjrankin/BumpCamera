//
//  ShapePixellateSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ShapePixellateSettingsUICode: FilterSettingUIBase, ColorPickerProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.ShapePixellate)
        
        let BlockSize = ParameterManager.GetInt(From: FilterID, Field: .PixellateWidth, Default: 32)
        SizeSlider.value = Float(Double(BlockSize) * 100.0)
        BlockSizeValue.text = "\(BlockSize)"
        let ShapeIndex = ParameterManager.GetInt(From: FilterID, Field: .PixellateShape, Default: 0)
        ShapeSegment.selectedSegmentIndex = ShapeIndex
        BlockColorSample.layer.cornerRadius = 5.0
        BlockColorSample.layer.borderColor = UIColor.black.cgColor
        BlockColorSample.layer.borderWidth = 0.5
        BlockColorSample.backgroundColor = ParameterManager.GetColor(From: FilterID, Field: .BlockColor, Default: UIColor.blue)
        OutlineColorSample.layer.cornerRadius = 5.0
        OutlineColorSample.layer.borderColor = UIColor.black.cgColor
        OutlineColorSample.layer.borderWidth = 0.5
        OutlineColorSample.backgroundColor = ParameterManager.GetColor(From: FilterID, Field: .PixelOutlineColor, Default: UIColor.black)
        BlockColorSegment.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .BlockColorDetermination, Default: 0)
        OutlineColorSegment.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .PixelOutlineColorDetermination, Default: 3)
        OutlineWidthSegment.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .PixelOutlineThickness, Default: 2)
        ShowOutlineSwitch.isOn = ParameterManager.GetBool(From: FilterID, Field: .DrawPixelOutline, Default: true)
    }
    
    @IBAction func HandleSizeSliderChanged(_ sender: Any)
    {
        let SliderValue = Int(SizeSlider.value / 100.0)
        BlockSizeValue.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .PixellateWidth)
        UpdateValue(WithValue: SliderValue, ToField: .PixellateHeight)
        ShowSampleView()
    }
    
    @IBAction func HandleShapeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: ShapeSegment.selectedSegmentIndex, ToField: .PixellateShape)
        ShowSampleView()
    }
    
    @IBAction func HandleBlockColorDeterminationChanged(_ sender: Any)
    {
        UpdateValue(WithValue: BlockColorSegment.selectedSegmentIndex, ToField: .BlockColorDetermination)
        ShowSampleView()
    }
    
    @IBAction func HandleOutlineWidthChanged(_ sender: Any)
    {
        UpdateValue(WithValue: OutlineWidthSegment.selectedSegmentIndex + 1, ToField: .PixelOutlineThickness)
        ShowSampleView()
    }
    
    @IBAction func HandleOutlineColorDeterminationChanged(_ sender: Any)
    {
        UpdateValue(WithValue: OutlineColorSegment.selectedSegmentIndex, ToField: .PixelOutlineColorDetermination)
        ShowSampleView()
    }
    
    @IBAction func HandleShowOutlineChanged(_ sender: Any)
    {
        UpdateValue(WithValue: ShowOutlineSwitch.isOn, ToField: .DrawPixelOutline)
        ShowSampleView()
    }
    
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
        //Not used in this class.
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            if let TagValue = Tag as? String
            {
                switch TagValue
                {
                case "BlockColor":
                    UpdateValue(WithValue: NewColor, ToField: .BlockColor)
                    BlockColorSample.backgroundColor = NewColor
                    
                case "OutlineColor":
                    UpdateValue(WithValue: NewColor, ToField: .PixelOutlineColor)
                    OutlineColorSample.backgroundColor = NewColor
                    
                default:
                    return
                }
                
                ShowSampleView()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToBlockColorPicker":
            if let Dest = segue.destination as? ColorPicker2
            {
                Dest.ParentDelegate = self
                let EditMe = ParameterManager.GetColor(From: FilterID, Field: .BlockColor, Default: UIColor.red)
                Dest.ColorToEdit(EditMe, Tag: "BlockColor")
            }
            
        case "ToOutlineColorPicker":
            if let Dest = segue.destination as? ColorPicker2
            {
                Dest.ParentDelegate = self
                let EditMe = ParameterManager.GetColor(From: FilterID, Field: .PixelOutlineColor, Default: UIColor.red)
                Dest.ColorToEdit(EditMe, Tag: "OutlineColor")
            }
            
        default:
            break;
        }
    super.prepare(for: segue, sender: self)
    }
    
    @IBOutlet weak var BlockSizeValue: UILabel!
    @IBOutlet weak var OutlineColorSegment: UISegmentedControl!
    @IBOutlet weak var OutlineWidthSegment: UISegmentedControl!
    @IBOutlet weak var ShowOutlineSwitch: UISwitch!
    @IBOutlet weak var OutlineColorSample: UIView!
    @IBOutlet weak var BlockColorSample: UIView!
    @IBOutlet weak var BlockColorSegment: UISegmentedControl!
    @IBOutlet weak var SizeSlider: UISlider!
    @IBOutlet weak var ShapeSegment: UISegmentedControl!
}
