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
        let InitialGroupID = Filters?.GetGroupID(ForGroup: .Standard)
        _Settings.set(InitialGroupID?.uuidString, forKey: "CurrentGroup")
        let InitialFilterID = Filters?.GetFilterID(For: .PassThrough)
        _Settings.set(InitialFilterID?.uuidString, forKey: "CurrentFilter")
        ParameterManager.CreateInitialStorage(Filters: Filters!, ImplementedFilters: Filters!.ImplementedFilters())
    }
}
