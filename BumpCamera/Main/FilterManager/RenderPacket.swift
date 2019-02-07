//
//  RenderPacket.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Contains information on how filters should render images.
class RenderPacket
{
    static let _Settings = UserDefaults.standard
    
    /// Initializer.
    ///
    /// - Parameter ID: ID of the filter.
    init(ID: UUID)
    {
        Reset()
        _FilterID = ID
    }
    
    /// Reset all properties (except for the FilterID property) to default values (nil).
    func Reset()
    {
        _Center = nil
        _Angle = nil
        _Width = nil
        _MergeWithBackground = nil
        _AdjustIfInLandscape = nil
        _EdgeIntensity = nil
        _InputThreshold = nil
        _InputContrast = nil
    }
    
    private var _FilterID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    /// Get or set the ID of the filter packet. Matches the ID of the filter itself.
    public var FilterID: UUID
    {
        get
        {
            return _FilterID
        }
        set
        {
            _FilterID = newValue
        }
    }
    
    private var _Center: CGPoint? = nil
    /// If present, the center of the rendering intent. Semantics are filter dependent.
    public var Center: CGPoint?
    {
        get
        {
            return _Center
        }
        set
        {
            _Center = newValue
        }
    }
    
    private var _Angle: Double? = nil
    /// If present, the angle at which to render. Semantics are filter dependent.
    public var Angle: Double?
    {
        get
        {
            return _Angle
        }
        set
        {
            _Angle = newValue
        }
    }
    
    private var _Width: Double? = nil
    /// If present the width of the rendering. Semantics are filter dependent.
    public var Width: Double?
    {
        get
        {
            return _Width
        }
        set
        {
            _Width = newValue
        }
    }
    
    private var _MergeWithBackground: Bool? = nil
    /// If present, the flag that indicates the result of the filter should be merged with the original image.
    public var MergeWithBackground: Bool?
    {
        get
        {
            return _MergeWithBackground
        }
        set
        {
            _MergeWithBackground = newValue
        }
    }
    
    private var _AdjustIfInLandscape: Bool? = nil
    /// If present, the flag that indicates certain angle adjustments (always in radians) are needed if the devices is in
    /// landscape mode.
    public var AdjustIfInLandscape: Bool?
    {
        get
        {
            return _AdjustIfInLandscape
        }
        set
        {
            _AdjustIfInLandscape = newValue
        }
    }
    
    private var _EdgeIntensity: Double? = nil
    /// Get or set the edge intensity for those filters that use it.
    public var EdgeIntensity: Double?
    {
        get
        {
            return _EdgeIntensity
        }
        set
        {
            _EdgeIntensity = newValue
        }
    }
    
    private var _InputThreshold: Double? = nil
    /// Get or set the input threshold for those filters that use it.
    public var InputThreshold: Double?
    {
        get
        {
            return _InputThreshold
        }
        set
        {
            _InputThreshold = newValue
        }
    }
    
    private var _InputContrast: Double? = nil
    /// Get or set the input contrast for those filters that use it.
    public var InputContrast: Double?
    {
        get
        {
            return _InputContrast
        }
        set
        {
            _InputContrast = newValue
        }
    }
    
    private var _SupportedTypes = [FilterManager.InputFields]() 
    /// Get the list of supported input types.
    public var SupportedFields: [FilterManager.InputFields]
    {
        get
        {
            return _SupportedTypes
        }
        set
        {
            _SupportedTypes = newValue
        }
    }
    
    /// Given an input field descriptor, return the current value of the input field. If no value has
    /// been set, return nil. (Nil will be returned even if the input field is supported as long as there
    /// is no value.)
    ///
    /// - Parameter IType: Determines the input field to return.
    /// - Returns: Value of the input field cast to Any?
    public func GetValueFor(_ IType: FilterManager.InputFields) -> Any?
    {
        switch IType
        {
        case .AdjustInLandscape:
            if let AdjustForLandscape = AdjustIfInLandscape
            {
                return AdjustForLandscape as Any
            }
            return nil
            
        case .Angle:
            if let Angle = Angle
            {
                return Angle as Any
            }
            return nil
            
        case .Center:
            if let Center = Center
            {
                return Center as Any
            }
            return nil
            
        case .EdgeIntensity:
            if let EdgeIntensity = EdgeIntensity
            {
                return EdgeIntensity as Any
            }
            return nil
            
        case .InputContrast:
            if let InputContrast = InputContrast
            {
                return InputContrast as Any
            }
            return nil
            
        case .InputThreshold:
            if let InputThreshold = InputThreshold
            {
                return InputThreshold as Any
            }
            return nil
            
        case .MergeWithBackground:
            if let DoMerge = MergeWithBackground
            {
                return DoMerge as Any
            }
            return nil
            
        case .Width:
            if let Width = Width
            {
                return Width as Any
            }
            return nil
            
        default:
            return nil
        }
    }
    
    /// Given an input field descriptor set the value to the passed value.
    ///
    /// - Parameter IType: Determines the input field to set.
    /// - Parameter To: The value to set the field to.
    public func SetValueFor(_ IType: FilterManager.InputFields, To: Any?)
    {
        switch IType
        {
        case .AdjustInLandscape:
            if To == nil
            {
                AdjustIfInLandscape = nil
                return
            }
            else
            {
                AdjustIfInLandscape = (To as! Bool)
            }
            
        case .Angle:
            if To == nil
            {
                Angle = nil
                return
            }
            else
            {
                Angle = (To as! Double)
            }
            
        case .Center:
            if To == nil
            {
                Center = nil
                return
            }
            else
            {
                Center = (To as! CGPoint)
            }
            
        case .EdgeIntensity:
            if To == nil
            {
                EdgeIntensity = nil
                return
            }
            else
            {
                EdgeIntensity = (To as! Double)
            }
            
        case .InputContrast:
            if To == nil
            {
                InputContrast = nil
                return
            }
            else
            {
                InputContrast = (To as! Double)
            }
            
        case .InputThreshold:
            if To == nil
            {
                InputThreshold = nil
                return
            }
            else
            {
                InputThreshold = (To as! Double)
            }
            
        case .MergeWithBackground:
            if To == nil
            {
                MergeWithBackground = nil
                return
            }
            else
            {
                MergeWithBackground = (To as! Bool)
            }
            
        case .Width:
            if To == nil
            {
                Width = nil
                return
            }
            else
            {
                Width = (To as! Double)
            }
            
        default:
            break
        }
    }
    
    /// Decode an encoded string and return a render packet with the decoded information. Encoded format is:
    ///
    ///     Supported="<comma-separated list of integers representing valid input fields>"
    ///     <integer represeting an input field>=raw value (points are comma-separated)
    ///
    /// Strings must be encoded in the format shown above.
    /// - Parameters:
    ///   - ID: ID of the render packet that ties it to its associated filter.
    ///   - Raw: Encoded render packet information. If Raw is empty, an empty packet is returned.
    /// - Returns: New render packet with decoded information.
    public static func Decode(ID: UUID, _ Raw: String) -> RenderPacket
    {
        let Packet = RenderPacket(ID: ID)
        if Raw.isEmpty
        {
            return Packet
        }
        var Lines = [String]()
        Raw.enumerateLines{line, _ in Lines.append(line)}
        
        let FirstLine = Lines.first
        let LineParts = FirstLine?.split(separator: "=")
        let SInParts = String(LineParts![1]).split(separator: ",")
        for SNum in SInParts
        {
            let StrNum = String(SNum)
            if let Num = Int(StrNum)
            {
                let ENum = FilterManager.InputFields(rawValue: Num)
                Packet.SupportedFields.append(ENum!)
            }
            else
            {
                fatalError("Error parsing supported fields.")
            }
        }
        Lines.removeFirst()
        
        for Line in Lines
        {
            let LineParts = Line.split(separator: "=")
            let FieldIDString = String(LineParts[0])
            let RawValue = String(LineParts[1])
            guard let FieldID = Int(FieldIDString) else
            {
                fatalError("Error converting field ID.")
            }
            guard let TheField = FilterManager.InputFields(rawValue: FieldID) else
            {
                fatalError("Error converting FieldID to actual enum.")
            }
            let FieldType = FilterManager.FieldMap[TheField]
            switch FieldType!
            {
            case .DoubleType:
                guard let DVal = Double(RawValue) else
                {
                    fatalError("Error parsing double value.")
                }
                Packet.SetValueFor(TheField, To: DVal as Any?)
                
            case .IntType:
                guard let IVal = Int(RawValue) else
                {
                    fatalError("Error parsing int value.")
                }
                Packet.SetValueFor(TheField, To: IVal as Any?)
                
            case .BoolType:
                guard let BVal = Bool(RawValue) else
                {
                    fatalError("Error parsing bool value.")
                }
                Packet.SetValueFor(TheField, To: BVal as Any?)
                
            case .PointType:
                let Coords = RawValue.split(separator: ",")
                if Coords.count != 2
                {
                    fatalError("Badly formed coordinate.")
                }
                var XS = String(Coords[0])
                XS = XS.replacingOccurrences(of: "(", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                var YS = String(Coords[1])
                YS = YS.replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard let X = Double(XS) else
                {
                    fatalError("Error parsing X double value.")
                }
                guard let Y = Double(YS) else
                {
                    fatalError("Error parsing Y double value.")
                }
                let NewPoint = CGPoint(x: CGFloat(X), y: CGFloat(Y))
                Packet.SetValueFor(TheField, To: NewPoint as Any?)
                
            default:
                fatalError("Invalid field type encountered.")
            }
        }
        return Packet
    }
    
    public static func Encode(_ Packet: RenderPacket) -> String?
    {
        var Final = ""
        
        if Packet.SupportedFields.count < 1
        {
            return nil
        }
        var Supported = "Supported="
        for InType in Packet.SupportedFields
        {
            let RawType = InType.rawValue
            let RawString = "\(RawType),"
            Supported = Supported + RawString
        }
        Supported = Supported + "\n"
        Final = Supported
        
        for InType in Packet.SupportedFields
        {
            let Anything = Packet.GetValueFor(InType)
            let AnyType = FilterManager.FieldMap[InType]
            var FinalValueString = ""
            if Anything != nil
            {
                switch AnyType!
                {
                case .DoubleType:
                    let DVal = Anything as! Double
                    FinalValueString = "\(DVal)"
                    
                case .IntType:
                    let IVal = Anything as! Int
                    FinalValueString = "\(IVal)"
                    
                case .BoolType:
                    let BVal = Anything as! Bool
                    FinalValueString = "\(BVal)"
                    
                case .PointType:
                    let PVal = Anything as! CGPoint
                    FinalValueString = "\(PVal)"
                    
                default:
                    fatalError("Invalid type encountered.")
                }
            }
            let Line = "\(InType.rawValue)=\(FinalValueString)" + "\n"
            Final = Final + Line
        }
        
        return Final
    }
    
    /// Save the passed packet into the user's settings. The packed is encoded into a single string first.
    ///
    /// - Parameter Packet: The packet to save.
    public static func Save(_ Packet: RenderPacket)
    {
        let Raw = Encode(Packet)
        let IDS = Packet.FilterID.uuidString
        _Settings.set(Raw, forKey: IDS)
    }
    
    /// Get the parameter packet for the specified ID.
    ///
    /// - Parameter ID: ID of the packet to return.
    /// - Returns: The specified parameter packet on success, nil on error.
    public static func Read(_ ID: UUID) -> RenderPacket?
    {
        let IDS = ID.uuidString
        let Raw = _Settings.string(forKey: IDS)
        if Raw == nil || (Raw?.isEmpty)!
        {
            print("Could not read \(IDS)")
            return nil
        }
        let Packet = Decode(ID: ID, Raw!)
        return Packet
    }
    #if false
    enum InputFields: Int
    {
        case InputThreshold = 0
        case InputContrast = 1
        case EdgeIntensity = 2
        case Center = 3
        case Width = 4
        case Angle = 5
        case MergeWithBackground = 6
        case AdjustInLandscape = 7
    }
    
    enum InputTypes: Int
    {
        case DoubleType = 0
        case IntType = 1
        case BoolType = 2
        case PointType = 3
        case NoType = 1000
    }
    
    public static let FieldMap: [InputFields: InputTypes] =
        [
            .InputThreshold: .DoubleType,
            .InputContrast: .DoubleType,
            .EdgeIntensity: .DoubleType,
            .Center: .PointType,
            .Width: .DoubleType,
            .Angle: .DoubleType,
            .MergeWithBackground: .BoolType,
            .AdjustInLandscape: .BoolType
    ]
    
    public static let FieldStorageMap: [InputFields: String] =
    [
        .InputThreshold: "_InputThreshold",
        .InputContrast: "_InputContrast",
        .EdgeIntensity: "_EdgeIntensity",
        .Center: "_Center",
        .Width: "_Width",
        .Angle: "_Angle",
        .MergeWithBackground: "_MergeWithBackground",
        .AdjustInLandscape: "_AdjustInLandscape"
    ]
    #endif
    
    /// Given a field type, return its data type.
    ///
    /// - Parameter For: The input field whose data type will be returned.
    /// - Returns: The data type for the specified field on success, fatal error on error.
    public static func GetInputFieldType(For: FilterManager.InputFields) -> FilterManager.InputTypes
    {
        if let TheType = FilterManager.FieldMap[For]
        {
            return TheType
        }
        fatalError("Unexpected field type encountered.")
    }
}
