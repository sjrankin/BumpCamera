//
//  ParameterManager.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import simd

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
    /// - Returns: Tuple in the form (input type, actual value, storage name of the value) where input type is one of
    ///            FilterManager.InputTypes and data is of type Any?. On error, the input type will be .NoType. If the data is
    ///            nil but the input type is valid, that just means the user hasn't set a value for the given field.
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
    
    public static func GetFieldData(Blob: FilterSettingsBlob, Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    {
        if !Blob.HasSetting(Field)
        {
            return (FilterManager.InputTypes.NoType, nil)
        }
        guard let ExpectedType = FilterManager.FieldMap[Field] else
        {
            fatalError("Specified field has no associated type.")
        }
        return (ExpectedType, Blob.GetSetting(Field))
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
    
    /// Convert a string representation of a color ("double,double,double,double") into an
    /// equivalent color.
    ///
    /// - Parameter Raw: String representation of a color in the form double,double,double,double where the value of
    ///                  each double is in the range 0.0 to 1.0. Values are clamped internally.
    /// - Returns: UIColor created from the string representation of the color.
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
            if var DVal = Double(SPart)
            {
                DVal = DVal.Clamp(0.0, 1.0)
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
    
    /// Return a color stored in user settings.
    ///
    /// - Note: This function generate a fatal error if the specified field is not found or the data cannot be converted
    ///         into a color.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the color is stored.
    ///   - Field: The input field associated with the color value.
    ///   - Default: Default color value.
    /// - Returns: Value of the color stored in user settings on success, default color on failure.
    public static func GetColor(From: UUID, Field: FilterManager.InputFields, Default: UIColor) -> UIColor
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if let CVal = FieldData.1 as? UIColor
        {
            return CVal
        }
        return Default
    }
    
    public static func GetColor(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: UIColor) -> UIColor
    {
        let FieldData = GetFieldData(Blob: Blob, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in FilterSettingsBlob.")
        }
        if let CVal = FieldData.1 as? UIColor
        {
            return CVal
        }
        return Default
    }
    
    /// Return a color stored in user settings. The color is converted to simd_float4 before being returned.
    ///
    /// - Note: Calls GetColor which may generate a fatal error on bad data.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the color is stored.
    ///   - Field: The input field associated with the color value.
    ///   - Default: Default color value.
    /// - Returns: Value of the color stored in user settings on success in a simd_float4 structure, default color on failure.
    public static func GetFloat4(From: UUID, Field: FilterManager.InputFields, Default: UIColor) -> simd_float4
    {
        let Color = GetColor(From: From, Field: Field, Default: Default)
        return Color.ToFloat4()
    }
    
    public static func GetFloat4(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: UIColor) -> simd_float4
    {
        let Color = GetColor(Blob: Blob, Field: Field, Default: Default)
        return Color.ToFloat4()
    }
    
    /// Return a double value stored in user settings.
    ///
    /// - Note: This function generate a fatal error if the specified field is not found or the data cannot be converted
    ///         into a double.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the double is stored.
    ///   - Field: The input field associated with the double value.
    ///   - Default: Default double value.
    /// - Returns: Value of the double stored in user settings on success, default value on failure.
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
        return Default
    }
    
    public static func GetDouble(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: Double) -> Double
    {
        let FieldData = GetFieldData(Blob: Blob, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in FilterSettingsBlob.")
        }
        if let DVal = FieldData.1 as? Double
        {
            return DVal
        }
        return Default
    }
    
    /// Return a double value stored in user settings. Value is converted into a simd_float1 before being returned.
    ///
    /// - Note: This function calls GetDouble which may generate a fatal error on bad data.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the value is stored.
    ///   - Field: The input field associated with the value.
    ///   - Default: Default value.
    /// - Returns: Value of the double stored in user settings on success and converted to a simd_float1, default double on failure.
    public static func GetFloat1(From: UUID, Field: FilterManager.InputFields, Default: Double) -> simd_float1
    {
        return simd_float1(GetDouble(From: From, Field: Field, Default: Default))
    }
    
    public static func GetFloat1(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: Double) -> simd_float1
    {
        return simd_float1(GetDouble(Blob: Blob, Field: Field, Default: Default))
    }
    
    /// Return an integer stored in user settings.
    ///
    /// - Note: This function generate a fatal error if the specified field is not found or the data cannot be converted
    ///         into an integer.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the integer is stored.
    ///   - Field: The input field associated with the integer value.
    ///   - Default: Default integer value.
    /// - Returns: Value of the integer stored in user settings on success, default integer on failure.
    public static func GetInt(From: UUID, Field: FilterManager.InputFields, Default: Int) -> Int
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            let FromType = FilterManager.GetFilterTypeFrom(ID: From)
            let FromTitle = FilterManager.GetFilterTitle(FromType!)
            fatalError("No data found for \(Field) in \(FromTitle!).")
        }
        if let IVal = FieldData.1 as? Int
        {
            return IVal
        }
        return Default
    }
    
    public static func GetInt(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: Int) -> Int
    {
        let FieldData = GetFieldData(Blob: Blob, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in FilterSettingsBlob.")
        }
        if let IVal = FieldData.1 as? Int
        {
            return IVal
        }
        return Default
    }
    
    /// Return an integer stored in user settings as a simd_uint1 value.
    ///
    /// - Note: This function calls GetInt which may generate a fatal error on bad data.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the integer is stored.
    ///   - Field: The input field associated with the integer value.
    ///   - Default: Default integer value.
    /// - Returns: Value of the integer stored in user settings on success cast as a simd_uint1, default color on failure.
    public static func GetUInt1(From: UUID, Field: FilterManager.InputFields, Default: Int) -> simd_uint1
    {
        return simd_uint1(GetInt(From: From, Field: Field, Default: Default))
    }
    
    public static func GetUInt1(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: Int) -> simd_uint1
    {
        return simd_uint1(GetInt(Blob: Blob, Field: Field, Default: Default))
    }
    
    /// Return a boolean value stored in user settings.
    ///
    /// - Note: This function generate a fatal error if the specified field is not found or the data cannot be converted
    ///         into a boolean value.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the boolean is stored.
    ///   - Field: The input field associated with the boolean value.
    ///   - Default: Default boolean value.
    /// - Returns: Value of the boolean stored in user settings on success, default boolean value on failure.
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
        return Default
    }
    
    public static func GetBool(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: Bool) -> Bool
    {
        let FieldData = GetFieldData(Blob: Blob, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in FilterSettingsBlob.")
        }
        if let BVal = FieldData.1 as? Bool
        {
            return BVal
        }
        return Default
    }
    
    /// Return a boolean stored in user settings cast as a simd_bool.
    ///
    /// - Note: This function calls GetBool which may cause a fatal error if the data cannot be read.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the boolean is stored.
    ///   - Field: The input field associated with the boolean value.
    ///   - Default: Default boolean value.
    /// - Returns: Value of the boolean stored in user settings on success converted to simd_bool, default boolean on failure.
    public static func GetSimdBool(From: UUID, Field: FilterManager.InputFields, Default: Bool) -> simd_bool
    {
        return simd_bool(GetBool(From: From, Field: Field, Default: Default))
    }
    
    public static func GetSimdBool(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: Bool) -> simd_bool
    {
        return simd_bool(GetBool(Blob: Blob, Field: Field, Default: Default))
    }
    
    /// Return a string stored in user settings.
    ///
    /// - Note: This function generate a fatal error if the specified field is not found or the data cannot be converted
    ///         into a string.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the string is stored.
    ///   - Field: The input field associated with the string value.
    ///   - Default: Default string value.
    /// - Returns: The string stored in user settings on success, default string value on failure.
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
        return Default
    }
    
    public static func GetString(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: String) -> String
    {
        let FieldData = GetFieldData(Blob: Blob, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in FilterSettingsBlob.")
        }
        if let SVal = FieldData.1 as? String
        {
            return SVal
        }
        return Default
    }
    
    /// Return a normal stored in user settings as a double value. Value is clamped to 0.0 to 1.0 before being returned.
    ///
    /// - Note: This function generate a fatal error if the specified field is not found or the data cannot be converted
    ///         into a double.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the normal is stored.
    ///   - Field: The input field associated with the normal value.
    ///   - Default: Default normal value. If returned, clamped first to 0.0 to 1.0.
    /// - Returns: Value of the normal stored in user settings on success, default normal on failure.
    public static func GetNormal(From: UUID, Field: FilterManager.InputFields, Default: Double) -> Double
    {
        let FieldData = GetFieldData(From: From, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in \(From).")
        }
        if var NVal = FieldData.1 as? Double
        {
            NVal = NVal.Clamp(0.0, 1.0)
            return NVal
        }
        return Default.Clamp(0.0, 1.0)
    }
    
    public static func GetNormal(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: Double) -> Double
    {
        let FieldData = GetFieldData(Blob: Blob, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in FilterSettingsBlob.")
        }
        if var NVal = FieldData.1 as? Double
        {
            NVal = NVal.Clamp(0.0, 1.0)
            return NVal
        }
        return Default.Clamp(0.0, 1.0)
    }
    
    /// Return a CGPoint stored in user settings.
    ///
    /// - Note: This function generate a fatal error if the specified field is not found or the data cannot be converted
    ///         into a CGPoint.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the point is stored.
    ///   - Field: The input field associated with the point value.
    ///   - Default: Default point value.
    /// - Returns: Value of the point stored in user settings on success, default point on failure.
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
        return Default
    }
    
    public static func GetPoint(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: CGPoint) -> CGPoint
    {
        if !Blob.HasSetting(Field)
        {
            return Default
        }
        let FieldData = GetFieldData(Blob: Blob, Field: Field)
        if FieldData.0 == .NoType
        {
            fatalError("No data found for \(Field) in passed FilterSettingsBlob.")
        }
        if let PVal = FieldData.1 as? CGPoint
        {
            return PVal
        }
        return Default
    }
    
    /// Return a CIVector stored in user settings.
    ///
    /// - Note: This function generate a fatal error if the specified field is not found or the data cannot be converted
    ///         into a CGPoint. This function calls GetPoint and converts the point to a vector so the fatal error may
    ///         occur there.
    ///
    /// - Parameters:
    ///   - From: The ID of the filter where the vector is stored.
    ///   - Field: The input field associated with the vector value.
    ///   - Default: Default vector value.
    /// - Returns: Value of the vector stored in user settings on success, default vector on failure.
    public static func GetVector(From: UUID, Field: FilterManager.InputFields, Default: CIVector) -> CIVector
    {
        let Point = GetPoint(From: From, Field: Field, Default: CGPoint(x: 0, y: 0))
        return CIVector(x: Point.x, y: Point.y)
    }
    
    public static func GetVector(Blob: FilterSettingsBlob, Field: FilterManager.InputFields, Default: CIVector) -> CIVector
    {
        if !Blob.HasSetting(Field)
        {
            return Default
        }
        let Point = GetPoint(Blob: Blob, Field: Field, Default: CGPoint(x: 0, y: 0))
        return CIVector(x: Point.x, y: Point.y)
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
    
    /// Lock for updating render accumulation values.
    static let RenderUpdateLock0 = NSObject()
    
    /// Update rendering accumulator totals for a given filter. The rendering count is updated
    /// here as well.
    ///
    /// - Parameters:
    ///   - NewValue: New rendering value to accumulate.
    ///   - ID: ID of the filter updating the accumulator.
    ///   - ForImage: If true, the value is for rendering an image. If false, for rendering a live view.
    public static func UpdateRenderAccumulator(NewValue: Double, ID: UUID, ForImage: Bool)
    {
        objc_sync_enter(RenderUpdateLock0)
        defer{objc_sync_exit(RenderUpdateLock0)}
        if !_Settings.bool(forKey: "CollectPerformanceStatistics")
        {
            return
        }
        let CountField = ForImage ? FilterManager.InputFields.RenderImageCount : .RenderLiveCount
        let ValueField = ForImage ? FilterManager.InputFields.CumulativeImageRenderDuration : .CumulativeLiveRenderDuration
        let CountName = MakeStorageName(For: ID, Field: CountField)
        let ValueName = MakeStorageName(For: ID, Field: ValueField)
        var Count = _Settings.integer(forKey: CountName)
        Count = Count + 1
        _Settings.set(Count, forKey: CountName)
        var Value = _Settings.double(forKey: ValueName)
        Value = Value + NewValue
        _Settings.set(Value, forKey: ValueName)
    }
    
    /// Lock for updating render accumulation values.
    static let RenderUpdateLock1 = NSObject()
    
    /// Reset the filter render accumulation instances and durations.
    ///
    /// - Parameters:
    ///   - ID: ID of the filter whose accumulation statistics will be reset.
    ///   - ForImage: If true, the image rendering statistics will be reset. If false, the live rendering statistics will be reset.
    public static func ResetRenderAccumulator(ID: UUID, ForImage: Bool)
    {
        objc_sync_enter(RenderUpdateLock1)
        defer{objc_sync_exit(RenderUpdateLock1)}
        if !_Settings.bool(forKey: "CollectPerformanceStatistics")
        {
            return
        }
        let CountField = ForImage ? FilterManager.InputFields.RenderImageCount : .RenderLiveCount
        let ValueField = ForImage ? FilterManager.InputFields.CumulativeImageRenderDuration : .CumulativeLiveRenderDuration
        let CountName = MakeStorageName(For: ID, Field: CountField)
        let ValueName = MakeStorageName(For: ID, Field: ValueField)
        _Settings.set(0, forKey: CountName)
        _Settings.set(0.0, forKey: ValueName)
    }
    
    /// Return rendering statistics for the specified filter and render type.
    ///
    /// - Parameters:
    ///   - ID: The filter for which rendering statistics will be returned.
    ///   - ForImage: The type of rendering for the filter (eg, image or live filtering).
    /// - Returns: Tuple in the order of: render instance count, cumulative render time (in seconds).
    public static func GetRenderStatistics(ID: UUID, ForImage: Bool) -> (Int, Double)?
    {
        objc_sync_enter(RenderUpdateLock1)
        defer{objc_sync_exit(RenderUpdateLock1)}
        
        let CountField = ForImage ? FilterManager.InputFields.RenderImageCount : .RenderLiveCount
        let ValueField = ForImage ? FilterManager.InputFields.CumulativeImageRenderDuration : .CumulativeLiveRenderDuration
        let CountName = MakeStorageName(For: ID, Field: CountField)
        let ValueName = MakeStorageName(For: ID, Field: ValueField)
        let Count = _Settings.integer(forKey: CountName)
        let Value = _Settings.double(forKey: ValueName)
        return (Count, Value)
    }
    
    /// Return all filter performace data.
    ///
    /// - Returns: List of performace data, each element a tuple of (filter type, image count, image total, live count
    ///            and live total).
    public static func DumpRenderData() -> [(FilterManager.FilterTypes, FilterManager.FilterKernelTypes, Int, Double, Int, Double)]
    {
        var Results = [(FilterManager.FilterTypes, FilterManager.FilterKernelTypes, Int, Double, Int, Double)]()
        for (FilterType, Info) in FilterManager.FilterInfoMap
        {
            let (ImageCount, ImageTotal) = GetRenderStatistics(ID: Info.0, ForImage: true)!
            let (LiveCount, LiveTotal) = GetRenderStatistics(ID: Info.0, ForImage: false)!
            Results.append((FilterType, Info.1, ImageCount, ImageTotal, LiveCount, LiveTotal))
        }
        return Results
    }
    
    /// Converts the value (type cast to Any) to the value specified in OfType and returns the
    /// result as a string, ready to save to user settings.
    ///
    /// - Parameters:
    ///   - Raw: The value to convert.
    ///   - OfType: The type of the value.
    /// - Returns: The converted value as a String.
    public static func ConvertAny(_ Raw: Any?, OfType: FilterManager.InputTypes) -> String
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

