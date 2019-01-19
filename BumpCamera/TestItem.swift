//
//  TestItem.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ScrollTestItem: UICollectionViewCell
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        clipsToBounds = true
        layer.borderColor = UIColor.black.cgColor
        layer.backgroundColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 5.0
        Label = UILabel()
        Label.frame = CGRect(x: 0, y: 0, width: 80, height: 50)
        Label.contentMode = .center
        Label.textAlignment = .center
        Label.font = UIFont(name: "Avenir", size: 14.0)
        Label.text = "?"
        Label.textColor = UIColor.red
        Label.numberOfLines = 3
        
        Container = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 50))
        Container.addSubview(Label)
        
        contentView.addSubview(Container)
        if BorderLayer == nil
        {
            MakeSelectionLayer()
        }
    }
    
    var Label: UILabel!
    var Container: UIView!
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("what is this anyway?")
    }
    
    func SetCellValue(_ Value: String, CellColor: UIColor)
    {
        Label.textColor = UIColor.black
        Label.backgroundColor = CellColor
        Label.text = Value
    }
    
    func MakeSelectionLayer()
    {
        BorderLayer = CAShapeLayer()
        BorderLayer!.cornerRadius = 5.0
        BorderLayer!.strokeColor = UIColor.red.cgColor
        BorderLayer!.lineWidth = 2.0
        BorderLayer!.lineDashPattern = [2, 2]
        BorderLayer!.frame = Container.bounds
        BorderLayer!.fillColor = nil
        let SelectRect = CGRect(x: 2, y: 2, width: Container.bounds.width - 4, height: Container.bounds.height - 4)
        BorderLayer!.path = UIBezierPath(rect: SelectRect).cgPath
        SetSelectionState(Selected: false)
        Container.layer.addSublayer(BorderLayer!)
    }
    
    var BorderLayer: CAShapeLayer? = nil
    
    func SetSelectionState(Selected: Bool)
    {
        BorderLayer!.strokeColor = Selected ? UIColor.red.cgColor : UIColor.clear.cgColor
    }
}
