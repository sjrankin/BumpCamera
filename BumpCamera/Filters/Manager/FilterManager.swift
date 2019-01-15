//
//  FilterManager.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Types of filters that can be run on live views and static images.
///
/// - PassThrough: Filter that does nothing.
/// - Noir: Noir (dramatic black and white) filter.
/// - LineScreen: Line screen - makes images look like old CRT images.
/// - CircularScreen: Circular screen.
/// - DotScreen: Dot screen.
/// - HatchScreen: Hatch screen.
/// - Pixellate: Pixellate.
/// - CircleAndLines: Combination of a line screen and a circular screen.
/// - CMYKHalftone: CMYK halftone filter.
/// - NotSet: Used to indicate no filter set.
enum FilterNames
{
    case PassThrough
    case Noir
    case LineScreen
    case CircularScreen
    case DotScreen
    case HatchScreen
    case Pixellate
    case CircleAndLines
    case CMYKHalftone
    case NotSet
}

/// Manages the set of filters for the camera and general image processing.
class FilterManager
{
    /// Set the current filter to the specified filter type. Returns the filter (which can also be accessed via
    /// the property CurrentFilter). If the filter hasn't been constructed yet, it will be constructed and added
    /// to the filter list before being returned.
    ///
    /// - Parameter Name: The type of filter to set as the current filter.
    /// - Returns: The new current filter (which may be a pre-existing one). Nil returned on error.
    public func SetCurrentFilter(Name: FilterNames) -> CameraFilter?
    {
        _CurrentFilter = GetFilter(Name: Name)
        return CurrentFilter
    }
    
    private var _CurrentFilter: CameraFilter?
    /// Get the current filter. If nil, either no current filter set (see SetCurrentFilter) or an error occurred.
    public var CurrentFilter: CameraFilter?
    {
        get
        {
            return _CurrentFilter
        }
    }
    
    /// Get the specified type of filter. If it does not yet exist, it will be constructed. If the filter is created, it will be
    /// placed in the filter list for reuse purposes.
    ///
    /// - Parameter Name: The type of filter to return.
    /// - Returns: The specified camera filter type on success, nil on error.
    public func GetFilter(Name: FilterNames) -> CameraFilter?
    {
        for Camera in FilterList
        {
            if Camera.FilterType == Name
            {
                return Camera
            }
        }
        if let NewRenderer = CreateFilter(For: Name)
        {
            let NewCamera = CameraFilter(WithFilter: NewRenderer, AndType: Name, ID: FilterMap[Name]!)
            FilterList.append(NewCamera)
            NewCamera.Parameters = RenderPacket(ID: FilterMap[Name]!)
            return NewCamera
        }
        return nil
    }
    
    /// Returns the parameter block for the specified camera type.
    ///
    /// - Parameter For: The filter type whose parameters will be returned.
    /// - Returns: The current set of parameters for the specified filter type. Nil on error.
    public func GetParameters(For: FilterNames) -> RenderPacket?
    {
        for Camera in FilterList
        {
            if Camera.FilterType == For
            {
                return Camera.Parameters
            }
        }
        return nil
    }
    
    /// Creates a filter class for the specified filter type.
    ///
    /// - Parameter For: The type of filter class to create.
    /// - Returns: The newly-created filter class. Nil returned on error.
    private func CreateFilter(For: FilterNames) -> Renderer?
    {
        switch For
        {
        case .CircularScreen:
            return CircularScreen()
            
        case .CMYKHalftone:
            return CMYKHalftone()
            
        case .DotScreen:
            return DotScreen()
            
        case .HatchScreen:
            return HatchScreen()
            
        case .LineScreen:
            return LineScreen()
            
        case .CircleAndLines:
            return nil
            
        case .Noir:
            return Noir()
            
        case .PassThrough:
            return PassThrough()
            
        case .Pixellate:
            return Pixellate()
            
        default:
            return nil
        }
    }
    
    private var _FilterList = [CameraFilter]()
    /// Get or set the list of filters.
    public var FilterList: [CameraFilter]
    {
        get
        {
            return _FilterList
        }
        set
        {
            _FilterList = newValue
        }
    }
    
    /// Map between filter types and filter IDs.
    private let FilterMap: [FilterNames: UUID] =
        [
            .Noir: UUID(uuidString: "7215048f-15ea-46a1-8b11-a03e104a568d")!,
            .LineScreen: UUID(uuidString: "03d25ebe-1536-4088-9af6-150490262467")!,
            .CircularScreen: UUID(uuidString: "43a29cb4-4f85-40a7-b535-3cd659edd3cb")!,
            .DotScreen: UUID(uuidString: "48145942-f695-436a-a9bc-94158d3b469a")!,
            .HatchScreen: UUID(uuidString: "49a3792a-f46a-40c5-8831-51ff7834e8c7")!,
            .Pixellate: UUID(uuidString: "0f56b55b-0d77-4c3a-98eb-cadc62be7f4d")!,
            .CircleAndLines: UUID(uuidString: "0c84fc21-e06a-4b49-ae0e-90594abeeb4a")!,
            .CMYKHalftone: UUID(uuidString: "13c40f19-3d54-492c-92bc-2680f4cf2a2f")!,
            .PassThrough: UUID(uuidString: "e18b32bf-e965-41c6-a1f5-4bb4ed6ba472")!,
            ]
}
