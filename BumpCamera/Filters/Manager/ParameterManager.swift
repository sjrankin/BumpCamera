//
//  ParameterManager.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Manages parameter values for the various filters.
class ParameterManager
{
    static let _Settings = UserDefaults.standard
    
    /// Initialize the parameter manager. Not strictly required to be called.
    ///
    /// - Parameters:
    ///   - Filters: The filter manager.
    ///   - Preload: If true, preload all filter values into the internal cache.
    public static func Initialize(Filters: FilterManager, Preload: Bool = true)
    {
        if Preload
        {
            PreloadCache(From: Filters)
        }
    }
    
    /// Preload the internal cache with all implemented filters' parameters.
    ///
    /// - Parameter Manager: The filter manager.
    private static func PreloadCache(From Manager: FilterManager)
    {
        for Filter in Manager.ImplementedFilters()
        {
            let FilterID = Manager.GetFilterID(For: Filter)
            let CameraFilterInstance = Manager.GetFilter(Name: Filter, FilterManager.FilterLocations.Photo)
            let FilterInstance = CameraFilterInstance?.Filter
            for Field in (FilterInstance?.SupportedFields())!
            {
                let (_, _) = GetFieldData(From: FilterID!, Field: Field)
            }
        }
    }
    
    /// Create initial storage in user settings. Should be called only after first run after installation. Subsequent calls will
    /// overwrite any changes made by the user.
    ///
    /// - Parameters:
    ///   - Filters: The filter manager.
    ///   - ImplementedFilters: List of filters to create.
    public static func CreateInitialStorage(Filters: FilterManager, ImplementedFilters: [FilterManager.FilterTypes])
    {
        for Filter in ImplementedFilters
        {
            StoreInitialFilterFor(Filter, From: Filters)
        }
    }
    
    /// Creates the structure to store filter parameter values for the passed filter type.
    ///
    /// - Parameters:
    ///   - Filter: The type of filter to create the structure for.
    ///   - From: The filter manager.
    private static func StoreInitialFilterFor(_ Filter: FilterManager.FilterTypes, From: FilterManager)
    {
        let ID: UUID = From.GetFilterID(For: Filter)!
        let CameraFilterInstance = From.GetFilter(Name: Filter, FilterManager.FilterLocations.Photo)
        let FilterInstance = CameraFilterInstance?.Filter
        if (FilterInstance?.SupportedFields().count)! < 1
        {
            return
        }
        //print("Creating storage for ID: \(ID.uuidString): \(From.GetFilterTitle(Filter)).")
        for Field in (FilterInstance?.SupportedFields())!
        {
            let (FieldType, AnyValue) = (FilterInstance?.DefaultFieldValue(Field: Field))!
            let StorageName = MakeStorageName(For: ID, Field: Field)
            var StoredData = ""
            switch FieldType
            {
            case FilterManager.InputTypes.BoolType:
                if let DefaultValue = AnyValue
                {
                    let BVal = DefaultValue as! Bool
                    StoredData = String(BVal)
                }
                
            case FilterManager.InputTypes.DoubleType:
                if let DefaultValue = AnyValue
                {
                    let DVal = DefaultValue as! Double
                    StoredData = String(DVal)
                }
                
            case FilterManager.InputTypes.IntType:
                if let DefaultValue = AnyValue
                {
                    let IVal = DefaultValue as! Int
                    StoredData = String(IVal)
                }
                
            case FilterManager.InputTypes.PointType:
                if let DefaultValue = AnyValue
                {
                    let PVal = DefaultValue as! CGPoint
                    let PValX = PVal.x
                    let PValY = PVal.y
                    StoredData = "\(PValX),\(PValY)"
                }
                
            default:
                fatalError("Unexpected field type \(FieldType) encountered in StoreInitialFilterFor.")
            }
            //print("  Creating field: \(Field) of type \(FieldType) and default value \(StoredData)")
            _Settings.set(StoredData, forKey: StorageName)
        }
    }
    
    /// Create a unique name for storing parameter information in user defaults.
    ///
    /// - Parameters:
    ///   - For: The ID of the filter.
    ///   - Field: The name of the field to create.
    /// - Returns: String in the form: ID_InputFieldName.
    private static func MakeStorageName(For: UUID, Field: FilterManager.InputFields) -> String
    {
        let Prefix = For.uuidString
        guard let Suffix = FilterManager.FieldStorageMap[Field] else
        {
            fatalError("Cannot find storage name for \(Field)")
        }
        if Suffix.isEmpty
        {
            fatalError("No valid suffix returned.")
        }
        return Prefix + Suffix
    }
    
    /// Determines if the filter with the passed ID has data in user settings for the specified field type.
    ///
    /// - Parameters:
    ///   - In: The ID of the filter.
    ///   - Field: The type of input field to verify.
    /// - Returns: True if the ID/filter combination exists, false if not.
    public static func HasField(In: UUID, Field: FilterManager.InputFields) -> Bool
    {
        let FieldName = MakeStorageName(For: In, Field: Field)
        return _Settings.string(forKey: FieldName) != nil
    }
    
    /// Clear the field cache.
    public static func ClearCache()
    {
        objc_sync_enter(CacheLock)
        defer{objc_sync_exit(CacheLock)}
        FieldCache.removeAll()
    }
    
    /// Field cache. Data is added here as it is read or written. Data in this cache is assumed to always be coherent.
    static var FieldCache = [String: (FilterManager.InputTypes, Any?)]()
    
    static var CacheLock = NSObject()
    
    /// Get field information for the filter/field type passed.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter.
    ///   - Field: The type of input field.
    /// - Returns: Tuple in the form (input type, data) where input type is one of FilterManager.InputTypes and data is
    ///            of type Any?. On error, the input type will be .NoType. If the data is nil but the input type is
    ///            valid, that just means the user hasn't set a value for the given field.
    public static func GetFieldData(From: UUID, Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    {
        objc_sync_enter(CacheLock)
        defer{objc_sync_exit(CacheLock)}
        if !HasField(In: From, Field: Field)
        {
            return (FilterManager.InputTypes.NoType, nil)
        }
        guard let ExpectedType = FilterManager.FieldMap[Field] else
        {
            fatalError("Specified field has no associated type.")
        }
        let StorageName = MakeStorageName(For: From, Field: Field)
        let RawValue = _Settings.string(forKey: StorageName)
        let AnyValue = ConvertToAny(RawValue!, FromType: ExpectedType)
        FieldCache[StorageName] = (ExpectedType, AnyValue)
        return (ExpectedType, AnyValue)
    }
    
    /// Get field information for the filter/field type passed.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter.
    ///   - Field: The type of input field.
    /// - Returns: The value of the field cast to Any?
    public static func GetField(From: UUID, Field: FilterManager.InputFields) -> Any?
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        return FieldData.1
    }
    
    /// Converted the passed string into type Any? Values are converted to their specified types then cast to Any? when returned.
    ///
    /// - Parameters:
    ///   - Raw: The raw data to convert.
    ///   - FromType: Determines the target type.
    /// - Returns: The converted value cast to Any?
    private static func ConvertToAny(_ Raw: String, FromType: FilterManager.InputTypes) -> Any?
    {
        if Raw.isEmpty
        {
            return "" as Any?
        }
        switch FromType
        {
        case .BoolType:
            if let BVal = Bool(Raw)
            {
                return BVal as Any?
            }
            return "" as Any?
            
        case .DoubleType:
            if let DVal = Double(Raw)
            {
                return DVal as Any?
            }
            return "" as Any?
            
        case .IntType:
            if let IVal = Int(Raw)
            {
                return IVal as Any?
            }
            return "" as Any?
            
        case .PointType:
            let Parts = Raw.split(separator: ",")
            if Parts.count != 2
            {
                fatalError("Badly formatted point encountered.")
            }
            let XS = String(Parts[0])
            let YS = String(Parts[1])
            var FinalX: CGFloat = 0.0
            if let X = Double(XS)
            {
                FinalX = CGFloat(X)
            }
            else
            {
                print("Bad X in point.")
                return "" as Any?
            }
            var FinalY: CGFloat = 0.0
            if let Y = Double(YS)
            {
                FinalY = CGFloat(Y)
            }
            else
            {
                return "" as Any?
            }
            return CGPoint(x: FinalX, y: FinalY) as Any?
            
        default:
            fatalError("Invalid type encountered in ConvertToAny")
        }
    }
    
    /// Set the value of a field for the specified filter.
    ///
    /// - Parameters:
    ///   - To: The ID of the filter.
    ///   - Field: The field type to set.
    ///   - Value: The value to save.
    public static func SetField(To: UUID, Field: FilterManager.InputFields, Value: Any?)
    {
        objc_sync_enter(CacheLock)
        defer{objc_sync_exit(CacheLock)}
        let StorageName = MakeStorageName(For: To, Field: Field)
        guard let ExpectedType = FilterManager.FieldMap[Field] else
        {
            fatalError("Specified field has no associated type.")
        }
        let FinalValue = ConvertAny(Value, OfType: ExpectedType)
        _Settings.set(FinalValue, forKey: StorageName)
        FieldCache[StorageName] = (ExpectedType, Value)
    }
    
    private static func ConvertAny(_ Raw: Any?, OfType: FilterManager.InputTypes) -> String
    {
        if Raw == nil
        {
            return ""
        }
        switch OfType
        {
        case .BoolType:
            if let BVal = Raw as? Bool
            {
                return String(BVal)
            }
            return ""
            
        case .DoubleType:
            if let DVal = Raw as? Double
            {
                return String(DVal)
            }
            return ""
            
        case .IntType:
            if let IVal = Raw as? Int
            {
                return String(IVal)
            }
            
        case .PointType:
            if let Point = Raw as? CGPoint
            {
                let X = Point.x
                let Y = Point.y
                return "\(X),\(Y)"
            }
            return ""
            
        default:
            fatalError("Unexpected type \(OfType) encountered.")
        }
        
        return ""
    }
}
