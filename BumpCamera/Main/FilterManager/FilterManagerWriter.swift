//
//  FilterManagerWriter.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

extension FilterManager
{
    /// Returns current state of a filter as an XML fragment string.
    ///
    /// - Parameters:
    ///   - For: Instantiation of a filter whose state is returned.
    ///   - FrameNumber: Optional frame number.
    ///   - TimeStamp: Optional time stamp.
    ///   - ActiveFilter: Boolean that indicates the filter being dumped is active. Intended for use for changing filter settings
    ///                   for running filters.
    /// - Returns: XML fragment with informatin describing the filter.
    public static func GetFilterSettingString(For: Renderer, FrameNumber: Int? = nil, TimeStamp: Date? = nil,
                                              ActiveFilter: Bool = false, ShowVersionInfo: Bool = true) -> String
    {
        let ID = For.ID()
        let FilterType = GetFilterTypeFrom(ID: ID)
        var Aux = ""
        if let FrameCount = FrameNumber
        {
            Aux = " Frame=\"\(FrameCount)\""
        }
        let IsActiveFilter = " Active=\"\(ActiveFilter)\""
        if let When = TimeStamp
        {
            let WhenS = Utility.MakeTimeStamp(FromDate: When)
            Aux = Aux + " TimeStamp=\"\(WhenS)\""
        }
        var Working = "<Filter Name=\(For.Title()) ID=\(For.ID())\(Aux)\(IsActiveFilter)>\n"
        if ShowVersionInfo
        {
            Working = Working + Versioning.EmitXML(4) + "\n"
        }
        Working = Working + "    <Parameters Count=\"\(ParameterCountFor(FilterType!))\">\n"
        
        for SomeField in For.SupportedFields()
        {
            let FieldName = FieldStorageMap[SomeField]!
            let FieldType = FieldMap[SomeField]
            let FieldTypeName = FieldTypeNameMap[FieldType!]!
            let (_, Anything, _) = ParameterManager.GetFieldDataEx(From: ID, Field: SomeField)
            let FieldContents = ParameterManager.ConvertAny(Anything, OfType: FieldType!)
            Working = Working + "        <Parameter Name=\"\(FieldName)\" Type=\"\(FieldTypeName)\" Contents=\"\(FieldContents)\">\n"
        }
        
        Working = Working + "    </Parameters>\n"
        Working = Working + "</Filter>\n"
        
        return Working
    }
    
    /// Save filter settings for the passed filter.
    ///
    /// - Parameters:
    ///   - For: Instance of the filter to save settings for.
    ///   - WithName: File name to use for the saved file. If not specified, "MostRecentFilter.xml" will be used.
    ///   - InDirectory: Directory where to save the file. If not specified, the runtime directory will be used.
    public static func SaveFilterSettings(For: Renderer, WithName: String? = nil, InDirectory: String? = nil,
                                          FrameNumber: Int? = nil, TimeStamp: Date? = nil)
    {
        let FileName: String = WithName == nil ? "MostRecentFilter.xml" : WithName!
        let Directory: String = InDirectory == nil ? FileHandler.RuntimeDirectory : InDirectory!
        let Working = GetFilterSettingString(For: For, FrameNumber: FrameNumber, TimeStamp: TimeStamp)
        FileHandler.SaveStringToFile(Working, FileName: FileName, ToDirectory: Directory)
    }
    
    /// Generate filter performance statistics in the specified type and returned as a (probably large) string.
    ///
    /// - Parameter AsType: Determines the type of string returned.
    /// - Returns: Filter performance statistics in the specified format as a string.
    public static func GeneratePerformanceStatistics(AsType: ExportDataTypes) -> String
    {
        let DateString = Utility.MakeTimeStamp(FromDate: Date(), TimeSeparator: ".")
        //var FileName = "FilterPerformance." + DateString
        let RawData = ParameterManager.DumpRenderData()
        var Working = ""
        let GPUName = Platform.MetalGPU()
        let MetalDevice = Platform.MetalDeviceName()
        let (CPUName, CPUFreq) = Platform.GetProcessorInfo()
        let iOSVer = Platform.iOSVersion()
        let NiceModel = Platform.NiceModelName()
        let SysOSName = Platform.SystemOSName()
        let SysPressure = Platform.GetSystemPressure()
        let (UsedMem, FreeMem) = Platform.RAMSize()
        let MetalSpace = Platform.MetalAllocatedSpace()
        var DebugDeviceName = ""
        var DebugIsOn = "NO"
        #if DEBUG
        DebugIsOn = "YES"
        DebugDeviceName = Platform.SystemName()
        #endif
        switch AsType
        {
        case .CSV:
            //FileName = FileName + ".csv"
            Working = "BumpCamera Filter Performance,\(DateString),,,,\n"
            Working = Working + "Filter Type,Filter Name,Image Count,Image Total,Live Count,LiveTotal\n"
            for (FilterType, KernelType, ImageCount, ImageTotal, LiveCount, LiveTotal) in RawData
            {
                var OneLine = KernelType.rawValue + "," + GetFilterTitle(FilterType)! + ","
                OneLine = OneLine + "\(ImageCount),\(ImageTotal),\(LiveCount),\(LiveTotal)\n"
                Working = Working + OneLine
            }
            break;
            
        case .XML:
            //FileName = FileName + ".xml"
            Working = Working + "<FilterPerformance For=\"BumpCamera\" ExportedOn=\"\(DateString)\">\n"
            Working = Working + Versioning.EmitXML() + "\n"
            Working = Working + "  <SystemReport DebugBuild=\"\(DebugIsOn)\">\n"
            #if DEBUG
            Working = Working + "    <Device Model=\"\(NiceModel)\" DeviceName=\"\(DebugDeviceName)\">\n"
            #else
            Working = Working + "    <Device Model=\"\(NiceModel)\">\n"
            #endif
            Working = Working + "    <CPU Name=\"\(CPUName)\" BaseFrequency=\"\(CPUFreq)\">\n"
            Working = Working + "    <GPU Name=\"\(GPUName)\" Metal=\"\(MetalDevice)\">\n"
            Working = Working + "    <Memory Used=\"\(UsedMem)\" Free=\"\(FreeMem)\" MetalAllocated=\"\(MetalSpace)\">\n"
            Working = Working + "    <OS Name=\"\(SysOSName)\" Version=\"\(iOSVer)\">\n"
            Working = Working + "    <Current SystemPressure=\"\(SysPressure)\">\n"
            Working = Working + "  </SystemReport>\n"
            for (FilterType, KernelType, ImageCount, ImageTotal, LiveCount, LiveTotal) in RawData
            {
                var OneLine = "  <Filter Name=\"\(GetFilterTitle(FilterType)!)\" KernelType=\"\(KernelType.rawValue)\">\n"
                OneLine = OneLine + "    <ImagePerformance Count=\"\(ImageCount)\" TotalSeconds=\"\(ImageTotal)\"/>\n"
                OneLine = OneLine + "    <LivePerformance Count=\"\(LiveCount)\" TotalSeconds=\"\(LiveTotal)\"/>\n"
                OneLine = OneLine + "  </Filter>\n"
                Working = Working + OneLine
            }
            Working = Working + "</FilterPerformance>\n"
            break;
            
        case .JSON:
            //FileName = FileName + ".json"
            Working = "{\n"
            Working = Working + "  \"PerformanceFor\": \"BumpCamera\",\n"
            Working = Working + "  \"ExportedOn\": \"\(DateString)\",\n"
            Working = Working + "  \"DebugBuild\": \"\(DebugIsOn)\",\n"
            Working = Working + "  \"Model\": \"\(NiceModel)\",\n"
            #if DEBUG
            Working = Working + "  \"DeviceName\": \"\(DebugDeviceName)\",\n"
            #endif
            Working = Working + "  \"CPUName\": \"\(CPUName)\",\n"
            Working = Working + "  \"CPUFreq\": \"\(CPUFreq)\",\n"
            Working = Working + "  \"GPUName\": \"\(GPUName)\",\n"
            Working = Working + "  \"Metal\": \"\(MetalDevice)\",\n"
            Working = Working + "  \"MemoryUsed\": \"\(UsedMem)\",\n"
            Working = Working + "  \"MemoryFree\": \"\(FreeMem)\",\n"
            Working = Working + "  \"MetalAllocated\": \"\(MetalSpace)\",\n"
            Working = Working + "  \"OS\": \"\(SysOSName)\",\n"
            Working = Working + "  \"OSVersion\": \"\(iOSVer)\",\n"
            Working = Working + "  \"SystemPressure\": \"\(SysPressure)\",\n"
            Working = Working + "  \"Filter\":\n"
            Working = Working + "  [\n"
            
            for (FilterType, KernelType, ImageCount, ImageTotal, LiveCount, LiveTotal) in RawData
            {
                var OneLine = "    {\n"
                OneLine = OneLine + "      \"Name\": \"\(GetFilterTitle(FilterType)!)\",\n"
                OneLine = OneLine + "      \"KernelType\": \"\(KernelType.rawValue)\",\n"
                OneLine = OneLine + "      \"ImagePerformance\":\n"
                OneLine = OneLine + "      {\n"
                OneLine = OneLine + "        \"Count\": \"\(ImageCount)\",\n"
                OneLine = OneLine + "        \"TotalSeconds\": \"\(ImageTotal)\",\n"
                OneLine = OneLine + "      },\n"
                OneLine = OneLine + "      \"LivePerformance\":\n"
                OneLine = OneLine + "      {\n"
                OneLine = OneLine + "        \"Count\": \"\(LiveCount)\",\n"
                OneLine = OneLine + "        \"TotalSeconds\": \"\(LiveTotal)\",\n"
                OneLine = OneLine + "      },\n"
                OneLine = OneLine + "    },\n"
                Working = Working + OneLine
            }
            
            Working = Working + "  ]\n"
            Working = Working + "}\n"
            break
        }
        
        return Working
    }
    
    /// Export filter performance statistics to a file. The file is saved off the top-level BumpCamera directory in
    /// /PerformanceData.
    ///
    /// - Parameter AsType: Determines the format of the exported file.
    /// - Returns: Tuple with the success flag and file name used.
    public static func ExportPerformanceStatistics(AsType: ExportDataTypes) -> (Bool, String)
    {
        let DateString = Utility.MakeTimeStamp(FromDate: Date(), TimeSeparator: ".")
        let FileName = "FilterPerformance." + DateString + [ExportDataTypes.CSV: ".csv", ExportDataTypes.XML: ".xml", ExportDataTypes.JSON: ".json"][AsType]!
        #if false
        let DateString = Utility.MakeTimeStamp(FromDate: Date(), TimeSeparator: ".")
        var FileName = "FilterPerformance." + DateString
        let RawData = ParameterManager.DumpRenderData()
        var Working = ""
        let GPUName = Platform.MetalGPU()
        let MetalDevice = Platform.MetalDeviceName()
        let (CPUName, CPUFreq) = Platform.GetProcessorInfo()
        let iOSVer = Platform.iOSVersion()
        let NiceModel = Platform.NiceModelName()
        let SysOSName = Platform.SystemOSName()
        let SysPressure = Platform.GetSystemPressure()
        let (UsedMem, FreeMem) = Platform.RAMSize()
        let MetalSpace = Platform.MetalAllocatedSpace()
        var DebugDeviceName = ""
        var DebugIsOn = "NO"
        #if DEBUG
        DebugIsOn = "YES"
        DebugDeviceName = Platform.SystemName()
        #endif
        switch AsType
        {
        case .CSV:
            FileName = FileName + ".csv"
            Working = "BumpCamera Filter Performance,\(DateString),,,,\n"
            Working = Working + "Filter Type,Filter Name,Image Count,Image Total,Live Count,LiveTotal\n"
            for (FilterType, KernelType, ImageCount, ImageTotal, LiveCount, LiveTotal) in RawData
            {
                var OneLine = KernelType.rawValue + "," + GetFilterTitle(FilterType)! + ","
                OneLine = OneLine + "\(ImageCount),\(ImageTotal),\(LiveCount),\(LiveTotal)\n"
                Working = Working + OneLine
            }
            break;
            
        case .XML:
            FileName = FileName + ".xml"
            Working = Working + "<FilterPerformance For=\"BumpCamera\" ExportedOn=\"\(DateString)\">\n"
            Working = Working + Versioning.EmitXML() + "\n"
            Working = Working + "  <SystemReport DebugBuild=\"\(DebugIsOn)\">\n"
            #if DEBUG
            Working = Working + "    <Device Model=\"\(NiceModel)\" DeviceName=\"\(DebugDeviceName)\">\n"
            #else
            Working = Working + "    <Device Model=\"\(NiceModel)\">\n"
            #endif
            Working = Working + "    <CPU Name=\"\(CPUName)\" BaseFrequency=\"\(CPUFreq)\">\n"
            Working = Working + "    <GPU Name=\"\(GPUName)\" Metal=\"\(MetalDevice)\">\n"
            Working = Working + "    <Memory Used=\"\(UsedMem)\" Free=\"\(FreeMem)\" MetalAllocated=\"\(MetalSpace)\">\n"
            Working = Working + "    <OS Name=\"\(SysOSName)\" Version=\"\(iOSVer)\">\n"
            Working = Working + "    <Current SystemPressure=\"\(SysPressure)\">\n"
            Working = Working + "  </SystemReport>\n"
            for (FilterType, KernelType, ImageCount, ImageTotal, LiveCount, LiveTotal) in RawData
            {
                var OneLine = "  <Filter Name=\"\(GetFilterTitle(FilterType)!)\" KernelType=\"\(KernelType.rawValue)\">\n"
                OneLine = OneLine + "    <ImagePerformance Count=\"\(ImageCount)\" TotalSeconds=\"\(ImageTotal)\"/>\n"
                OneLine = OneLine + "    <LivePerformance Count=\"\(LiveCount)\" TotalSeconds=\"\(LiveTotal)\"/>\n"
                OneLine = OneLine + "  </Filter>\n"
                Working = Working + OneLine
            }
            Working = Working + "</FilterPerformance>\n"
            break;
            
        case .JSON:
            FileName = FileName + ".json"
            Working = "{\n"
            Working = Working + "  \"PerformanceFor\": \"BumpCamera\",\n"
            Working = Working + "  \"ExportedOn\": \"\(DateString)\",\n"
            Working = Working + "  \"DebugBuild\": \"\(DebugIsOn)\",\n"
            Working = Working + "  \"Model\": \"\(NiceModel)\",\n"
            #if DEBUG
            Working = Working + "  \"DeviceName\": \"\(DebugDeviceName)\",\n"
            #endif
            Working = Working + "  \"CPUName\": \"\(CPUName)\",\n"
            Working = Working + "  \"CPUFreq\": \"\(CPUFreq)\",\n"
            Working = Working + "  \"GPUName\": \"\(GPUName)\",\n"
            Working = Working + "  \"Metal\": \"\(MetalDevice)\",\n"
            Working = Working + "  \"MemoryUsed\": \"\(UsedMem)\",\n"
            Working = Working + "  \"MemoryFree\": \"\(FreeMem)\",\n"
            Working = Working + "  \"MetalAllocated\": \"\(MetalSpace)\",\n"
            Working = Working + "  \"OS\": \"\(SysOSName)\",\n"
            Working = Working + "  \"OSVersion\": \"\(iOSVer)\",\n"
            Working = Working + "  \"SystemPressure\": \"\(SysPressure)\",\n"
            Working = Working + "  \"Filter\":\n"
            Working = Working + "  [\n"
            
            for (FilterType, KernelType, ImageCount, ImageTotal, LiveCount, LiveTotal) in RawData
            {
                var OneLine = "    {\n"
                OneLine = OneLine + "      \"Name\": \"\(GetFilterTitle(FilterType)!)\",\n"
                OneLine = OneLine + "      \"KernelType\": \"\(KernelType.rawValue)\",\n"
                OneLine = OneLine + "      \"ImagePerformance\":\n"
                OneLine = OneLine + "      {\n"
                OneLine = OneLine + "        \"Count\": \"\(ImageCount)\",\n"
                OneLine = OneLine + "        \"TotalSeconds\": \"\(ImageTotal)\",\n"
                OneLine = OneLine + "      },\n"
                OneLine = OneLine + "      \"LivePerformance\":\n"
                OneLine = OneLine + "      {\n"
                OneLine = OneLine + "        \"Count\": \"\(LiveCount)\",\n"
                OneLine = OneLine + "        \"TotalSeconds\": \"\(LiveTotal)\",\n"
                OneLine = OneLine + "      },\n"
                OneLine = OneLine + "    },\n"
                Working = Working + OneLine
            }
            
            Working = Working + "  ]\n"
            Working = Working + "}\n"
            break
        }
        #else
        let Working = GeneratePerformanceStatistics(AsType: AsType)
        #endif
        
        FileHandler.SaveStringToFile(Working, FileName: FileName)
        
        return (true, FileName)
    }
}
