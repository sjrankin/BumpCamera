//
//  ConvolutionEmbossSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ConvolutionEmbossSettingsUICode: FilterSettingUIBase, UIPickerViewDelegate, UIPickerViewDataSource
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.ConvolutionEmboss)
        KernelPicker.delegate = self
        KernelPicker.dataSource = self
        KernelPicker.reloadAllComponents()
        let Index = ParameterManager.GetInt(From: FilterID, Field: .CurrentKernelIndex, Default: 0)
        KernelPicker.selectRow(Index, inComponent: 0, animated: true)
        UpdateSample(Index)
    }
    
    let KernelList: [(String, EmbossKernels)] =
        [
            (EmbossKernels.Kernel1.rawValue, .Kernel1),
            (EmbossKernels.Kernel2.rawValue, .Kernel2),
            (EmbossKernels.Kernel3.rawValue, .Kernel3),
            (EmbossKernels.Kernel4.rawValue, .Kernel4),
            (EmbossKernels.Kernel5.rawValue, .Kernel5),
            (EmbossKernels.Kernel6.rawValue, .Kernel6),
            (EmbossKernels.Kernel7.rawValue, .Kernel7),
            (EmbossKernels.Identity.rawValue, .Identity),
    ]
    
    let KernelData: [EmbossKernels: (Int, Int, [Float])] =
        [
            .Kernel1: (3, 3,
                       [0.0, 1.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.0, -1.0, 0.0]),
            .Kernel2: (3, 3,
                       [1.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, -1.0]),
            .Kernel3: (3, 3,
                       [0.0, 0.0, 0.0,
                        1.0, 0.0, -1.0,
                        0.0, 0.0, 0.0]),
            .Kernel4: (3, 3,
                       [0.0, 0.0, 1.0,
                        0.0, 0.0, 0.0,
                        -1.0, 0.0, 0.0]),
            .Kernel5: (3, 3,
                       [-1.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 1.0]),
            .Kernel6: (3, 3,
                       [0.0, 0.0, 1.0,
                        0.0, 0.0, 0.0,
                        -1.0, 0.0, 0.0]),
            .Kernel7: (5, 5,
                       [1.0, 0.0, 0.0, 0.0, 0.0,
                        0.0, 1.0, 0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0, -1.0, 0.0,
                        0.0, 0.0, 0.0, 0.0, -1.0]),
            .Identity: (3, 3,
                        [1.0, 0.0, 0.0,
                         0.0, 1.0, 0.0,
                         0.0, 0.0, 1.0])
    ]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return KernelList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return KernelList[row].0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        UpdateValue(WithValue: row, ToField: .CurrentKernelIndex)
UpdateSample(row)
    }
    
    func UpdateSample(_ AtIndex: Int)
    {
                let SelectedKernel = KernelList[AtIndex].1
        let (Width, Height, Kernel) = KernelData[SelectedKernel]!
        UpdateValue(WithValue: Convolution.KernelToString(Kernel), ToField: .ConvolutionKernel)
        UpdateValue(WithValue: Width, ToField: .ConvolutionWidth)
        UpdateValue(WithValue: Height, ToField: .ConvolutionHeight)
        ShowSampleView()
    }
    
    @IBOutlet weak var KernelPicker: UIPickerView!
}

enum EmbossKernels: String
{
    case Kernel1 = "Kernel1"
    case Kernel2 = "Kernel2"
    case Kernel3 = "Kernel3"
    case Kernel4 = "Kernel4"
    case Kernel5 = "Kernel2a"
    case Kernel6 = "Kernel2b"
    case Kernel7 = "Kernel5"
    case Identity = "Identity"
}
