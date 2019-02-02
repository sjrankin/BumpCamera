//
//  CollapsibleHeader.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/1/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class CollapsibleHeader: UITableViewHeaderFooterView
{
    var delegate: CollapsibleTableViewHeaderDelegate? = nil
    var Section: Int = 0
    var TitleLabel = UILabel()
    var ArrowLabel = UILabel()
    
    init(reuseIdentifier: String?, CanCollapse: Bool = true)
    {
        super.init(reuseIdentifier: reuseIdentifier!)
        
        HeaderContentsCanCollapse = CanCollapse
        
        contentView.backgroundColor = UIColor.darkGray
        let MarginGuide = contentView.layoutMarginsGuide
        
        contentView.addSubview(TitleLabel)
        TitleLabel.textColor = UIColor.white
        TitleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.bold)
        TitleLabel.translatesAutoresizingMaskIntoConstraints = false
        TitleLabel.topAnchor.constraint(equalTo: MarginGuide.topAnchor).isActive = true
        TitleLabel.trailingAnchor.constraint(equalTo: MarginGuide.trailingAnchor).isActive = true
        TitleLabel.bottomAnchor.constraint(equalTo: MarginGuide.bottomAnchor).isActive = true
        TitleLabel.leadingAnchor.constraint(equalTo: MarginGuide.leadingAnchor).isActive = true
        
        if HeaderContentsCanCollapse
        {
            contentView.addSubview(ArrowLabel)
            ArrowLabel.textColor = UIColor.white
            ArrowLabel.translatesAutoresizingMaskIntoConstraints = false
            ArrowLabel.widthAnchor.constraint(equalToConstant: 12.0).isActive = true
            ArrowLabel.topAnchor.constraint(equalTo: MarginGuide.topAnchor).isActive = true
            ArrowLabel.trailingAnchor.constraint(equalTo: MarginGuide.trailingAnchor).isActive = true
            ArrowLabel.bottomAnchor.constraint(equalTo: MarginGuide.bottomAnchor).isActive = true
            
            let Tap = UITapGestureRecognizer(target: self, action: #selector(HeaderTapped))
            self.addGestureRecognizer(Tap)
        }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("Not implemented.")
    }
    
    var HeaderContentsCanCollapse = true
    
    @objc func HeaderTapped(Recognizer: UITapGestureRecognizer)
    {
        guard let Cell = Recognizer.view as? CollapsibleHeader else
        {
            return
        }
        print("Tapped on section \(Cell.Section)")
        delegate?.ToggleSection(Header: self, Section: Cell.Section)
    }
    
    func SetCollapseVisual(IsCollapsed: Bool)
    {
        //print("Setting collapse visual in \((TitleLabel.text)!) to \(IsCollapsed)")
        let RotateTo: CGFloat = IsCollapsed ? 0.0 : CGFloat.pi / 2.0
        ArrowLabel.Rotate(RotateTo)
    }
}
