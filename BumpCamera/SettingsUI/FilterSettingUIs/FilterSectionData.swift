//
//  FilterSectionData.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/1/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class FilterSectionData
{
    init(_ IsCollapsed: Bool = false)
    {
        _SectionCollapsed = IsCollapsed
    }
    
    private var _CanCollaspe: Bool = true
    public var CanCollapse: Bool
    {
        get
        {
            return _CanCollaspe
        }
        set
        {
            _CanCollaspe = newValue
        }
    }
    
    private var _HeaderTitle: String = ""
    public var HeaderTitle: String
    {
        get
        {
            return _HeaderTitle
        }
        set
        {
            _HeaderTitle = newValue
        }
    }
    
    private var _Index: Int = 0
    public var Index: Int
    {
        get
        {
            return _Index
        }
        set
        {
            _Index = newValue
        }
    }
    
    private var _SectionCollapsed: Bool = false
    public var SectionCollapsed: Bool
    {
        get
        {
            return _SectionCollapsed
        }
    }
    
    func Toggle() -> Bool
    {
        _SectionCollapsed.toggle()
        return _SectionCollapsed
    }
    
    private var _Title: String = ""
    public var Title: String
    {
        get
        {
            return _Title
        }
        set
        {
            _Title = newValue
        }
    }
    
    private var _CellData: [(FilterManager.FilterTypes, String)] = [(FilterManager.FilterTypes, String)]()
    public var CellData: [(FilterManager.FilterTypes, String)]
    {
        get
        {
            return _CellData
        }
        set
        {
            _CellData = newValue
        }
    }
    
    func CellTitle(AtIndex: Int) -> String
    {
        if AtIndex > _CellData.count - 1 || AtIndex < 1
        {
            fatalError("Bad index for title.")
        }
        return _CellData[AtIndex].1
    }
    
    func CellType(AtIndex: Int) -> FilterManager.FilterTypes
    {
        if AtIndex > _CellData.count - 1 || AtIndex < 0
        {
            fatalError("Bad index for title.")
        }
        return _CellData[AtIndex].0
    }
}

