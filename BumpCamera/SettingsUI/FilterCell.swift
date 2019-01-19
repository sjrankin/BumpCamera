//
//  FilterCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class FilterCell: UITableViewCell
{
    public static var CellHeight: CGFloat = 70.0
    public var delegate: FilterSettings? = nil
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
    }
    
    public func SetData(_ LabelTitle: String? = nil, InputField: RenderPacket.InputFields, OldValue: String)
    {
        self.InputField = InputField
    }
    
    private var InputField: RenderPacket.InputFields!
    
    private func HandleChange(_ NewRawValue: String)
    {
        delegate?.NewRawValue(NewRawValue, Field: InputField)
    }
}
