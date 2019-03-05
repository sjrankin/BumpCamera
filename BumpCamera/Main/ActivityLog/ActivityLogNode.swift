//
//  ActivityLogNode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// One log entry in the activity log.
class ActivityLogNode
{
    /// Initialize the node.
    ///
    /// - Parameters:
    ///   - Text: The text value of the node.
    ///   - TimeStamp: The time stamp of the entry.
    init(Text: String, TimeStamp: Date? = nil)
    {
        NodeTimeStamp = TimeStamp
        PrintMessage = Text
    }
    
    /// Initialize the node.
    ///
    /// - Parameters:
    ///   - NodeMessage: The text value of the node.
    ///   - TimeStamp: The time stamp of the entry.
    init(NodeMessage: String, TimeStamp: Date? = nil)
    {
        NodeTimeStamp = TimeStamp
        Message = NodeMessage
    }
    
    /// Initialize the node.
    ///
    /// - Parameters:
    ///   - NodeMessage: The text value of the node.
    ///   - NodeSubMessage: The sub-text value of the node.
    ///   - TimeStamp: The time stamp of the entry.
    init(NodeMessage: String, NodeSubMessage: String, TimeStamp: Date? = nil)
    {
        NodeTimeStamp = TimeStamp
        Message = NodeMessage
        SubMessage = NodeSubMessage
    }
    
    /// Contains optional filter data.
    private var _FilterData: String? = nil
    /// String that describes a filter instance.
    public var FilterData: String?
    {
        get
        {
            return _FilterData
        }
        set
        {
            _FilterData = newValue
        }
    }
    
    /// Holds the text of the message.
    private var _PrintMessage: String? = nil
    /// Get or set the text.
    public var PrintMessage: String?
    {
        get
        {
            return _PrintMessage
        }
        set
        {
            _PrintMessage = newValue
        }
    }
    
    /// Holds the message.
    private var _Message: String? = nil
    /// Get or set the message.
    public var Message: String?
    {
        get
        {
            return _Message
        }
        set
        {
            _Message = newValue
        }
    }
    
    /// Holds the sub-message.
    private var _SubMessage: String? = nil
    /// Get or set the sub-message.
    public var SubMessage: String?
    {
        get
        {
            return _SubMessage
        }
        set
        {
            _SubMessage = newValue
        }
    }
    
    /// Holds the time stamp of the node.
    private var _NodeTimeStamp: Date? = nil
    /// Get or set the time stamp.
    public var NodeTimeStamp: Date?
    {
        get
        {
            return _NodeTimeStamp
        }
        set
        {
            _NodeTimeStamp = newValue
        }
    }
    
    /// Returns the contents of the node as an XML fragment.
    public func ToString() -> String
    {
        var NodeTime: String = ""
        if let TimeStamp = NodeTimeStamp
        {
            NodeTime = " TimeStamp=\"\(TimeStamp)\" "
        }
        
        var Working = "<Activity\(NodeTime)>\n"
        
        if let PMessage = PrintMessage
        {
            Working = Working + "  <Print Text=\"\(PMessage)>\"\n"
        }
        if let NodeMessage = Message
        {
            Working = Working + "  <Message Text=\"\(NodeMessage)>\"\n"
        }
        if let NodeSubMessage = SubMessage
        {
            Working = Working + "  <Message2 Text=\"\(NodeSubMessage)>\"\n"
        }
        if let FilterSettings = FilterData
        {
            Working = Working + "  <FilterSettings>\n"
            Working = Working + FilterSettings
            Working = Working + "  </FilerSettings>\n"
        }
        
        Working = Working + "</Activity>\n"
        
        return Working
    }
}
