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
            (EmbossKernels.Identity.rawValue, .Identity),
            (EmbossKernels.Outline.rawValue, .Outline),
            (EmbossKernels.Emboss1.rawValue, .Emboss1),
            (EmbossKernels.Emboss2.rawValue, .Emboss2),
            (EmbossKernels.Emboss3.rawValue, .Emboss3),
            (EmbossKernels.Emboss4.rawValue, .Emboss4),
            (EmbossKernels.Emboss5.rawValue, .Emboss5),
            (EmbossKernels.Emboss6.rawValue, .Emboss6),
            (EmbossKernels.Emboss7.rawValue, .Emboss7),
            (EmbossKernels.Emboss8.rawValue, .Emboss8),
            (EmbossKernels.EmbossDN.rawValue, .EmbossDN),
            (EmbossKernels.Edges.rawValue, .Edges),
            (EmbossKernels.UnsharpMask.rawValue, .UnsharpMask),
            (EmbossKernels.Sharpen.rawValue, .Sharpen),
            (EmbossKernels.Sharpen3x3.rawValue, .Sharpen3x3),
            (EmbossKernels.Sharpen5x5.rawValue, .Sharpen5x5),
            (EmbossKernels.HighPass.rawValue, .HighPass),
            (EmbossKernels.LowPass3x3.rawValue, .LowPass3x3),
            (EmbossKernels.LowPass5x5.rawValue, .LowPass5x5),
            (EmbossKernels.Gaussian3x3.rawValue, .Gaussian3x3),
            (EmbossKernels.Gaussian5x5.rawValue, .Gaussian5x5),
            (EmbossKernels.LeftSobel.rawValue, .LeftSobel),
            (EmbossKernels.TopSobel.rawValue, .TopSobel),
            (EmbossKernels.RightSobel.rawValue, .RightSobel),
            (EmbossKernels.BottomSobel.rawValue, .BottomSobel),
            (EmbossKernels.Mean3x3.rawValue, .Mean3x3),
            (EmbossKernels.Mean5x5.rawValue, .Mean5x5),
            (EmbossKernels.HorizontalLines.rawValue, .HorizontalLines),
            (EmbossKernels.VerticalLines.rawValue, .VerticalLines),
            (EmbossKernels.Lines45.rawValue, .Lines45),
            (EmbossKernels.Lines135.rawValue, .Lines135),
            (EmbossKernels.Smoothing.rawValue, .Smoothing),
    ]
    
    let KernelData: [EmbossKernels: (Int, Int, Double, Double, [Float])] =
        [
            .Emboss1: (3, 3, 1.0, 0.5,
                       [0.0, 1.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.0, -1.0, 0.0]),
            .Emboss2: (3, 3, 1.0, 0.5,
                       [1.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, -1.0]),
            .Emboss3: (3, 3, 1.0, 0.5,
                       [0.0, 0.0, 0.0,
                        1.0, 0.0, -1.0,
                        0.0, 0.0, 0.0]),
            .Emboss4: (3, 3, 1.0, 0.5,
                       [0.0, 0.0, 1.0,
                        0.0, 0.0, 0.0,
                        -1.0, 0.0, 0.0]),
            .Emboss5: (3, 3, 1.0, 0.5,
                       [-1.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 1.0]),
            .Emboss6: (3, 3, 1.0, 0.5,
                       [0.0, 0.0, 1.0,
                        0.0, 0.0, 0.0,
                        -1.0, 0.0, 0.0]),
            .Emboss7: (5, 5, 1.0, 0.5,
                       [1.0, 0.0, 0.0, 0.0, 0.0,
                        0.0, 1.0, 0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0, -1.0, 0.0,
                        0.0, 0.0, 0.0, 0.0, -1.0]),
            .Emboss8: (3, 3, 1.0, 0.0,
                       [-2.0, -1.0, 1.0,
                        -1.0, 1.0, 1.0,
                        0.0, 1.0, 2.0]),
            .Identity: (3, 3, 1.0, 0.0,
                        [0.0, 0.0, 0.0,
                         0.0, 1.0, 0.0,
                         0.0, 0.0, 0.0]),
            .EmbossDN: (3, 3, 1.0, 0.5,
                        [2.0, 0.0, 0.0,
                         0.0, -1.0, 0.0,
                         0.0, 0.0, -1.0]),
            .Edges: (3, 3, 1.0, 0.0,
                     [-1.0, -1.0, -1.0,
                      -1.0, 8.0, -1.0,
                      -1.0, -1.0, -1.0]),
            .Sharpen: (3, 3, 1.0, 1.0 / 8.0,
                       [-1.0, -1.0, -1.0,
                        -1.0, 9.0, -1.0,
                        -1.0, -1.0, -1.0]),
            .Sharpen3x3: (3, 3, 1.0, 0.0,
                          [0, -2.0, 0.0,
                           -2.0, 11.0, -2.0,
                           0.0, -2.0, 0.0]),
            .Sharpen5x5: (5, 5, 1.0, 0.0,
                          [-1.0, -1.0, -1.0, -1.0, -1.0,
                           -1.0, 2.0, 2.0, 2.0, -1.0,
                           -1.0, 2.0, 8.0, 2.0, 1.0,
                           -1.0, 2.0, 2.0, 2.0, -1.0,
                           -1.0, -1.0, -1.0, -1.0, -1.0 ]),
            .UnsharpMask: (5, 5, -1.0 / 256.0, 0.5,
                           [1.0, 4.0, 6.0, 1.0,
                            4.0, 16.0, 24.0, 16.0, 4.0,
                            6.0, 24.0, -476.0, 24.0, 6.0,
                            4.0, 16.0, 24.0, 16.0, 4.0,
                            1.0, 4.0, 6.0, 1.0]),
            .HighPass: (3, 3, 1.0, 0.5,
                        [-1.0, -2.0, -1.0,
                         -2.0, 12, -2.0,
                         -1.0, -2.0, -1.0]),
            .LowPass3x3: (3, 3, 1.0, 0.0,
                          [1.0, 2.0, 1.0,
                           2.0, 4.0, 2.0,
                           1.0, 2.0, 1.0]),
            .LowPass5x5: (5, 5, 1.0, 0.0,
                          [1.0, 1.0, 1.0, 1.0, 1.0,
                           1.0, 4.0, 4.0, 4.0, 1.0,
                           1.0, 4.0, 12.0, 4.0, 1.0,
                           1.0, 4.0, 4.0, 4.0, 1.0,
                           0.0, 0.0, -1.0, 0.0, 0.0 ]),
            .Gaussian3x3: (3, 3, /*1.0 / 16.0*/1.0, 0.0,
                           [1.0, 2.0, 1.0,
                            2.0, 4.0, 2.0,
                            1.0, 2.0, 1.0]),
            .Gaussian5x5: (5, 5, /*1.0 / 256.0*/1.0, 0.0,
                           [1.0, 4.0, 6.0, 4.0, 1.0,
                            4.0, 16.0, 24.0, 16.0, 4.0,
                            6.0, 24.0, 36.0, 24.0, 6.0,
                            4.0, 16.0, 24.0, 16.0, 4.0,
                            1.0, 4.0, 6.0, 4.0, 1.0]),
            /*
             [2.0, 4.0, 5.0, 4.0, 2.0,
             4.0, 9.0, 12.0, 9.0, 4.0,
             5.0, 12.0, 15.0, 12.0, 5.0,
             4.0, 9.0, 12.0, 9.0, 4.0,
             2.0, 4.0, 5.0, 4.0, 2.0]),
             */
            .Mean3x3: (3, 3, 1.0, 0.0,
                       [0.1111, 0.1111, 0.1111,
                        0.1111, 0.1111, 0.1111,
                        0.1111, 0.1111, 0.1111]),
            .Mean5x5: (5, 5, 1.0, 0.0,
                       [0.04, 0.04, 0.04, 0.04, 0.04,
                        0.04, 0.04, 0.04, 0.04, 0.04,
                        0.04, 0.04, 0.04, 0.04, 0.04,
                        0.04, 0.04, 0.04, 0.04, 0.04,
                        0.04, 0.04, 0.04, 0.04, 0.04,]),
            .Outline: (3, 3, 1.0, 0.5,
                       [-1.0, -1.0, -1.0,
                        -1.0, 8.0, -1.0,
                        -1.0, -1.0, -1.0]),
            .LeftSobel: (3, 3, 1.0, 0.0,
                         [1.0, 0.0, -1.0,
                          2.0, 0.0, -2.0,
                          1.0, 0.0, -1.0]),
            .TopSobel: (3, 3, 1.0, 1.0,
                        [1.0, 2.0, 0.0,
                         0.0, 0.0, 0.0,
                         -1.0, -2.0, -1.0]),
            .RightSobel: (3, 3, 1.0, 0.0,
                          [-1.0, 0.0, 1.0,
                           -2.0, 0.0, 2.0,
                           -1.0, 0.0, 1.0]),
            .BottomSobel: (3, 3, 1.0, 0.0,
                           [-1.0, -2.0, -1.0,
                            0.0, 0.0, 0.0,
                            1.0, 2.0, 1.0]),
            .HorizontalLines: (3, 3, 1.0, 0.0,
            [-1.0, -1.0, -1.0,
                2.0, 2.0, 2.0,
                -1.0, -1.0, -1.0]),
            .VerticalLines: (3, 3, 1.0, 0.0,
                               [-1.0, 2.0, -1.0,
                                -1.0, 2.0, -1.0,
                                -1.0, 2.0, -1.0]),
            .Lines45: (3, 3, 1.0, 0.0,
                               [-1.0, -1.0, 2.0,
                                -1.0, 2.0, -1.0,
                                2.0, -1.0, -1.0]),
            .Lines135: (3, 3, 1.0, 0.0,
                               [2.0, -1.0, -1.0,
                                -1.0, 2.0, -1.0,
                                -1.0, -1.0, 2.0]),
            .Smoothing: (5, 5, 1.0, 0.0,
            [0.0, 1.0, 2.0, 1.0, 0.0,
             1.0, 4.0, 8.0, 4.0, 1.0,
             2.0, 8.0, 16.0, 8.0, 2.0,
                          1.0, 4.0, 8.0, 4.0, 1.0,
                0.0, 1.0, 2.0, 1.0, 0.0]),
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
        let (Width, Height, Factor, Bias, Kernel) = KernelData[SelectedKernel]!
        UpdateValue(WithValue: Convolution.KernelToString(Kernel), ToField: .ConvolutionKernel)
        UpdateValue(WithValue: Width, ToField: .ConvolutionWidth)
        UpdateValue(WithValue: Height, ToField: .ConvolutionHeight)
        UpdateValue(WithValue: Factor, ToField: .ConvolutionFactor)
        UpdateValue(WithValue: Bias, ToField:. ConvolutionBias)
        ShowSampleView()
    }
    
    @IBOutlet weak var KernelPicker: UIPickerView!
}

enum EmbossKernels: String
{
    case Emboss1 = "Emboss 1"
    case Emboss2 = "Emboss 2"
    case Emboss3 = "Emboss 3"
    case Emboss4 = "Emboss 4"
    case Emboss5 = "Emboss 2a"
    case Emboss6 = "Emboss 2b"
    case Emboss7 = "Emboss 5"
    case Emboss8 = "Emboss 6"
    case Identity = "Identity"
    case EmbossDN = "Emboss DN"
    case Edges = "Edge Detection"
    case Sharpen5x5 = "Sharpen 5x5"
    case Sharpen = "Sharpen"
    case Sharpen3x3 = "Sharpen 3x3"
    case HighPass = "High Pass"
    case LowPass3x3 = "Low Pass 3x3"
    case LowPass5x5 = "Low Pass 5x5"
    case Gaussian3x3 = "Gaussian 3x3"
    case Gaussian5x5 = "Gaussian 5x5"
    case Mean3x3 = "Mean 3x3"
    case Mean5x5 = "Mean 5x5"
    case UnsharpMask = "Unsharp Mask"
    case Outline = "Outline"
    case BottomSobel = "Sobel: Bottom"
    case TopSobel = "Sobel: Top"
    case LeftSobel = "Sobel: Left"
    case RightSobel = "Sobel: Right"
    case HorizontalLines = "Horizontal Lines"
    case VerticalLines = "Vertical Lines"
    case Lines45 = "45° Lines"
    case Lines135 = "135° Lines"
    case Smoothing = "Smoothing"
}
