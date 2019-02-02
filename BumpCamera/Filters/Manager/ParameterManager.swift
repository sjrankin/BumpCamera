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
        for Field in (FilterInstance?.SupportedFields())!
        {
            let (FieldType, AnyValue) = (FilterInstance?.DefaultFieldValue(Field: Field))!
            let StorageName = MakeStorageName(For: ID, Field: Field)
            var StoredData = ""
            switch FieldType
            {
            case .StringType:
                if let DefaultValue = AnyValue
                {
                    let SVal = DefaultValue as! String
                    StoredData = SVal
                }
                
            case .BoolType:
                if let DefaultValue = AnyValue
                {
                    let BVal = DefaultValue as! Bool
                    StoredData = String(BVal)
                }
                
            case .DoubleType:
                if let DefaultValue = AnyValue
                {
                    let DVal = DefaultValue as! Double
                    StoredData = String(DVal)
                }
                
            case .Normal:
                if let DefaultValue = AnyValue
                {
                    let NVal = (DefaultValue as! Double).Clamp(0.0, 1.0)
                    StoredData = String(NVal)
                }
                
            case .IntType:
                if let DefaultValue = AnyValue
                {
                    let IVal = DefaultValue as! Int
                    StoredData = String(IVal)
                }
                
            case .PointType:
                if let DefaultValue = AnyValue
                {
                    let PVal = DefaultValue as! CGPoint
                    let PValX = PVal.x
                    let PValY = PVal.y
                    StoredData = "\(PValX),\(PValY)"
                }
                
            case .ColorType:
                if let DefaultValue = AnyValue
                {
                    let CValue = DefaultValue as! UIColor
                    StoredData = ColorToString(CValue)
                }
                
            default:
                fatalError("Unexpected field type \(FieldType) encountered in StoreInitialFilterFor.")
            }
            //print("  Creating field: \(Field) of type \(FieldType) and default value \(StoredData)")
            _Settings.set(StoredData, forKey: StorageName)
        }
    }
    
    private static func ColorToString(_ Color: UIColor) -> String
    {
        var Red: CGFloat = 0.0
        var Green: CGFloat = 0.0
        var Blue: CGFloat = 0.0
        var Alpha: CGFloat = 0.0
        Color.getRed(&Red, green: &Green, blue: &Blue, alpha: &Alpha)
        return "\(Red),\(Green),\(Blue),\(Alpha)"
    }
    
    /// Create a unique name for storing parameter information in user defaults.
    ///
    /// - Parameters:
    ///   - For: The ID of the filter.
    ///   - Field: The name of the field to create.
    /// - Returns: String in the form: ID_InputFieldName.
    public static func MakeStorageName(For: UUID, Field: FilterManager.InputFields) -> String
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
    /// - Returns: Tuple in the form (input type, data) where input type is one of FilterManager.InputTypes and data is
    ///            of type Any?. On error, the input type will be .NoType. If the data is nil but the input type is
    ///            valid, that just means the user hasn't set a value for the given field.
    public static func GetFieldDataEx(From: UUID, Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?, String)
    {
        objc_sync_enter(CacheLock)
        defer{objc_sync_exit(CacheLock)}
        if !HasField(In: From, Field: Field)
        {
            return (FilterManager.InputTypes.NoType, nil, "")
        }
        guard let ExpectedType = FilterManager.FieldMap[Field] else
        {
            fatalError("Specified field has no associated type.")
        }
        let StorageName = MakeStorageName(For: From, Field: Field)
        let RawValue = _Settings.string(forKey: StorageName)
        let AnyValue = ConvertToAny(RawValue!, FromType: ExpectedType)
        FieldCache[StorageName] = (ExpectedType, AnyValue)
        return (ExpectedType, AnyValue, StorageName)
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
    
    private static func ConvertStringtoColor(_ Raw: String) -> UIColor
    {
            let Parts = Raw.split(separator: ",")
            if Parts.count != 4
            {
                fatalError("Raw color \"\(Raw)\" does not have four parts.")
            }
            var Values = [CGFloat]()
            for Part in Parts
            {
                let SPart = String(Part)
                if let DVal = Double(SPart)
                {
                    Values.append(CGFloat(DVal))
                }
                else
                {
                    fatalError("Error converting \"\(SPart)\" to number.")
                }
            }
            let Final = UIColor(red: Values[0], green: Values[1], blue: Values[2], alpha: Values[3])
            return Final
    }
    
    public static func GetColor(From: UUID, Field: FilterManager.InputFields, Default: UIColor) -> UIColor
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if let SVal = FieldData.1 as? String
        {
            return ConvertStringtoColor(SVal)
        }
        fatalError("Bad data found for \(Field) in \(From).")
    }
    
    public static func GetDouble(From: UUID, Field: FilterManager.InputFields, Default: Double) -> Double
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if let DVal = FieldData.1 as? Double
        {
            return DVal
        }
        fatalError("Bad data found for \(Field) in \(From).")
    }
    
    public static func GetInt(From: UUID, Field: FilterManager.InputFields, Default: Int) -> Int
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if let IVal = FieldData.1 as? Int
        {
            return IVal
        }
        fatalError("Bad data found for \(Field) in \(From).")
    }
    
    public static func GetBool(From: UUID, Field: FilterManager.InputFields, Default: Bool) -> Bool
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if let BVal = FieldData.1 as? Bool
        {
            return BVal
        }
        fatalError("Bad data found for \(Field) in \(From).")
    }
    
    public static func GetString(From: UUID, Field: FilterManager.InputFields, Default: String) -> String
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if let SVal = FieldData.1 as? String
        {
            return SVal
        }
        fatalError("Bad data found for \(Field) in \(From).")
    }
    
    public static func GetNormal(From: UUID, Field: FilterManager.InputFields, Default: Double) -> Double
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if let NVal = FieldData.1 as? Double
        {
            return NVal
        }
        fatalError("Bad data found for \(Field) in \(From).")
    }
    
    public static func GetPoint(From: UUID, Field: FilterManager.InputFields, Default: CGPoint) -> CGPoint
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if let PVal = FieldData.1 as? CGPoint
        {
            return PVal
        }
        fatalError("Bad data found for \(Field) in \(From).")
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
        case .StringType:
            return Raw as Any?
            
        case .ColorType:
            let RawColor = ConvertStringtoColor(Raw)
            return RawColor as Any?
            
        case .BoolType:
            if let BVal = Bool(Raw)
            {
                return BVal as Any?
            }
            return nil
            
        case .DoubleType:
            if let DVal = Double(Raw)
            {
                return DVal as Any?
            }
            return nil
            
        case .Normal:
            if let NVal = Double(Raw)
            {
                return NVal.Clamp(0.0, 1.0) as Any?
            }
            return nil
            
        case .IntType:
            if let IVal = Int(Raw)
            {
                return IVal as Any?
            }
            return nil
            
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
                return nil
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
        case .ColorType:
            if let CVal = Raw as? UIColor
            {
                return ColorToString(CVal)
            }
            return ""
            
        case .StringType:
            if let SVal = Raw as? String
            {
                return SVal
            }
            return ""
            
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
            
        case .Normal:
            if var Norm = Raw as? Double
            {
                Norm = Norm.Clamp(0.0, 1.0)
                return String(Norm)
            }
            return ""
            
        default:
            fatalError("Unexpected type \(OfType) encountered.")
        }
        
        return ""
    }
}

