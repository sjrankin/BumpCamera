//
//  ActivityLog.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// When in DEBUG mode, maintains a log of activities the user does with the app. When not in DEBUG mode, nothing happens.
class ActivityLog
{
    /// Initialize the activity log.
    ///
    /// - Note: The activity log in general and this function in particular is highly dependent on the value
    ///         of the DEBUG compile-time flag. If true, functionality is available. If false, no activity
    ///         log functionality is available and this function will do nothing more than return to the
    ///         caller.
    ///
    /// - Parameters:
    ///   - TimeStamp: Time stamp for initialization.
    ///   - AlwaysEmitImmediately: If true, the log is written to disk as it is appended. This will negatively
    ///                            affect performance.
    public static func Initialize(TimeStamp: Date, AlwaysEmitImmediately: Bool = true)
    {
        #if DEBUG
        AlwaysEmitNow = AlwaysEmitImmediately
        _IsActive = true
        _LogTimeStamp = TimeStamp
        let LogName = CreateLogName(With: TimeStamp)
        let TimeString = Utility.MakeTimeStamp(FromDate: TimeStamp)
        LogURL = FileHandler.SaveStringToFileEx("<ActivityLog App=\"BumpCamera\" TimeStamp=\"\(TimeString)\">\n", FileName: LogName, ToDirectory: FileHandler.DebugDirectory)
        try! Versioning.EmitXML(4).AppendSelf(To: LogURL!)
        #endif
    }
    
    /// Close the activity log. This sets the log's URL to nil so no more writes may occur.
    public static func Close()
    {
        #if DEBUG
        if LogURL == nil
        {
            return
        }
        if IsActive
        {
            do
            {
                try "</ActivityLog>\n".AppendSelf(To: LogURL!)
                LogURL = nil
            }
            catch
            {
                print("Error appending text to activity log.")
                return
            }
        }
        #endif
    }
    
    /// Holds the immediate emission flag for the log.
    private static var AlwaysEmitNow: Bool = false
    
    /// Holds the log file's URL.
    private static var LogURL: URL? = nil
    
    /// Create a file name for the log.
    ///
    /// - Parameter TimeStamp: Time stamp that will form part of the log's name.
    /// - Returns: File name for the log with the extension of .xml.
    private static func CreateLogName(With TimeStamp: Date) -> String
    {
        let Working = "ActivityLogFor_\(Utility.MakeTimeStamp(FromDate: TimeStamp, TimeSeparator: "-")).xml"
        return Working
    }
    
    /// Contains the log's time stamp.
    private static var _LogTimeStamp: Date? = nil
    /// Get or set (but please don't set) the time stamp of the log.
    public static var LogTimeStamp: Date?
    {
        get
        {
            return _LogTimeStamp
        }
        set
        {
            _LogTimeStamp = newValue
        }
    }
    
    /// Contains the list of log nodes.
    static var LogNodeList = [ActivityLogNode]()
    
    /// Clear all log nodes from the internal log node list.
    public static func RemoveAll()
    {
        LogNodeList.removeAll()
    }
    
    /// Holds the is active value.
    private static var _IsActive: Bool = false
    /// Get or set the IsActive flag. If not in DEBUG mode, false is always returned.
    public static var IsActive: Bool
    {
        get
        {
            #if DEBUG
            return _IsActive
            #else
            return false
            #endif
        }
    }
    
    /// Holds the last text written to the log and potentially to the debug console.
    private static var LastText: String = ""
    /// Number of times the same text has been repeated in a row without intervening deltas.
    private static var TextRepeatCount: Int = 0
    
    /// Print to the log and optionally debug console.
    ///
    /// - Parameters:
    ///   - Text: The message to log and print.
    ///   - ConsoleToo: If true, the message is sent to Xcode's debug console.
    ///   - SuppressRepeats: If true, suppresses repeated strings - the first is printed and then nothing
    ///                      is printed (or saved) until a new string arrives. When that happens, a message
    ///                      stating how many repeats occurred is printed, then the new message is printed.
    public static func LogPrint(_ Text: String, ConsoleToo: Bool = true, SuppressRepeats: Bool = true)
    {
        if IsActive
        {
            if SuppressRepeats
            {
                if Text == LastText
                {
                    TextRepeatCount = TextRepeatCount + 1
                    return
                }
                if TextRepeatCount > 0
                {
                    print("Previous message repeated \(TextRepeatCount) times.")
                    let Node = ActivityLogNode(NodeMessage: "Previous message repeated \(TextRepeatCount) times.", TimeStamp: Date())
                    AddLogNode(Node)
                    TextRepeatCount = 0
                }
                LastText = Text
            }
            else
            {
                LastText = ""
                TextRepeatCount = 0
            }
            if ConsoleToo
            {
                print(Text)
            }
            let Node = ActivityLogNode(Text: Text, TimeStamp: Date())
            AddLogNode(Node)
        }
        else
        {
            print(Text)
        }
    }
    
    /// Print to the log and optionally debug console.
    ///
    /// - Parameters:
    ///   - Text: The message to log and print.
    ///   - FilterData: Information on a filter's settings.
    ///   - ConsoleToo: If true, the message is sent to Xcode's debug console.
    ///   - SuppressRepeats: If true, suppresses repeated strings - the first is printed and then nothing
    ///                      is printed (or saved) until a new string arrives. When that happens, a message
    ///                      stating how many repeats occurred is printed, then the new message is printed.
    public static func LogPrint(_ Text: String, FilterData: String, ConsoleToo: Bool = true, SuppressRepeats: Bool = true)
    {
        if IsActive
        {
            if SuppressRepeats
            {
                if Text == LastText
                {
                    TextRepeatCount = TextRepeatCount + 1
                    return
                }
                if TextRepeatCount > 0
                {
                    print("Previous message repeated \(TextRepeatCount) times.")
                    let Node = ActivityLogNode(NodeMessage: "Previous message repeated \(TextRepeatCount) times.", TimeStamp: Date())
                    AddLogNode(Node)
                    TextRepeatCount = 0
                }
                LastText = Text
            }
            else
            {
                LastText = ""
                TextRepeatCount = 0
            }
            if ConsoleToo
            {
                print(Text)
            }
            let Node = ActivityLogNode(Text: Text, TimeStamp: Date())
            Node.FilterData = FilterData
            AddLogNode(Node)
        }
        else
        {
            print(Text)
        }
    }
    
    /// Print to the log and optionally debug console.
    ///
    /// - Parameters:
    ///   - Message: The message to log and print.
    ///   - ConsoleToo: If true, the message is sent to Xcode's debug console.
    ///   - SuppressRepeats: If true, suppresses repeated strings - the first is printed and then nothing
    ///                      is printed (or saved) until a new string arrives. When that happens, a message
    ///                      stating how many repeats occurred is printed, then the new message is printed.
    public static func LogMessage(_ Message: String, ConsoleToo: Bool = true, SuppressRepeats: Bool = true)
    {
        if IsActive
        {
            if SuppressRepeats
            {
                if Message == LastText
                {
                    TextRepeatCount = TextRepeatCount + 1
                    return
                }
                if TextRepeatCount > 0
                {
                    print("Previous message repeated \(TextRepeatCount) times.")
                    let Node = ActivityLogNode(NodeMessage: "Previous message repeated \(TextRepeatCount) times.", TimeStamp: Date())
                    AddLogNode(Node)
                    TextRepeatCount = 0
                }
                LastText = Message
            }
            else
            {
                LastText = ""
                TextRepeatCount = 0
            }
            if ConsoleToo
            {
                print(Message)
            }
            let Node = ActivityLogNode(NodeMessage: Message, TimeStamp: Date())
            AddLogNode(Node)
        }
        else
        {
            print(Message)
        }
    }
    
    /// Print to the log and optionally debug console.
    ///
    /// - Parameters:
    ///   - Message: The message to log and print.
    ///   - SubMessage: Secondary message to log and print.
    ///   - ConsoleToo: If true, the message is sent to Xcode's debug console.
    ///   - SuppressRepeats: If true, suppresses repeated strings - the first is printed and then nothing
    ///                      is printed (or saved) until a new string arrives. When that happens, a message
    ///                      stating how many repeats occurred is printed, then the new message is printed.
    public static func LogMessage(_ Message: String, _ SubMessage: String, ConsoleToo: Bool = true, SuppressRepeats: Bool = true)
    {
        if IsActive
        {
            if SuppressRepeats
            {
                if Message == LastText
                {
                    TextRepeatCount = TextRepeatCount + 1
                    return
                }
                if TextRepeatCount > 0
                {
                    print("Previous message repeated \(TextRepeatCount) times.")
                    let Node = ActivityLogNode(NodeMessage: "Previous message repeated \(TextRepeatCount) times.", TimeStamp: Date())
                    AddLogNode(Node)
                    TextRepeatCount = 0
                }
                LastText = Message
            }
            else
            {
                LastText = ""
                TextRepeatCount = 0
            }
            if ConsoleToo
            {
                print(Message)
                print(SubMessage)
            }
            let Node = ActivityLogNode(NodeMessage: Message, NodeSubMessage: SubMessage, TimeStamp: Date())
            AddLogNode(Node)
        }
        else
        {
            print(Message)
            print(SubMessage)
        }
    }
    
    /// Lock object for adding nodes to the node list.
    private static var AddLock: NSObject = NSObject()
    
    /// Add a log node to the node list. Optionally emit the log node to the log file immediately.
    ///
    /// - Parameters:
    ///   - Node: The log node to add.
    ///   - EmitImmediately: If true, the contents of the node are immediately written to the log file
    ///                      (which will affect performance). If false, the log file is not written by
    ///                      this function. If the caller set the AlwaysEmitImmediately parameter in
    ///                      Initialize to true, even if EmitImmediately is false, the log will be
    ///                      written to immediately.
    public static func AddLogNode(_ Node: ActivityLogNode, EmitImmediately: Bool = false)
    {
        objc_sync_enter(AddLock)
        defer{objc_sync_exit(AddLock)}
        if !IsActive
        {
            return
        }
        LogNodeList.append(Node)
        if EmitImmediately || AlwaysEmitNow
        {
            do
            {
                try Node.ToString().AppendSelf(To: LogURL!)
            }
            catch
            {
                fatalError("Error appending data to activity log.")
            }
        }
    }
    
    /// Return the contents of the log as an XML-formatted string.
    ///
    /// - Returns: XML-formated fragment with the contents of the log.
    public static func ToString() -> String
    {
        if IsActive
        {
            var TimeString = ""
            if let TimeStamp = LogTimeStamp
            {
                let Final =  Utility.MakeTimeStamp(FromDate: TimeStamp)
                TimeString = "TimeStamp=\"\(Final)\" "
            }
            var Working = "<ActivityLog App=\"BumpCamera\"\(TimeString)>\n"
            
            for Node in LogNodeList
            {
                Working = Working + Node.ToString()
            }
            
            Working = Working + "</ActivityLog>/n"
            return Working
        }
        else
        {
            return ""
        }
    }
}
