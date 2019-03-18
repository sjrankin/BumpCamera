//
//  BlockMeanResultCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class BlockMeanResultCell: UITableViewCell
{
    public static var CellHeight: CGFloat = 50.0
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    var ColorSample: UIView!
    var IndexLabel: UILabel!
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
        
        IndexLabel = UILabel(frame: CGRect(x: 10, y: 5, width: 70, height: 40))
        IndexLabel.textAlignment = .right
        IndexLabel.font = UIFont(name: "Courier", size: 20.0)
        contentView.addSubview(IndexLabel)
        
        ColorSample = UIView(frame: CGRect(x: 100, y: 5, width: 100, height: 40))
        ColorSample.layer.borderColor = UIColor.black.cgColor
        ColorSample.layer.borderWidth = 0.5
        ColorSample.layer.cornerRadius = 5.0
        contentView.addSubview(ColorSample)
    }
    
    func SetData(IndexValue: String, Color: UIColor)
    {
        IndexLabel.text = IndexValue
        ColorSample.backgroundColor = Color
    }
}
