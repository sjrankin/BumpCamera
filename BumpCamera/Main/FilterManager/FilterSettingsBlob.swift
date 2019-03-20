//
//  FilterSettingsBlob.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation

/// Contains all settings and values for a filter, except for performance settings.
class FilterSettingsBlob
{
    /// Contains the map of settings.
    private var SettingMap = [FilterManager.InputFields: Any?]()
    
    /// Clear all settings from the blob.
    func Clear()
    {
        SettingMap.removeAll()
    }
    
    /// Determines if the blob currently contains the passed input field.
    ///
    /// - Parameter SettingField: Input field to determine existence in the blob.
    /// - Returns: True if the input field has been added, false if not.
    func HasSetting(_ SettingField: FilterManager.InputFields) -> Bool
    {
        return SettingMap[SettingField] != nil
    }
    
    /// Add an input field/setting pair to the filter settings blob.
    ///
    /// - Parameters:
    ///   - SettingField: The filter's input field.
    ///   - SettingValue: The filter's input field's value.
    func AddSetting(_ SettingField: FilterManager.InputFields, _ SettingValue: Any?)
    {
        SettingMap[SettingField] = SettingValue
    }
    
    /// Get the value of the passed input field.
    ///
    /// - Parameter SettingField: The input field whose value will be returned.
    /// - Returns: The value of the input field (cast as Any?) on success, nil if not found.
    func GetSetting(_ SettingField: FilterManager.InputFields) -> Any?
    {
        if let AnyValue = SettingMap[SettingField]
        {
            return AnyValue
        }
        return nil
    }
}
