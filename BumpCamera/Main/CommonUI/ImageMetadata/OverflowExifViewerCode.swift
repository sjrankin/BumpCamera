//
//  OverflowExifViewerCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/25/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Runs the Image Metadata Viewer overflow UI. Some tag values are rather voluble and don't fit into a normal iOS UI so
/// in that case, this UI allows the user to see the entire tag value.
class OverflowExifViewerCode: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        GroupLabelName.text = GroupName
        TagLabelName.text = TagName
        TagValueViewer.text = OverflowValue
        
        TagValueViewer.layer.borderColor = UIColor.black.cgColor
        TagValueViewer.layer.borderWidth = 0.5
        TagValueViewer.layer.cornerRadius = 5.0
        
        tableView.tableFooterView = UIView()
    }
    
    public func LoadOverflowData(Group: String, Tag: String, Overflow: String)
    {
        GroupName = Group
        TagName = Tag
        OverflowValue = Utility.StripNonEssentialWhitespace(From: Overflow)
    }
    
    private var GroupName: String = ""
    private var TagName: String = ""
    private var OverflowValue: String = ""
    
    @IBOutlet weak var TagValueViewer: UITextView!
    @IBOutlet weak var TagLabelName: UILabel!
    @IBOutlet weak var GroupLabelName: UILabel!
}
