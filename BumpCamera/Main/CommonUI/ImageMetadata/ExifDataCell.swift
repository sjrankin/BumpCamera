//
//  ExifDataCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/25/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Displays Exif (metadata) for images in the Image Metadata Viewer. Notes when the text doesn't fit and
/// notifies callers as needed.
class ExifDataCell: UITableViewCell
{
    public static var CellHeight: CGFloat = 70.0
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    var KeyLabel: UILabel!
    var ValueLabel: UILabel!
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
                self.selectionStyle = .none
        //var Width = UIScreen.main.bounds.width
        //let TableWidth = self.bounds.width
        //Width = Width - TableWidth
        let Width = self.bounds.width
        
        KeyLabel = UILabel()
        KeyLabel.font = UIFont(name: "Avenir", size: 18.0)
        KeyLabel.frame = CGRect(x: 30, y: 0, width: Width, height: 30)
        KeyLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.4, alpha: 1.0)
        self.contentView.addSubview(KeyLabel)
        
        ValueLabel = UILabel()
        ValueLabel.font = UIFont(name: "Avenir-Heavy", size: 20.0)
        ValueLabel.frame = CGRect(x: 30, y: 30, width: Width, height: 40)
        self.contentView.addSubview(ValueLabel)
    }
    
    func SetData(KeyData: String, ValueData: String)
    {
        KeyLabel.text = KeyData
        _KeyData = KeyData
        ValueLabel.text = Utility.StripNonEssentialWhitespace(From: ValueData)
        _ValueData = ValueData
        if ValueLabel.IsTruncated
        {
            self.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            //ValueLabel.textColor = UIColor.orange
            TooMuchText = true
        }
    }
    
    private var _KeyData: String = ""
    private var _ValueData: String = ""
    
    func GetData() -> (String, String)
    {
        return (_KeyData, _ValueData)
    }
    
    private var _TooMuchText: Bool = false
    public var TooMuchText: Bool
    {
        get
        {
            return _TooMuchText
        }
        set
        {
            _TooMuchText = newValue
        }
    }
}
