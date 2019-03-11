//
//  MainUISettings.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Extension to MainUIViewer that contains code related to the management of user settings. Code
/// related to the user changing user settings is elsewhere.
extension MainUIViewer
{
    /// Start monitoring certain settings. This is because they may change out from under the main UI
    /// asynchronously.
    func StartSettingsMonitor()
    {
        _Settings.addObserver(self, forKeyPath: "HideFilterName", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    /// Initialize settings. Should be called only if the value for "SettingsInstalled" is
    /// false or the user wants to reset all settings.
    func InitializeSettings()
    {
        _Settings.set(true, forKey: "SettingsInstalled")
        _Settings.set(false, forKey: "HideFilterName")
        _Settings.set(true, forKey: "SaveOriginalImage")
        _Settings.set(false, forKey: "ShowSaveAlert")
        _Settings.set(false, forKey: "HideFilterSelectionUI")
        _Settings.set(30.0, forKey: "SelectionHideTime")
        _Settings.set(false, forKey: "EnableDepthData")
        _Settings.set("Norio", forKey: "SampleImage")
        _Settings.set(0, forKey: "SetupForFilterType")
        _Settings.set(true, forKey: "ShowFilterSampleImages")
        _Settings.set(true, forKey: "StartWithLastFilter")
        _Settings.set(true, forKey: "ShowClosestColor")
        _Settings.set("", forKey: "UserCopyrightString")
        _Settings.set("", forKey: "UserAuthorString")
        #if DEBUG
        _Settings.set(true, forKey: "SaveRuntimeInformation")
        #else
        _Settings.set(false, forKey: "SaveRuntimeInformation")
        #endif
        _Settings.set(true, forKey: "AllowUserSampleImages")
        _Settings.set(true, forKey: "SaveUserInformationInEXIF")
        _Settings.set(true, forKey: "CollectPerformanceStatistics")
        _Settings.set(true, forKey: "SaveGPSCoordinatesWithImage")
        _Settings.set(false, forKey: "ClosedCleanly")
        #if DEBUG
        _Settings.set(false, forKey: "MaximumPrivacy")
        #else
        _Settings.set(true, forKey: "MaximumPrivacy")
        #endif
        #if DEBUG
        _Settings.set(false, forKey: "ClearRuntimeAtStartup")
        #else
        _Settings.set(true, forKey: "ClearRuntimeAtStartup")
        #endif
        #if DEBUG
        _Settings.set(false, forKey: "ClearScratchAtStartup")
        #else
        _Settings.set(true, forKey: "ClearScratchAtStartup")
        #endif
        #if DEBUG
        _Settings.set(true, forKey: "UseActivityLog")
        #else
        _Settings.set(false, forKey: "UseActivityLog")
        #endif
        #if DEBUG
        _Settings.set(false, forKey: "ShowFramerateOverlay")
        _Settings.set(true, forKey: "IngorePriorCrashes")
        _Settings.set("", forKey: "LastCrashedFilter")
        #endif
        _Settings.set(0, forKey: "ProgramMode")
        _Settings.set(true, forKey: "ShowModeUI")
        _Settings.set(0, forKey: "ColorPickerColorspace")
        #if DEBUG
        _Settings.set(true, forKey: "EnableHeartBeat")
        _Settings.set(60, forKey: "HeartBeatInterval")
        #else
        _Settings.set(false, forKey: "EnableHeartBeat")
        _Settings.set(0, forKey: "HeartBeatInterval")
        #endif
        #if DEBUG
        _Settings.set(true, forKey: "ShowHeartBeatIndicator")
        _Settings.set(0.5, forKey: "HeartRate")
        #endif
        _Settings.set("(Green)@(0.0),(Brown)@(1.0)", forKey: "UserGradient")
        let InitialGroupID = Filters?.GetGroupID(ForGroup: .Standard)
        _Settings.set(InitialGroupID?.uuidString, forKey: "CurrentGroup")
        let InitialFilterID = Filters?.GetFilterID(For: .PassThrough)
        _Settings.set(InitialFilterID?.uuidString, forKey: "CurrentFilter")
        ParameterManager.CreateInitialStorage(Filters: Filters!, ImplementedFilters: Filters!.ImplementedFilters())
    }
}
