//
//  ChannelMixerSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/31/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ChannelMixerSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        SampleView = UIImageView(image: UIImage(named: "Norio"))
        SampleView.contentMode = .scaleAspectFit
        
        NotificationCenter.default.addObserver(self, selector: #selector(DefaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
        Initialize(FilterType: FilterManager.FilterTypes.ChannelMixer)
        
        let (C1Val, C2Val, C3Val) = GetSwizzleValues()
        SetChannels(Channel1: C1Val, Channel2: C2Val, Channel3: C3Val)
    
        let _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block:
        {
            Tmr in
            self.ShowSampleView()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
        super.viewWillDisappear(animated)
    }
    
    @objc func DefaultsChanged(notification: NSNotification)
    {
        if let Defaults = notification.object as? UserDefaults
        {
            let NewName = Defaults.value(forKey: "SampleImage") as? String
            if NewName != PreviousImage
            {
                PreviousImage = NewName!
                ShowSampleView()
            }
        }
    }
    
    var PreviousImage = ""
    
    let ViewLock = NSObject()
    
    func ShowSampleView()
    {
        objc_sync_enter(ViewLock)
        defer{objc_sync_exit(ViewLock)}
        
        let ImageName = _Settings.string(forKey: "SampleImage")
        SampleView.image = nil
        var SampleImage = UIImage(named: ImageName!)
        SampleImage = SampleFilter?.Render(Image: SampleImage!)
        SampleView.image = SampleImage
    }
    
    var Channel1Value: Channels = .Red
    var Channel2Value: Channels = .Green
    var Channel3Value: Channels = .Blue
    
    func GetSwizzleValues() -> (Channels, Channels, Channels)
    {
        var C1: Int = Channels.Red.rawValue
        var C2: Int = Channels.Green.rawValue
        var C3: Int = Channels.Blue.rawValue
        let RawC1 = ParameterManager.GetField(From: FilterID, Field: FilterManager.InputFields.Channel1)
        if let C1Val = RawC1 as? Int
        {
            C1 = C1Val
        }
        let RawC2 = ParameterManager.GetField(From: FilterID, Field: FilterManager.InputFields.Channel2)
        if let C2Val = RawC2 as? Int
        {
            C2 = C2Val
        }
        let RawC3 = ParameterManager.GetField(From: FilterID, Field: FilterManager.InputFields.Channel3)
        if let C3Val = RawC3 as? Int
        {
            C3 = C3Val
        }
        return (Channels(rawValue: C1)!, Channels(rawValue: C2)!, Channels(rawValue: C3)!)
    }
    
    func SetChannels(Channel1: Channels, Channel2: Channels, Channel3: Channels)
    {
        SetChannel1(To: Channel1)
        SetChannel2(To: Channel2)
        SetChannel3(To: Channel3)
    }
    
    func SetChannel1(To: Channels)
    {
        SetChannelValue(To: To, RGBSegment: Channel1RGB, HSBSegment: Channel1HSB, CMYKSegment: Channel1CMYK)
    }
    
    func SetChannel2(To: Channels)
    {
        SetChannelValue(To: To, RGBSegment: Channel2RGB, HSBSegment: Channel2HSB, CMYKSegment: Channel2CMYK)
    }
    
    func SetChannel3(To: Channels)
    {
        SetChannelValue(To: To, RGBSegment: Channel3RGB, HSBSegment: Channel3HSB, CMYKSegment: Channel3CMYK)
    }
    
    func SetChannelValue(To: Channels, RGBSegment: UISegmentedControl,
                         HSBSegment: UISegmentedControl,
                         CMYKSegment: UISegmentedControl)
    {
        RGBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        HSBSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        CMYKSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        var Index = To.rawValue
        if Index <= Channels.Blue.rawValue
        {
            RGBSegment.selectedSegmentIndex = Index
        }
        else
        {
            if Index <= Channels.Brightness.rawValue
            {
                Index = Index - Channels.Hue.rawValue
                HSBSegment.selectedSegmentIndex = Index
            }
            else
            {
                Index = Index - Channels.Cyan.rawValue
                CMYKSegment.selectedSegmentIndex = Index
            }
        }
    }
    
    @IBAction func Channel1RGBChanged(_ sender: Any)
    {
        Channel1CMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel1HSB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel1Value = Channels(rawValue: Channel1RGB.selectedSegmentIndex)!
        UpdateChannelSwizzles()
    }
    
    @IBAction func Channel1HSBChanged(_ sender: Any)
    {
        Channel1CMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel1RGB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel1Value = Channels(rawValue: Channel1HSB.selectedSegmentIndex + Channels.Hue.rawValue)!
        UpdateChannelSwizzles()
    }
    
    @IBAction func Channel1CMYKChanged(_ sender: Any)
    {
        Channel1HSB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel1RGB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel1Value = Channels(rawValue: Channel1CMYK.selectedSegmentIndex + Channels.Cyan.rawValue)!
        UpdateChannelSwizzles()
    }
    
    @IBAction func Channel2RGBChanged(_ sender: Any)
    {
        Channel2CMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel2HSB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel2Value = Channels(rawValue: Channel2RGB.selectedSegmentIndex)!
        UpdateChannelSwizzles()
    }
    
    @IBAction func Channel2HSBChanged(_ sender: Any)
    {
        Channel2CMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel2RGB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel2Value = Channels(rawValue: Channel2HSB.selectedSegmentIndex + Channels.Hue.rawValue)!
        UpdateChannelSwizzles()
    }
    
    @IBAction func Channel2CMYKChanged(_ sender: Any)
    {
        Channel2HSB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel2RGB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel2Value = Channels(rawValue: Channel2CMYK.selectedSegmentIndex + Channels.Cyan.rawValue)!
        UpdateChannelSwizzles()
    }
    
    @IBAction func Channel3RGBChanged(_ sender: Any)
    {
        Channel3CMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel3HSB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel3Value = Channels(rawValue: Channel3RGB.selectedSegmentIndex)!
        UpdateChannelSwizzles()
    }
    
    @IBAction func Channel3HSBChanged(_ sender: Any)
    {
        Channel3CMYK.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel3RGB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel3Value = Channels(rawValue: Channel3HSB.selectedSegmentIndex + Channels.Hue.rawValue)!
        UpdateChannelSwizzles()
    }
    
    @IBAction func Channel3CMYKChanged(_ sender: Any)
    {
        Channel3HSB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel3RGB.selectedSegmentIndex = UISegmentedControl.noSegment
        Channel3Value = Channels(rawValue: Channel3CMYK.selectedSegmentIndex + Channels.Cyan.rawValue)!
        UpdateChannelSwizzles()
    }
    
    func ChannelColorSpace(Channel: Int) -> Int
    {
        switch Channel
        {
        case 0:
            if Channel1RGB.selectedSegmentIndex > -1
            {
                return 0
            }
            if Channel1HSB.selectedSegmentIndex > -1
            {
                return 1
            }
            if Channel1CMYK.selectedSegmentIndex > -1
            {
                return 2
            }
            
        case 1:
            if Channel2RGB.selectedSegmentIndex > -1
            {
                return 0
            }
            if Channel2HSB.selectedSegmentIndex > -1
            {
                return 1
            }
            if Channel2CMYK.selectedSegmentIndex > -1
            {
                return 2
            }
            
        case 2:
            if Channel3RGB.selectedSegmentIndex > -1
            {
                return 0
            }
            if Channel3HSB.selectedSegmentIndex > -1
            {
                return 1
            }
            if Channel3CMYK.selectedSegmentIndex > -1
            {
                return 2
            }
            
        default:
            break
        }
        return 0
    }
    
    func GetCurrentChannelValue(Channel: Int) -> Int
    {
        let ColorSpace = ChannelColorSpace(Channel: Channel)
        switch Channel
        {
        case 0:
            switch ColorSpace
            {
            case 0:
                return Channel1RGB.selectedSegmentIndex
                
            case 1:
                return Channel1HSB.selectedSegmentIndex + Channels.Hue.rawValue
                
            case 2:
                return Channel1CMYK.selectedSegmentIndex + Channels.Cyan.rawValue
                
            default:
                return 0
            }
            
        case 1:
            switch ColorSpace
            {
            case 0:
                return Channel2RGB.selectedSegmentIndex
                
            case 1:
                return Channel2HSB.selectedSegmentIndex + Channels.Hue.rawValue
                
            case 2:
                return Channel2CMYK.selectedSegmentIndex + Channels.Cyan.rawValue
                
            default:
                return 0
            }
            
        case 2:
            switch ColorSpace
            {
            case 0:
                return Channel3RGB.selectedSegmentIndex
                
            case 1:
                return Channel3HSB.selectedSegmentIndex + Channels.Hue.rawValue
                
            case 2:
                return Channel3CMYK.selectedSegmentIndex + Channels.Cyan.rawValue
                
            default:
                return 0
            }
            
        default:
            return 0
        }
    }
    
    func GetChannelValues() -> (Int, Int, Int)
    {
        let C1 = GetCurrentChannelValue(Channel: 0)
        let C2 = GetCurrentChannelValue(Channel: 1)
        let C3 = GetCurrentChannelValue(Channel: 2)
        return (C1, C2, C3)
    }
    
    func UpdateChannelSwizzles()
    {
        let (C1, C2, C3) = GetChannelValues()
        UpdateChannelSwizzles(Channel1: C1, Channel2: C2, Channel3: C3)
    }
    
    func UpdateChannelSwizzles(Channel1: Int, Channel2: Int, Channel3: Int)
    {
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: FilterManager.InputFields.Channel1,
                                  Value: Channel1 as Any?)
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: FilterManager.InputFields.Channel2,
                                  Value: Channel2 as Any?)
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: FilterManager.InputFields.Channel3,
                                  Value: Channel3 as Any?)
        ShowSampleView()
    }
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var Channel1RGB: UISegmentedControl!
    @IBOutlet weak var Channel1HSB: UISegmentedControl!
    @IBOutlet weak var Channel2RGB: UISegmentedControl!
    @IBOutlet weak var Channel2HSB: UISegmentedControl!
    @IBOutlet weak var Channel3RGB: UISegmentedControl!
    @IBOutlet weak var Channel3HSB: UISegmentedControl!
    @IBOutlet weak var Channel1CMYK: UISegmentedControl!
    @IBOutlet weak var Channel2CMYK: UISegmentedControl!
    @IBOutlet weak var Channel3CMYK: UISegmentedControl!
}
