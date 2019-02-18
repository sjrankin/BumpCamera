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

/// Code for the System Report UITableViewController.
class SystemReport: UITableViewController
{
    /// Load the UI.
    override func viewDidLoad()
    {
        super.viewDidLoad()
        Platform.MonitorBatteryLevel(true)
        LoadData()
        tableView.tableFooterView = UIView()
    }
    
    /// Handle view will appear events. Start the update timer, which fires once a second to keep information shown current. The timer
    /// is set up here (and not in viewDidLoad) to handle the case for when the user goes to a different view controller then returns
    /// here. If that happens, viewDidLoad isn't called again but this function is.
    ///
    /// - Parameter animated: Passed to super.viewWillAppear.
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        UpdateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(UpdateData), userInfo: nil, repeats: true)
    }
    
    /// Handle view will disappear events. Invalidated the update timer. Doing this here will ensure the timer (which calls some relatively
    /// heavy functions) will stop, and limit the effect of continuously running stats in the background where no one can see them. If the
    /// user returns to this view controller, viewWillAppear will restart the timer.
    ///
    /// - Parameter animated: Passed to super.ViewWillDisappear.
    override func viewWillDisappear(_ animated: Bool)
    {
        UpdateTimer?.invalidate()
        UpdateTimer = nil
        super.viewWillDisappear(animated)
    }
    
    /// Update the data in the UI. Called when the timer is triggered (and by viewDidLoad once).
    @objc func UpdateData()
    {
        LoadData()
    }
    
    /// Timer for showing updated data in the UI.
    var UpdateTimer: Timer? = nil
    
    /// Load the data into the UI.
    func LoadData()
    {
        ReportMetalFeatures()
        ReportCameraFeatures()
        ReportSystemFeatures()
    }
    
    /// Handle table cell selections. This is done to allow more information to be displayed for certain pieces of information.
    ///
    /// - Parameters:
    ///   - tableView: The table view where the selection took place.
    ///   - indexPath: Indicates which cell was selected (in our case, pressed).
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let Cell = tableView.cellForRow(at: indexPath)
        if Cell?.tag == 2
        {
            //Show an explanation for system pressure.
            let Explanation =
            """
Shows the current system pressure. Nomimal is good, Fair is for reaonsable loads, Serious is for heavy loads, Critical for very heavy loads and you should close programs, and Catastrophic for when the system will shut down very soon to protect itself from thermal damage.
"""
            let Alert = UIAlertController(title: "System Pressure", message: Explanation, preferredStyle: UIAlertController.Style.alert)
            Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            present(Alert, animated: true)
        }
    }
    
    /// Show data on system features, such as CPU, memory, system pressure, and the like.
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
    
    /// Colors to use for reporting system pressure. The higher the pressure, the more strident the color.
    let PressureColors: [String: (UIColor, UIColor)] =
        [
            "Nominal": (UIColor.black, UIColor(named: "GreenPastel")!),
            "Fair": (UIColor.black, UIColor(named: "LightGoldenrodYellow")!),
            "Serious": (UIColor(named: "Tomato")!, UIColor(named: "Daffodil")!),
            "Critical": (UIColor(named: "Tomato")!, UIColor(named: "PalePink")!),
            "Catastrophic": (UIColor.yellow, UIColor.red),
            ]
    
    /// Show metal feature information in the UI.
    func ReportMetalFeatures()
    {
        MetalFeatures.text = Platform.MetalGPU()
        DeviceName.text = Platform.MetalDeviceName()
        AllocMemLabel.text = Platform.MetalAllocatedSpace()
    }
    
    /// Show camera information in the UI.
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
    
    // MARK: UI controls/outlets.
    
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
