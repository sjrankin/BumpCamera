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
    /// Initializer.
    ///
    /// - Parameter ID: ID of the filter.
    init(ID: UUID)
    {
        _ID = ID
    }
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - WithFilter: The filter renderer class for the camera filter encapsulation.
    ///   - AndType: The type description of the filter renderer.
    ///   - ID: ID of the filter.
    init(WithFilter: Renderer, AndType: FilterNames, ID: UUID)
    {
        _FilterType = AndType
        _Filter = WithFilter
        _ID = ID
    }
    
    private var _FilterType: FilterNames = FilterNames.NotSet
    /// Get or set the type of filter to render.
    public var FilterType: FilterNames
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
}
