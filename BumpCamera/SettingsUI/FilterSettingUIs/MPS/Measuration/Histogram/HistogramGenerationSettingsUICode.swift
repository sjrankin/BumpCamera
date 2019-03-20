//
//  HistogramGenerationSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import MetalPerformanceShaders

class HistogramGenerationSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.HistogramGeneration, EnableSelectImage: true,
                   CallFilter: false, IsChildDialog: true)
    }
    
    @IBAction func HandleGenerateButtonPressed(_ sender: Any)
    {
        let HistoGen = Histogram()
        HistoGen.InitializeForImage()
        let Parameters = [String: Any]()
        if let Results = HistoGen.Query(Image: SampleViewImage!, Parameters: Parameters)
        {
            if let Something = Results["Histogram"]
            {
                RawHistogramData = Something as! [vector_float4]
                HaveGeneratedData = true
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        switch identifier
        {
        case "ToHistogramDataViewer":
            return HaveGeneratedData
            
        default:
            return true
        }
    }
    
    var HaveGeneratedData: Bool = false
    
    var RawHistogramData = [vector_float4]()
}
