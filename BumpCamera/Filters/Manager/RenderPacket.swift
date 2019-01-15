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
    /// Initializer.
    ///
    /// - Parameter ID: ID of the filter.
    init(ID: UUID)
    {
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
}
