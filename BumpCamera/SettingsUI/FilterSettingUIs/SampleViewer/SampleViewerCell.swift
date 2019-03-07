//
//  SampleViewerCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class SampleViewerCell: UICollectionViewCell
{
    var Container: UIView!
    var ImageView: UIImageView!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        clipsToBounds = true
        let ContainerRect = CGRect(x: 0, y: 0, width: 160, height: 160)
        Container.clipsToBounds = true
        Container.layer.borderColor = UIColor.black.cgColor
        Container.layer.borderWidth = 2.0
        Container.layer.cornerRadius = 2.0
        
        
        ImageView = UIImageView(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
}
