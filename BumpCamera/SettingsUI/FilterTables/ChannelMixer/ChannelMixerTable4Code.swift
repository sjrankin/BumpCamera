//
//  ChannelMixerTable4Code.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ChannelMixelTable4Code: FilterTableBase
{
    let Filter = FilterManager.FilterTypes.ChannelMixer
    var FilterID: UUID!
    let _Settings = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        FilterID = FilterManager.FilterMap[Filter]
        let OutCS = ParameterManager.GetField(From: FilterID, Field: FilterManager.InputFields.OutputColorSpace)
        var WorkingCS = 0
        if let CS = OutCS as? Int
        {
            WorkingCS = CS
        }
        ColorSpaceSegement.selectedSegmentIndex = WorkingCS
        NewColorSpace(WorkingCS)
    }
    
    func NewColorSpace(_ To: Int)
    {
        PopulateChannelSegments()
        switch To
        {
        case 0:
            let (C1, C2, C3) = GetChannelMapping(For: 0)
            print("CS0 channel map: \(C1),\(C2),\(C3)")
            SetSegmentValues(ToChannels: (C1, C2, C3))
            
        case 1:
            let (C1, C2, C3) = GetChannelMapping(For: 1)
                        print("CS1 channel map: \(C1),\(C2),\(C3)")
                        SetSegmentValues(ToChannels: (C1, C2, C3))
            
        default:
            fatalError("Unexpected color space index \(To) encountered.")
        }
    }
    
    func SetSegmentValues(ToChannels: (Channels, Channels, Channels))
    {
        switch ColorSpaceSegement.selectedSegmentIndex
        {
        case 0:
            let C1Index = RGBChannels.index(of: ToChannels.0)
            let C2Index = RGBChannels.index(of: ToChannels.1)
            let C3Index = RGBChannels.index(of: ToChannels.2)
            Channel1Segment.selectedSegmentIndex = C1Index!
            Channel2Segment.selectedSegmentIndex = C2Index!
            Channel3Segment.selectedSegmentIndex = C3Index!
            
        case 1:
            let C1Index = HSBChannels.index(of: ToChannels.0)
            let C2Index = HSBChannels.index(of: ToChannels.1)
            let C3Index = HSBChannels.index(of: ToChannels.2)
            Channel1Segment.selectedSegmentIndex = C1Index!
            Channel2Segment.selectedSegmentIndex = C2Index!
            Channel3Segment.selectedSegmentIndex = C3Index!
            
        default:
            return
        }
    }
    
    func GetChannelMapping(For: Int) -> (Channels, Channels, Channels)
    {
        var F1: FilterManager.InputFields!
        var F2: FilterManager.InputFields!
        var F3: FilterManager.InputFields!
        
        switch For
        {
        case 0:
            F1 = FilterManager.InputFields.RedChannel
            F2 = FilterManager.InputFields.GreenChannel
            F3 = FilterManager.InputFields.BlueChannel
            
        case 1:
            F1 = FilterManager.InputFields.HueChannel
            F2 = FilterManager.InputFields.SaturationChannel
            F3 = FilterManager.InputFields.BrightnessChannel
            
        default:
            fatalError("Unsupported color space (\(For)) in GetChannelMapping.")
        }
        
        var C1: Int = 0
        var C2: Int = 1
        var C3: Int = 2
        let Raw1 = ParameterManager.GetField(From: FilterID, Field: F1)
        if let P1 = Raw1 as? Int
        {
            C1 = P1
        }
        let Raw2 = ParameterManager.GetField(From: FilterID, Field: F2)
        if let P2 = Raw2 as? Int
        {
            C2 = P2
        }
        let Raw3 = ParameterManager.GetField(From: FilterID, Field: F3)
        if let P3 = Raw3 as? Int
        {
            C3 = P3
        }
        switch For
        {
        case 0:
            let FC1 = RGBChannels[C1]
            let FC2 = RGBChannels[C2]
            let FC3 = RGBChannels[C3]
            return (FC1, FC2, FC3)
            
        case 1:
            let FC1 = HSBChannels[C1 - Channels.Hue.rawValue]
            let FC2 = HSBChannels[C2 - Channels.Hue.rawValue]
            let FC3 = HSBChannels[C3 - Channels.Hue.rawValue]
            return (FC1, FC2, FC3)
            
        default:
            fatalError("Unexpected color space index \(For) encountered.")
        }
        return (.Red, .Green, .Blue)
    }
    
    @IBOutlet weak var ColorSpaceSegement: UISegmentedControl!
    
    @IBAction func HandleColorSpaceChanged(_ sender: Any)
    {
        let NewIndex = ColorSpaceSegement.selectedSegmentIndex
        UpdateSettings(WithValue: NewIndex, Field: FilterManager.InputFields.OutputColorSpace)
        NewColorSpace(NewIndex)
    }
    
    @IBOutlet weak var Channel1Segment: UISegmentedControl!
    @IBOutlet weak var Channel2Segment: UISegmentedControl!
    @IBOutlet weak var Channel3Segment: UISegmentedControl!
    
  
    @IBAction func HandleChannel1Changed(_ sender: Any)
    {
        let Channel1Value = Channel1Segment.selectedSegmentIndex
        let Channel2Value = Channel2Segment.selectedSegmentIndex
        let Channel3Value = Channel3Segment.selectedSegmentIndex
        let (C1, C2, C3) = GetSwizzledChannels(Index1: Channel1Value, Index2: Channel2Value, Index3: Channel3Value)
        UpdateChannelSwizzles(Channel1: C1, Channel2: C2, Channel3: C3)
    }
    
    @IBAction func HandleChannel2Changed(_ sender: Any)
    {
        let Channel1Value = Channel1Segment.selectedSegmentIndex
        let Channel2Value = Channel2Segment.selectedSegmentIndex
        let Channel3Value = Channel3Segment.selectedSegmentIndex
        let (C1, C2, C3) = GetSwizzledChannels(Index1: Channel1Value, Index2: Channel2Value, Index3: Channel3Value)
        UpdateChannelSwizzles(Channel1: C1, Channel2: C2, Channel3: C3)
    }
    
    @IBAction func HandleChannel3Changed(_ sender: Any)
    {
        let Channel1Value = Channel1Segment.selectedSegmentIndex
        let Channel2Value = Channel2Segment.selectedSegmentIndex
        let Channel3Value = Channel3Segment.selectedSegmentIndex
        let (C1, C2, C3) = GetSwizzledChannels(Index1: Channel1Value, Index2: Channel2Value, Index3: Channel3Value)
        UpdateChannelSwizzles(Channel1: C1, Channel2: C2, Channel3: C3)
    }
    
    func PopulateChannelSegments()
    {
        switch ColorSpaceSegement.selectedSegmentIndex
        {
        case 0:
            ChangeSegmentsTo(Segment: Channel1Segment, Seg1: "Red", Seg2: "Green", Seg3: "Blue")
            ChangeSegmentsTo(Segment: Channel2Segment, Seg1: "Red", Seg2: "Green", Seg3: "Blue")
            ChangeSegmentsTo(Segment: Channel3Segment, Seg1: "Red", Seg2: "Green", Seg3: "Blue")
            
        case 1:
            ChangeSegmentsTo(Segment: Channel1Segment, Seg1: "Hue", Seg2: "Saturation", Seg3: "Brightness")
            ChangeSegmentsTo(Segment: Channel2Segment, Seg1: "Hue", Seg2: "Saturation", Seg3: "Brightness")
            ChangeSegmentsTo(Segment: Channel3Segment, Seg1: "Hue", Seg2: "Saturation", Seg3: "Brightness")
            
        default:
            fatalError("Unexpected color space in PopulateChannelSegments")
        }
    }
    
    func ChangeSegmentsTo(Segment: UISegmentedControl, Seg1: String, Seg2: String, Seg3: String)
    {
        Segment.removeAllSegments()
        Segment.insertSegment(withTitle: Seg1, at: 0, animated: true)
        Segment.insertSegment(withTitle: Seg2, at: 1, animated: true)
        Segment.insertSegment(withTitle: Seg3, at: 2, animated: true)
    }
    
    func GetSwizzledChannels(Index1: Int, Index2: Int, Index3: Int) -> (Int, Int, Int)
    {
        var C1: Int = 0
        var C2: Int = 1
        var C3: Int = 2
        switch ColorSpaceSegement.selectedSegmentIndex
        {
        case 0:
            C1 = RGBChannels[Index1].rawValue
            C2 = RGBChannels[Index2].rawValue
            C3 = RGBChannels[Index3].rawValue
            
        case 1:
            C1 = HSBChannels[Index1].rawValue
            C2 = HSBChannels[Index2].rawValue
            C3 = HSBChannels[Index3].rawValue
            
        default:
            return (Channels.Red.rawValue, Channels.Green.rawValue, Channels.Blue.rawValue)
        }
        
        return (C1, C2, C3)
    }
    
    #if true
    let RGBChannelNames =
        [
            "Red",
            "Green",
            "Blue"
    ]
    let HSBChannelNames =
        [
            "Hue",
            "Saturation",
            "Brightness"
    ]
    let RGBChannelNameMap: [String: String] =
        [
            "R": "Red",
            "G": "Green",
            "B": "Blue"
    ]
    let HSBChannelNameMap: [String: String] =
        [
            "H": "Hue",
            "S": "Saturation",
            "L": "Brightness"
    ]
    let RGBChannels: [Channels] = [.Red, .Green, .Blue]
    let RGBChannelsToName: [Channels: String] =
        [
            .Red: "Red",
            .Green: "Green",
            .Blue: "Blue"
    ]
    let RGBChannelValueMap: [String: Channels] =
        [
            "Red": .Red,
            "Green": .Green,
            "Blue": .Blue
    ]
    let HSBChannels: [Channels] = [.Hue, .Saturation, .Brightness]
    let HSBChannelsToName: [Channels: String] =
        [
            .Hue: "Hue",
            .Saturation: "Saturation",
            .Brightness: "Brightness"
    ]
    let HSBChannelValueMap: [String: Channels] =
        [
            "Hue": .Hue,
            "Saturation": .Saturation,
            "Brightness": .Brightness
    ]
    #else
    let ChannelNames =
        [
            "Red",
            "Green",
            "Blue",
            "Hue",
            "Saturation",
            "Brightness",
            "Cyan",
            "Magenta",
            "Yellow",
            "Black"
    ]
    
    let ChannelNameMap: [String: String] =
        [
            "R": "Red",
            "G": "Green",
            "B": "Blue",
            "H": "Hue",
            "S": "Saturation",
            "L": "Brightness",
            "C": "Cyan",
            "M": "Magenta",
            "Y": "Yellow",
            "K": "Black"
    ]
    #endif
    
    func UpdateSettings(WithValue: Int, Field: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: Field, Value: WithValue as Any?)
        ParentDelegate?.NewRawValue()
    }
    
    func UpdateSettings(WithValue: String, Field: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: Field, Value: WithValue as Any?)
        ParentDelegate?.NewRawValue()
    }
    
    func UpdateChannelSwizzles(Channel1: Int, Channel2: Int, Channel3: Int)
    {
        print("Channel1=\(Channel1), Channel2=\(Channel2), Channel3=\(Channel3)")
        var F1: FilterManager.InputFields!
        var F2: FilterManager.InputFields!
        var F3: FilterManager.InputFields!
        switch ColorSpaceSegement.selectedSegmentIndex
        {
        case 0:
            F1 = FilterManager.InputFields.RedChannel
            F2 = FilterManager.InputFields.GreenChannel
            F3 = FilterManager.InputFields.BlueChannel
            
        case 1:
            F1 = FilterManager.InputFields.HueChannel
            F2 = FilterManager.InputFields.SaturationChannel
            F3 = FilterManager.InputFields.BrightnessChannel
            
        default:
            fatalError("Unsupported color space: \(ColorSpaceSegement.selectedSegmentIndex).")
        }
        
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: F1, Value: Channel1 as Any?)
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: F2, Value: Channel2 as Any?)
        ParameterManager.SetField(To: FilterManager.FilterMap[Filter]!,
                                  Field: F3, Value: Channel3 as Any?)
        
        ParentDelegate?.NewRawValue()
    }
    
    @IBOutlet weak var Channel3Label: UILabel!
    @IBOutlet weak var Channel2Label: UILabel!
    @IBOutlet weak var Channel1Label: UILabel!
}
