//
//  DebugSettingsCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class DebugSettingsCode: UITableViewController
{
    #if DEBUG
    let _Settings = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        ShowHeartBeatSwitch.isOn = _Settings.bool(forKey: "ShowHeartBeatIndicator")
        let HeartBeatRate = _Settings.double(forKey: "HeartRate")
        HeartBeatSpeedSegments.selectedSegmentIndex = SegmentFromHeartBeat(HeartBeatRate)
        HeartBeatSwitch.isOn = _Settings.bool(forKey: "EnableHeartBeat")
        ActivityLogSwitch.isOn = _Settings.bool(forKey: "UseActivityLog")
        FramerateSwitch.isOn = _Settings.bool(forKey: "ShowFramerateOverlay")
        IgnorePreviousCrashSwitch.isOn = _Settings.bool(forKey: "IgnorePriorCrashes")
        var LastBadFilter = (UIApplication.shared.delegate as? AppDelegate)?.CrashedFilterName
        if (LastBadFilter?.isEmpty)!
        {
            LastBadFilter = "not recorded"
        }
        LastCrashedFilterName.text = LastBadFilter
        RunHeartBeat()
        self.tableView.tableFooterView = UIView()
    }
    
    let HeartRates: [Double: Int] =
    [
        1.5 : 0,
        1.0 : 1,
        0.5 : 2,
        0.25: 3,
    ]
    
    func SegmentFromHeartBeat(_ Value: Double) -> Int
    {
        if let Seg = HeartRates[Value]
        {
            return Seg
        }
        return 1
    }
    
    func HeartBeatRateFromSegment(_ SegIndex: Int) -> Double
    {
        for (Rate, Index) in HeartRates
        {
            if Index == SegIndex
            {
                return Rate
            }
        }
        return 1.0
    }
    
    func RunHeartBeat()
    {
        StopHeartBeat()
        let HeartSeg = HeartBeatSpeedSegments.selectedSegmentIndex
        let HeartRate = HeartBeatRateFromSegment(HeartSeg)
        HeartTimer = Timer.scheduledTimer(timeInterval: HeartRate, target: self,
                                          selector: #selector(UpdateHeartIndicator),
                                          userInfo: nil, repeats: true)
    }
    
    func StopHeartBeat()
    {
        if HeartTimer != nil
        {
            HeartTimer?.invalidate()
            HeartTimer = nil
        }
    }
    
    var HeartTimer: Timer? = nil
    var ShowingEmptyHeart = true
    
    @objc func UpdateHeartIndicator()
    {
        if ShowingEmptyHeart
        {
            HeartRateIndicator.image = UIImage(named: "FilledHeart")
        }
        else
        {
            HeartRateIndicator.image = UIImage(named: "EmptyHeart")
        }
        ShowingEmptyHeart = !ShowingEmptyHeart
    }
    
    @IBAction func HandleActivityLogChanged(_ sender: Any)
    {
        _Settings.set(ActivityLogSwitch.isOn, forKey: "UseActivityLog")
    }
    
    @IBOutlet weak var ActivityLogSwitch: UISwitch!
    
    @IBAction func HandleFramerateChanged(_ sender: Any)
    {
        _Settings.set(FramerateSwitch.isOn, forKey: "ShowFramerateOverlay")
    }
    
    @IBOutlet weak var FramerateSwitch: UISwitch!
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleIgnorePreviousCrashChanged(_ sender: Any)
    {
        _Settings.set(IgnorePreviousCrashSwitch.isOn, forKey: "IgnorePriorCrashes")
    }
    
    @IBOutlet weak var IgnorePreviousCrashSwitch: UISwitch!
    
    @IBAction func HandleHeartBeatSwitch(_ sender: Any)
    {
        _Settings.set(HeartBeatSwitch.isOn, forKey: "EnableHeartBeat")
    }
    
    @IBOutlet weak var HeartBeatSwitch: UISwitch!
    
    @IBAction func HandleShowHeartBeatSwitchChanged(_ sender: Any)
    {
        _Settings.set(ShowHeartBeatSwitch.isOn, forKey: "ShowHeartBeatIndicator")
        if ShowHeartBeatSwitch.isOn
        {
            RunHeartBeat()
        }
        else
        {
            StopHeartBeat()
            HeartRateIndicator.image = nil
        }
    }
    
    @IBAction func HandleHeartBeatSpeedChanged(_ sender: Any)
    {
        if ShowHeartBeatSwitch.isOn
        {
            RunHeartBeat()
        }
    }
    
    @IBOutlet weak var HeartBeatSpeedSegments: UISegmentedControl!
    
    @IBOutlet weak var ShowHeartBeatSwitch: UISwitch!
    
    @IBOutlet weak var HeartRateIndicator: UIImageView!
    
    @IBOutlet weak var LastCrashedFilterName: UILabel!
    
    @IBAction func HandleClearDebugDirectoryButtonPressed(_ sender: Any)
    {
        FileHandler.ClearDirectory(FileHandler.DebugDirectory)
        let Alert = UIAlertController(title: "Completed",
                                      message: "The directory \(FileHandler.DebugDirectory) was cleared.",
                                      preferredStyle: UIAlertController.Style.alert)
        Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    }
    
    #endif
}
