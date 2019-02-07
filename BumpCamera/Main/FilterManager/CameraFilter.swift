//
//  CameraFilter.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Encapsulates a filter and its parameters.
class CameraFilter
{
    let _Settings = UserDefaults.standard
    
    /// Initializer.
    ///
    /// - Parameter ID: ID of the filter.
    init(ID: UUID)
    {
        #if false
        _ID = ID
        #endif
    }
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - WithFilter: The filter renderer class for the camera filter encapsulation.
    ///   - AndType: The type description of the filter renderer.
    ///   - ID: ID of the filter.
    ///   - ReadParameters: If true, the filter's parameters are read and stored.
    init(WithFilter: Renderer, AndType: FilterManager.FilterTypes, ID: UUID, ReadParameters: Bool = true)
    {
        _FilterType = AndType
        _Filter = WithFilter
        #if false
        _ID = ID
        if ReadParameters
        {
            let IDS = ID.uuidString
            if let Raw = _Settings.string(forKey: IDS)
            {
                print("Filter=\((FilterManager.GetFilterTitle(AndType))!), Raw=\(Raw)")
                Parameters = RenderPacket.Decode(ID: ID, Raw)
            }
        }
        #endif
    }
    
    private var _FilterType: FilterManager.FilterTypes = FilterManager.FilterTypes.NotSet
    /// Get or set the type of filter to render.
    public var FilterType: FilterManager.FilterTypes
    {
        get
        {
            return _FilterType
        }
        set
        {
            _FilterType = newValue
        }
    }
    
    private var _Filter: Renderer? = nil
    /// Get or set the rendering filter.
    public var Filter: Renderer?
    {
        get
        {
            return _Filter
        }
        set
        {
            _Filter = newValue
        }
    }
    
    private var _Parameters: RenderPacket? = nil
    /// Get or set the parameters for rendering. May be nil for those filters that do not take parameters.
    public var Parameters: RenderPacket?
    {
        get
        {
            return _Parameters
        }
        set
        {
            _Parameters = newValue
        }
    }
    
    #if false
    private var _ID: UUID = UUID()
    /// Get or set the ID of the encapsulation, the filter, and the parameters. IDs for the parameter and filter
    /// class are updated when this value is updated.
    public var ID: UUID
    {
        get
        {
            return _ID
        }
        set
        {
            _ID = newValue
            if let Parameters = Parameters
            {
                Parameters.FilterID = _ID
            }
            if let Filter = Filter
            {
                Filter.ID = _ID
            }
        }
    }
    #endif
}
