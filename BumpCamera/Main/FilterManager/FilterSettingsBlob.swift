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
    
    /// Change a setting in the blob. If the setting doesn't exist, it is added.
    ///
    /// - Parameters:
    ///   - SettingField: The field whose setting value will change.
    ///   - NewValue: The new value for the setting.
    func ChangeSetting(_ SettingField: FilterManager.InputFields, To NewValue: Any?)
    {
        if !HasSetting(SettingField)
        {
            SettingMap[SettingField] = NewValue
            return
        }
        SettingMap[SettingField] = NewValue
    }
    
    /// Serializes the contents of the passed instance of a FilterSettingsBlob into an
    /// XML-like string.
    ///
    /// - Parameter Instance: The instance whose values will be serialized.
    /// - Returns: XML-like string of the contents of the passed instance. This string
    ///            can be passed to `Deserialize` to create a new FilterSettingsBlob
    ///            instance.
    public static func Serialize(_ Instance: FilterSettingsBlob) -> String
    {
        var Ser = ""
        for (Field, SomeValue) in Instance.SettingMap
        {
            if let InputType = FilterManager.FieldTypeForInputField(Field)
            {
                var Result = ParameterManager.ConvertAny(SomeValue, OfType: InputType)
                Result = Utility.MakeSpecialQuotedString(Result)
                let SXr = Utility.MakeNVP(Name: "\(Field.rawValue)", Value: Result)
                Ser = Ser + SXr + "\u{1012}"
            }
        }
        Ser.removeLast(1)
        return Ser
    }
    
    /// Deserialize the passed string (which needs to have been serialized by
    /// `FilterSettingsBlob.Serialize` first) and return a new instance of a
    /// FilterSettingsBlob populated with the passed serialized string.
    ///
    /// - Parameter Serialized: The serialized string (which should have been serialized
    ///                         by `FilterSettingsBlob.Serialize`).
    /// - Returns: New instance of a FilterSettingsBlob populated by data from the passed
    ///            string. On failure, nil is returned.
    public static func Deserialize(_ Serialized: String) -> FilterSettingsBlob?
    {
        let Parts = Serialized.split(separator: "\u{1012}")
        let NewBlob = FilterSettingsBlob()
        for Part in Parts
        {
            let Serialized = String(Part)
            let SettingParts = Serialized.split(separator: "=")
            if SettingParts.count != 2
            {
                continue
            }
            let RawData = Utility.RemoveSpecialQuotes(String(SettingParts[1]))
            let RawFieldIndex = String(SettingParts[0])
            if let FieldIndex = Int(RawFieldIndex)
            {
                if let Field = FilterManager.InputFields(rawValue: FieldIndex)
                {
                    let InputType = FilterManager.FieldTypeForInputField(Field)!
                    let AnyValue = ParameterManager.ConvertToAny(RawData, FromType: InputType)
                    NewBlob.AddSetting(Field, AnyValue)
                }
            }
        }
        return NewBlob
    }
}
