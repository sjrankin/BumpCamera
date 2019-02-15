//
//  Platform.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import Metal
import AVFoundation

class Platform
{
    /// Returns the type of processor architecture we're running on.
    ///
    /// - Returns: String description of the processor's architecture.
    public static func MachineType() -> String
    {
        var SysInfo = utsname()
        uname(&SysInfo)
        let Name = withUnsafePointer(to: &SysInfo.machine.0)
        {
            ptr in
            return String(cString: ptr)
        }
        return Name
    }
    
    /// Returns the user's name for the device.
    ///
    /// - Returns: Name of the device as given by the user.
    public static func SystemName() -> String
    {
        var SysInfo = utsname()
        uname(&SysInfo)
        let Name = withUnsafePointer(to: &SysInfo.nodename.0)
        {
            ptr in
            return String(cString: ptr)
        }
        let Parts = Name.split(separator: ".")
        return String(Parts[0])
    }
    
    /// Returns the Kernel name and version.
    ///
    /// - Returns: OS kernel name and version.
    public static func KernelInfo() -> String
    {
        var SysInfo = utsname()
        uname(&SysInfo)
        let Name = withUnsafePointer(to: &SysInfo.nodename.0)
        {
            ptr in
            return String(cString: ptr)
        }
        let Parts = Name.split(separator: ":")
        return String(Parts[0])
    }
    
    public static func iOSVersion() -> String
    {
        let SysVer = UIDevice.current.systemVersion
        return SysVer
    }
    
    public static func SystemOSName() -> String
    {
        return UIDevice.current.systemName
    }
    
    public static func GetSystemPressure() -> String
    {
        let VideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,
                                                                                         .builtInWideAngleCamera],
                                                                           mediaType: .video,
                                                                           position: .unspecified)
         let DefaultVideoDevice: AVCaptureDevice? = VideoDeviceDiscoverySession.devices.first
        let Pressure = DefaultVideoDevice?.systemPressureState
        switch (Pressure?.level)!
        {
        case .nominal:
            return "Nominal"
            
        case .fair:
            return "Fair"
            
        case .serious:
            return "Serious"
            
        case .critical:
            return "Critical"
            
        case .shutdown:
            return "Catastrophic"
            
        default:
            return "Unknown"
        }
    }
    
    /// Return the amount of RAM (used and unused) on the system.
    ///
    /// - Note: [Determining the Available Amount of RAM on an iOS Device](https://stackoverflow.com/questions/5012886/determining-the-available-amount-of-ram-on-an-ios-device)
    ///
    /// - Returns: Tuple with the values (Used memory, free memory).
    public static func RAMSize() -> (Int64, Int64)
    {
        var PageSize: vm_size_t = 0
        let HostPort: mach_port_t = mach_host_self()
        var HostSize: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(HostPort, &PageSize)
        var vm_stat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat)
        {
            (vmStatPointer) -> Void in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(HostSize))
            {
                if host_statistics(HostPort, HOST_VM_INFO, $0, &HostSize) != KERN_SUCCESS
                {
                    print("Error: failed to get vm statistics")
                }
            }
        }
        let MemUsed: Int64 = Int64(vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * Int64(PageSize)
        let MemFree: Int64 = Int64(vm_stat.free_count) * Int64(PageSize)
        return (MemUsed, MemFree)
    }
    
    public static func BatteryLevel() -> Float?
    {
        if UIDevice.current.isBatteryMonitoringEnabled
        {
            return UIDevice.current.batteryLevel
        }
        else
        {
            return nil
        }
    }
    
    public static func MonitorBatteryLevel(_ Enabled: Bool)
    {
        UIDevice.current.isBatteryMonitoringEnabled = Enabled
    }
    
    //https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
    public static func NiceModelName() -> String
    {
        let ModelType = UIDevice.current.SystemType
        let ModelTypeString = ModelType.rawValue
        return ModelTypeString
    }
    
    public static func GetProcessorInfo() -> (String, String)
    {
        let (CPUName, CPUFrequency) = Processor[UIDevice.current.SystemType]!
        return (CPUName, CPUFrequency)
    }
    
    public static func HasTrueDepthCamera() -> Bool
    {
        return GetCameraResolution(CameraType: .builtInTrueDepthCamera, Position: .back) != nil
    }
    
    public static func HasTelephotoCamera() -> Bool
    {
        return GetCameraResolution(CameraType: .builtInTelephotoCamera, Position: .back) != nil
    }
    
    public static func GetCameraResolution(CameraType: AVCaptureDevice.DeviceType, Position: AVCaptureDevice.Position) -> CGSize?
    {
        var Resolution = CGSize.zero
        if let CaptureDevice = AVCaptureDevice.default(CameraType, for: AVMediaType.video, position: Position)
        {
            let Description = CaptureDevice.activeFormat.formatDescription
            let Dimensions = CMVideoFormatDescriptionGetDimensions(Description)
            Resolution = CGSize(width: CGFloat(Dimensions.width), height: CGFloat(Dimensions.height))
            return Resolution
        }
        else
        {
            return nil
        }
    }
    
    public static func MetalGPU() -> String
    {
        let MetalDevice = MTLCreateSystemDefaultDevice()
        var SupportedGPU = ""
        var GPUValue: UInt = 0
        for (GPUFamily, _) in MetalFeatureTable
        {
            if (MetalDevice?.supportsFeatureSet(GPUFamily))!
            {
                if GPUFamily.rawValue > GPUValue
                {
                    GPUValue = GPUFamily.rawValue
                }
            }
        }
        
        let FinalGPU = MTLFeatureSet(rawValue: GPUValue)
        SupportedGPU = MetalFeatureTable[FinalGPU!]!
        return SupportedGPU.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public static func MetalDeviceName() -> String
    {
        let MetalDevice = MTLCreateSystemDefaultDevice()
        return (MetalDevice?.name)!
    }
    
    public static func MetalAllocatedSpace() -> String
    {
        let MetalDevice = MTLCreateSystemDefaultDevice()
        let Allocated = MetalDevice?.currentAllocatedSize
        return Utility.MakeSeparatedNumber(Allocated!, Separator: ",")
    }
    
    static let MetalFeatureTable: [MTLFeatureSet: String] =
        [
            MTLFeatureSet.iOS_GPUFamily1_v1: "GPU 1, v1",
            MTLFeatureSet.iOS_GPUFamily1_v2: "GPU 1, v2",
            MTLFeatureSet.iOS_GPUFamily1_v3: "GPU 1, v3",
            MTLFeatureSet.iOS_GPUFamily1_v4: "GPU 1, v4",
            MTLFeatureSet.iOS_GPUFamily1_v5: "GPU 1, v5",
            MTLFeatureSet.iOS_GPUFamily2_v1: "GPU 2, v1",
            MTLFeatureSet.iOS_GPUFamily2_v2: "GPU 2, v2",
            MTLFeatureSet.iOS_GPUFamily2_v3: "GPU 2, v2",
            MTLFeatureSet.iOS_GPUFamily2_v4: "GPU 2, v4",
            MTLFeatureSet.iOS_GPUFamily2_v5: "GPU 2, v5",
            MTLFeatureSet.iOS_GPUFamily3_v1: "GPU 3, v1",
            MTLFeatureSet.iOS_GPUFamily3_v2: "GPU 3, v2",
            MTLFeatureSet.iOS_GPUFamily3_v3: "GPU 3, v2",
            MTLFeatureSet.iOS_GPUFamily3_v4: "GPU 3, v4",
            MTLFeatureSet.iOS_GPUFamily4_v1: "GPU 4, v1",
            MTLFeatureSet.iOS_GPUFamily4_v2: "GPU 4, v2",
            MTLFeatureSet.iOS_GPUFamily5_v1: "GPU 5, v1"
    ]
    
    //https://www.devicespecifications.com/en/brand/cefa26
    private static let Processor: [Model: (String, String)] =
        [
            .simulator        : ("N/A", ""),
            .iPad2            : ("A5", "1GHz"),
            .iPad3            : ("A5X", "1GHz"),
            .iPad4            : ("A6X", "1.4GHz"),
            .iPhone4          : ("A4", "800MHz"),
            .iPhone4S         : ("A5", "800MHz"),
            .iPhone5          : ("A6", "1.3GHz"),
            .iPhone5S         : ("A7", "1.3GHz"),
            .iPhone5C         : ("A6", "1.3GHz"),
            .iPadMini1        : ("A5", "1GHz"),
            .iPadMini2        : ("A7", "1.3GHz"),
            .iPadMini3        : ("A7", "1.3GHz"),
            .iPadMini4        : ("A8", "1.5GHz"),
            .iPadAir1         : ("A7", "1.3GHz"),
            .iPadAir2         : ("A8X", "1.5GHz"),
            .iPadPro9_7       : ("A9X", "2.26GHz"),
            .iPadPro9_7_cell  : ("A9X", "2.26GHz"),
            .iPadPro10_5      : ("A10X", "2.36GHz"),
            .iPadPro10_5_cell : ("A10X", "2.36GHz"),
            .iPadPro12_9      : ("A10X Fusion", "2.36GHz"),
            .iPadPro12_9_cell : ("A10X Fusion", "2.36GHz"),
            .iPadPro11        : ("A12X Bionic", "2.5GHz"),
            .iPadPro11_cell   : ("A12X Bionic", "2.5GHz"),
            .iPadPro12_9_3g : ("A12X Bionic", "2.5GHz"),
            .iPadPro12_9_3g_cell: ("A12X Bionic", "2.5GHz"),
            .iPhone6          : ("A8", "1.4GHz"),
            .iPhone6plus      : ("A8", "1.4GHz"),
            .iPhone6S         : ("A8", "1.4GHz"),
            .iPhone6Splus     : ("A8", "1.4GHz"),
            .iPhoneSE         : ("A9", "1.84GHz"),
            .iPhone7          : ("A10", "2.37GHz"),
            .iPhone7plus      : ("A10", "2.37GHz"),
            .iPhone8          : ("A11 Bionic", "2.1GHz"),
            .iPhone8plus      : ("A11 Bionic", "2.1GHz"),
            .iPhoneX          : ("A11 Bionic", "2.39GHz"),
            .iPhoneXS         : ("A12 Bionic", "2.49GHz"),
            .iPhoneXSmax      : ("A12 Bionic", "2.49GHz"),
            .iPhoneXR         : ("A12 Bionic", "2.49GHz"),
            .unrecognized     : ("?unrecognized?", "")
    ]
}

//https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
public enum Model : String
{
    case simulator   = "simulator/sandbox",
    iPad2            = "iPad 2",
    iPad3            = "iPad 3",
    iPad4            = "iPad 4",
    iPhone4          = "iPhone 4",
    iPhone4S         = "iPhone 4S",
    iPhone5          = "iPhone 5",
    iPhone5S         = "iPhone 5S",
    iPhone5C         = "iPhone 5C",
    iPadMini1        = "iPad Mini 1",
    iPadMini2        = "iPad Mini 2",
    iPadMini3        = "iPad Mini 3",
    iPadMini4        = "iPad Mini 4",
    iPadAir1         = "iPad Air 1",
    iPadAir2         = "iPad Air 2",
    iPadPro9_7       = "iPad Pro 9.7\"",
    iPadPro9_7_cell  = "iPad Pro 9.7\" cellular",
    iPadPro10_5      = "iPad Pro 10.5\"",
    iPadPro10_5_cell = "iPad Pro 10.5\" cellular",
    iPadPro12_9      = "iPad Pro 12.9\"",
    iPadPro12_9_cell = "iPad Pro 12.9\" cellular",
    iPadPro11        = "iPad Pro 11\"",
    iPadPro11_cell   = "iPad Pro 11\" cellular",
    iPadPro12_9_3g   = "iPad Pro 12.9\" 3rd gen",
    iPadPro12_9_3g_cell = "iPad Pro 12.9\" celular 3rd gen",
    iPhone6          = "iPhone 6",
    iPhone6plus      = "iPhone 6 Plus",
    iPhone6S         = "iPhone 6S",
    iPhone6Splus     = "iPhone 6S Plus",
    iPhoneSE         = "iPhone SE",
    iPhone7          = "iPhone 7",
    iPhone7plus      = "iPhone 7 Plus",
    iPhone8          = "iPhone 8",
    iPhone8plus      = "iPhone 8 Plus",
    iPhoneX          = "iPhone X",
    iPhoneXS         = "iPhone XS",
    iPhoneXSmax      = "iPhone XS Max",
    iPhoneXR         = "iPhone XR",
    unrecognized     = "?unrecognized?"
}

//https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
public extension UIDevice
{
    public var SystemType: Model
    {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine)
        {
            $0.withMemoryRebound(to: CChar.self, capacity: 1)
            {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        var modelMap : [String : Model] =
            [
            "i386"       : .simulator,
            "x86_64"     : .simulator,
            "iPad2,1"    : .iPad2,
            "iPad2,2"    : .iPad2,
            "iPad2,3"    : .iPad2,
            "iPad2,4"    : .iPad2,
            "iPad2,5"    : .iPadMini1,
            "iPad2,6"    : .iPadMini1,
            "iPad2,7"    : .iPadMini1,
            "iPhone3,1"  : .iPhone4,
            "iPhone3,2"  : .iPhone4,
            "iPhone3,3"  : .iPhone4,
            "iPhone4,1"  : .iPhone4S,
            "iPhone5,1"  : .iPhone5,
            "iPhone5,2"  : .iPhone5,
            "iPhone5,3"  : .iPhone5C,
            "iPhone5,4"  : .iPhone5C,
            "iPad3,1"    : .iPad3,
            "iPad3,2"    : .iPad3,
            "iPad3,3"    : .iPad3,
            "iPad3,4"    : .iPad4,
            "iPad3,5"    : .iPad4,
            "iPad3,6"    : .iPad4,
            "iPhone6,1"  : .iPhone5S,
            "iPhone6,2"  : .iPhone5S,
            "iPad4,1"    : .iPadAir1,
            "iPad4,2"    : .iPadAir2,
            "iPad4,4"    : .iPadMini2,
            "iPad4,5"    : .iPadMini2,
            "iPad4,6"    : .iPadMini2,
            "iPad4,7"    : .iPadMini3,
            "iPad4,8"    : .iPadMini3,
            "iPad4,9"    : .iPadMini3,
            "iPad5,1"    : .iPadMini4,
            "iPad5,2"    : .iPadMini4,
            "iPad6,3"    : .iPadPro9_7,
            "iPad6,11"   : .iPadPro9_7,
            "iPad6,4"    : .iPadPro9_7_cell,
            "iPad6,12"   : .iPadPro9_7_cell,
            "iPad6,7"    : .iPadPro12_9,
            "iPad6,8"    : .iPadPro12_9_cell,
            "iPad7,3"    : .iPadPro10_5,
            "iPad7,4"    : .iPadPro10_5_cell,
            "iPad8,1"    : .iPadPro11,
            "iPad8,2"    : .iPadPro11,
            "iPad8,3"    : .iPadPro11_cell,
            "iPad8,4"    : .iPadPro11_cell,
            "iPad8,5"    : .iPadPro12_9_3g,
            "iPad8,6"    : .iPadPro12_9_3g,
            "iPad8,7"    : .iPadPro12_9_3g_cell,
            "iPad8,8"    : .iPadPro12_9_3g_cell,
            "iPhone7,1"  : .iPhone6plus,
            "iPhone7,2"  : .iPhone6,
            "iPhone8,1"  : .iPhone6S,
            "iPhone8,2"  : .iPhone6Splus,
            "iPhone8,4"  : .iPhoneSE,
            "iPhone9,1"  : .iPhone7,
            "iPhone9,2"  : .iPhone7plus,
            "iPhone9,3"  : .iPhone7,
            "iPhone9,4"  : .iPhone7plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,2" : .iPhone8plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,6" : .iPhoneX,
            "iPhone11,2" : .iPhoneXS,
            "iPhone11,4" : .iPhoneXSmax,
            "iPhone11,6" : .iPhoneXSmax,
            "iPhone11,8" : .iPhoneXR
        ]
        
        if let model = modelMap[String.init(validatingUTF8: modelCode!)!]
        {
            return model
        }
        return Model.unrecognized
    }
}
