//
//  GradientStopCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GradientStopCell: UITableViewCell
{
    public static var CellHeight: CGFloat = 70.0
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    var ColorSample: UIView!
    var LocationLabel: UILabel!
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
        
        let CurrentWidth = UIScreen.main.bounds.width
        
        let ColorRect = CGRect(x: 10, y: 5, width: CurrentWidth * 0.5, height: GradientStopCell.CellHeight - 10.0)
        ColorSample = UIView(frame: ColorRect)
        ColorSample.layer.cornerRadius = 5.0
        ColorSample.layer.borderWidth = 0.5
        ColorSample.layer.borderColor = UIColor.black.cgColor
        contentView.addSubview(ColorSample)
        
        let LabelRect = CGRect(x: CurrentWidth - 60.0, y: 5, width: 40.0, height: 30.0)
        LocationLabel = UILabel(frame: LabelRect)
        LocationLabel.textAlignment = .right
        contentView.addSubview(LocationLabel)
        
        self.accessoryType = .disclosureIndicator
        self.selectionStyle = .none
    }
    
    func SetData(StopColor: UIColor, StopLocation: Double)
    {
        ColorSample.backgroundColor = StopColor
        LocationLabel.text = "\(StopLocation.Round(To: 2))"
        _CellColor = StopColor
        _CellLocation = StopLocation
    }
    
    var _CellColor = UIColor.black
    var _CellLocation: Double = 0.0
    
    func CellData() -> (UIColor, Double)
    {
        return (_CellColor, _CellLocation)
    }
}
