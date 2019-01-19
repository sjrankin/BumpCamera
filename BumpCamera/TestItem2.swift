//
//  TestItem2.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/16/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ScrollTestItem2: UICollectionViewCell
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
        Label.font = UIFont(name: "Helvetica Neue", size: 14.0)
        Label.text = "?"
        Label.textColor = UIColor.red
        
        Container = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 50))
        Container.addSubview(Label)
        
        contentView.addSubview(Container)
        #if false
        MakeSelectionLayer()
        #else
        if BorderLayer == nil
        {
            MakeSelectionLayer()
        }
        #endif
    }
    
    var Label: UILabel!
    var Container: UIView!
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("what is this anyway?")
    }
    
    func SetCellValue(_ Value: String, GroupColor: UIColor)
    {
        Label.textColor = UIColor.black
        Label.backgroundColor = GroupColor
        Label.text = Value
        TheGroupColor = GroupColor
    }
    
    private var TheGroupColor: UIColor = UIColor.lightGray
    
    func GetGroupColor() -> UIColor
    {
        return TheGroupColor
    }
    
    func GetValue() -> String
    {
        return Label.text!
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
        SetSelectionState(Selected: false, ForRow: -1, ID: -1)
        Container.layer.addSublayer(BorderLayer!)
    }
    
    var BorderLayer: CAShapeLayer? = nil
    
    func SetSelectionState(Selected: Bool, ForRow: Int, ID: Int)
    {
        if ForRow != ID
        {
            print("Mistmatch between row \(ForRow) and ID \(ID).")
            return
        }
        if Label.text == "?"
        {
            return
        }
        if Selected
        {
            #if false
            if ForRow != -1
            {
                print("Item \((Label.text)!) selected: \(Selected), ForRow: \(ForRow), ID: \(ID).")
            }
            #endif
        }
        BorderLayer!.strokeColor = Selected ? UIColor.red.cgColor : UIColor.clear.cgColor
    }
}
