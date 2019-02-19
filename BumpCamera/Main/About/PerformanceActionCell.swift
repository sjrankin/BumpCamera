//
//  PerformanceActionCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class PerformanceActionCell: UITableViewCell
{
    var delegate: FilterPerformanceCode? = nil
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    var ResetButton: UIButton!
    var ExportButton: UIButton!
    var ClearButton: UIButton!
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
        
        ResetButton = UIButton()
        ResetButton.frame = CGRect(x: 20, y: 20, width: 80, height: 30)
        ResetButton.setTitleColor(UIColor.red, for: UIControl.State.normal)
        ResetButton.setTitle("Reset", for: UIControl.State.normal)
        ResetButton.addTarget(self, action: #selector(HandleResetButtonPressed), for: UIControl.Event.touchUpInside)
        self.contentView.addSubview(ResetButton)
        
        ExportButton = UIButton()
        ExportButton.frame = CGRect(x: 120, y: 20, width: 80, height: 30)
        ExportButton.setTitleColor(UIColor.blue, for: UIControl.State.normal)
        ExportButton.setTitle("Export", for: UIControl.State.normal)
        ExportButton.addTarget(self, action: #selector(HandleExportButtonPressed), for: UIControl.Event.touchUpInside)
        self.contentView.addSubview(ExportButton)
        
        ClearButton = UIButton()
        ClearButton.frame = CGRect(x: 220, y: 20, width: 80, height: 30)
        ClearButton.setTitleColor(UIColor.blue, for: UIControl.State.normal)
        ClearButton.setTitle("Clear", for: UIControl.State.normal)
        ClearButton.addTarget(self, action: #selector(HandleClearButtonPressed), for: UIControl.Event.touchUpInside)
        self.contentView.addSubview(ClearButton)
    }
    
    @objc func HandleResetButtonPressed(_ sender: Any)
    {
        delegate?.DoReset()
    }
    
    @objc func HandleExportButtonPressed(_ sender: Any)
    {
        delegate?.DoExport()
    }
    
    @objc func HandleClearButtonPressed(_ sender: Any)
    {
        delegate?.DoClearDirectory()
    }
}
