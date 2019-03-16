//
//  Pixellate2SettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class Pixellate2SettingsUICode: FilterSettingUIBase, DescendentDelta
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.PixellateMetal)
        let BWidth = ParameterManager.GetInt(From: FilterID, Field: .BlockWidth, Default: 32)
        BlockWidthSlider.value = Float(BWidth * 10)
        WidthOut.text = "\(BWidth)"
        let BHeight = ParameterManager.GetInt(From: FilterID, Field: .BlockHeight, Default: 32)
        BlockWidthSlider.value = Float(BHeight * 10)
        HeightOut.text = "\(BHeight)"
        BlockWidthSlider.addTarget(self, action: #selector(HandleWidthStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        BlockHeightSlider.addTarget(self, action: #selector(HandleHeightStoppedSliding), for: [.touchUpInside, .touchUpOutside])
        let DoMerge = ParameterManager.GetBool(From: FilterID, Field: .MergeWithBackground, Default: true)
        MergeSwitch.isOn = DoMerge
        ShowSampleView()
    }
    
    func UpdatedFrom(_ DescendentName: String, Field: FilterManager.InputFields)
    {
        
    }
    
    @objc func HandleWidthStoppedSliding()
    {
        let SliderValue = Int(BlockWidthSlider.value / 10.0)
        WidthOut.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .BlockWidth)
        ShowSampleView()
    }
    
    @IBAction func HandleWidthChanged(_ sender: Any)
    {
        let SliderValue = Int(BlockWidthSlider.value / 10.0)
        WidthOut.text = "\(SliderValue)"
    }
    
    @objc func HandleHeightStoppedSliding()
    {
        let SliderValue = Int(BlockHeightSlider.value / 10.0)
        HeightOut.text = "\(SliderValue)"
        UpdateValue(WithValue: SliderValue, ToField: .BlockHeight)
        ShowSampleView()
    }
    
    @IBAction func HandleHeightChanged(_ sender: Any)
    {
        let SliderValue = Int(BlockHeightSlider.value / 10.0)
        HeightOut.text = "\(SliderValue)"
    }
    
    @IBAction func HandleMergeChanged(_ sender: Any)
    {
        UpdateValue(WithValue: MergeSwitch.isOn, ToField: .MergeWithBackground)
        ShowSampleView()
    }
    
    @IBOutlet weak var ConditionalLabel: UILabel!
    @IBOutlet weak var BlockWidthSlider: UISlider!
    @IBOutlet weak var BlockHeightSlider: UISlider!
    @IBOutlet weak var MergeSwitch: UISwitch!
    @IBOutlet weak var WidthOut: UILabel!
    @IBOutlet weak var HeightOut: UILabel!
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToConditionalPixellation":
            let Dest = segue.destination as? Pixellate2ConditionalUI
            Dest?.delegate = self
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
}
