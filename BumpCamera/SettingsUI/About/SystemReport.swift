//
//  SystemReport.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import Metal
import AVFoundation

class SystemReport: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        Platform.MonitorBatteryLevel(true)
        LoadData()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        UpdateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(UpdateData), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        UpdateTimer?.invalidate()
        UpdateTimer = nil
        super.viewWillDisappear(animated)
    }
    
    @objc func UpdateData()
    {
        LoadData()
    }
    
    var UpdateTimer: Timer? = nil
    
    func LoadData()
    {
        ReportMetalFeatures()
        ReportCameraFeatures()
        ReportSystemFeatures()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let Cell = tableView.cellForRow(at: indexPath)
        if Cell?.tag == 2
        {
            let Explanation =
            """
Shows the current system pressure. Nomimal is good, Fair is for reaonsable loads, Serious is for heavy loads, Critical for very heavy loads and you should close programs, and Catastrophic for when the system will shut down very soon to protect itself from thermal damage.
"""
            let Alert = UIAlertController(title: "System Pressure", message: Explanation, preferredStyle: UIAlertController.Style.alert)
            Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            present(Alert, animated: true)
        }
    }
    
    func ReportSystemFeatures()
    {
        let NetName = Platform.SystemName()
        NetworkNameLabel.text = NetName
        let DeviceTypeName = Platform.NiceModelName()
        DeviceLabel.text = DeviceTypeName
        let RAMSizes = Platform.RAMSize()
        let PercentInUse: Double = Double(RAMSizes.0 / (RAMSizes.0 + RAMSizes.1))
        let Mem = "in use \(PercentInUse.Round(To: 2))%, " + Utility.BigNumToSuffixedNum(BigNum: RAMSizes.0 + RAMSizes.1)
        SystemMemoryLabel.text = Mem
        let Pressure = Platform.GetSystemPressure()
        SystemPressure.text = Pressure
        if let (FGColor, BGColor) = PressureColors[Pressure]
        {
            SystemPressure.textColor = FGColor
            SystemPressure.backgroundColor = BGColor
        }
        else
        {
            SystemPressure.textColor = UIColor.white
            SystemPressure.backgroundColor = UIColor.black
        }
        let (CPUName, CPUFrequency) = Platform.GetProcessorInfo()
        let CPUData = "\(CPUName), \(CPUFrequency)"
        SystemProcessorLabel.text = CPUData
        if let BatteryLevel = Platform.BatteryLevel()
        {
            BatteryLevelLabel.text = "\(Int(BatteryLevel * 100.0))%"
        }
        else
        {
            BatteryLevelLabel.text = "not monitored"
        }
    }
    
    let PressureColors: [String: (UIColor, UIColor)] =
        [
            "Nominal": (UIColor.black, UIColor(named: "GreenPastel")!),
            "Fair": (UIColor.black, UIColor(named: "LightGoldenrodYellow")!),
            "Serious": (UIColor(named: "Tomato")!, UIColor(named: "Daffodil")!),
            "Critical": (UIColor(named: "Tomato")!, UIColor(named: "PalePink")!),
            "Catastrophic": (UIColor.yellow, UIColor.red),
            ]
    
    func ReportMetalFeatures()
    {
        MetalFeatures.text = Platform.MetalGPU()
        DeviceName.text = Platform.MetalDeviceName()
        AllocMemLabel.text = Platform.MetalAllocatedSpace()
    }
    
    func ReportCameraFeatures()
    {
        let HasZoom = Platform.HasTelephotoCamera()
        HasTelephotoLabel.text = HasZoom ? "Yes" : "No"
        let HasTrueDepth = Platform.HasTrueDepthCamera()
        SupportsTrueDepthLabel.text = HasTrueDepth ? "Yes" : "No"
        if let FrontResolution = Platform.GetCameraResolution(CameraType: .builtInWideAngleCamera, Position: .front)
        {
            FrontCameraResolution.text = "\(Int(FrontResolution.width))x\(Int(FrontResolution.height))"
        }
        else
        {
            FrontCameraResolution.text = "unknown"
        }
        if let BackResolution = Platform.GetCameraResolution(CameraType: .builtInWideAngleCamera, Position: .back)
        {
            BackCameraResolution.text = "\(Int(BackResolution.width))x\(Int(BackResolution.height))"
        }
        else
        {
            BackCameraResolution.text = "unknown"
        }
    }
    
    @IBOutlet weak var NetworkNameLabel: UILabel!
    @IBOutlet weak var DeviceLabel: UILabel!
    @IBOutlet weak var SystemPressureTitle: UILabel!
    @IBOutlet weak var BatteryLevelLabel: UILabel!
    @IBOutlet weak var SupportsTrueDepthLabel: UILabel!
    @IBOutlet weak var HasTelephotoLabel: UILabel!
    @IBOutlet weak var BackCameraResolution: UILabel!
    @IBOutlet weak var FrontCameraResolution: UILabel!
    @IBOutlet weak var SystemPressure: UILabel!
    @IBOutlet weak var SystemMemoryLabel: UILabel!
    @IBOutlet weak var SystemProcessorLabel: UILabel!
    @IBOutlet weak var AllocMemLabel: UILabel!
    @IBOutlet weak var DeviceName: UILabel!
    @IBOutlet weak var MetalFeatures: UILabel!
}
