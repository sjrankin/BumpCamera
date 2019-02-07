//
//  FilterCollectionCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/16/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Implements a UICollectionViewCell for filters and groups. Used by the user to select which filter to use.
class FilterCollectionCell: UICollectionViewCell
{
    /// Initializer.
    ///
    /// - Parameter frame: Frame of the view.
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        clipsToBounds = true
        let ContainerRect = CGRect(x: 0, y: 0, width: 80, height: 50)
        Container = UIView(frame: ContainerRect)
        Container.layer.borderColor = UIColor.black.cgColor
        Container.layer.borderWidth = 0.25
        Container.layer.cornerRadius = 5.0
        Container.clipsToBounds = true
        
        TitleLabel = UILabel()
        TitleLabel.frame = CGRect(x: 5, y: 0, width: 70, height: 50)
        TitleLabel.textAlignment = .center
        TitleLabel.contentMode = .center
        TitleLabel.text = "?"
        TitleLabel.font = UIFont(name: "Avenir", size: 14.0)
        TitleLabel.numberOfLines = 3
        TitleLabel.textColor = UIColor.black
        TitleLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        Container.addSubview(TitleLabel)
        
        contentView.addSubview(Container)
        if BorderLayer == nil
        {
            MakeSelectionLayer()
        }
    }
    
    var Container: UIView!
    var TitleLabel: UILabel!
    var CellIcon: UIImageView!
    var BorderLayer: CAShapeLayer? = nil
    var IsGroupNode: Bool = false
    var GroupColor: UIColor? = nil
    
    /// Initializer. Not implemented. Calling this will result in a fatal error.
    ///
    /// - Parameter aDecoder: See Apple documentation.
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Not implemented")
    }
    
    /// Creates a layer that visually indicates selection status.
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
    
    /// Set various values to display in the cell. Since cells can be (and will be) reused, all fields are reset.
    ///
    /// - Parameters:
    ///   - Title: The title of the cell.
    ///   - IsSelected: Selection flag.
    ///   - ID: ID of the cell. Used for debug purposes.
    ///   - IsGroup: Flag that indicates if this cell is for group selection or filter selection.
    ///   - Color: Background color.
    func SetCellValue(Title: String, IsSelected: Bool, ID: Int, IsGroup: Bool, Color: UIColor)
    {
        TitleLabel.text = Title
        TitleLabel.backgroundColor = Color
        Container.backgroundColor = Color
        if IsGroup
        {
            IsGroupNode = true
            GroupColor = Color
        }
        SetSelectionState(Selected: IsSelected)
    }
    
    /// Set the selection state of the cell.
    ///
    /// - Parameter Selected: True for selected, false for deselected.
    func SetSelectionState(Selected: Bool)
    {
        BorderLayer!.strokeColor = Selected ? UIColor.red.cgColor : UIColor.clear.cgColor
    }
}
