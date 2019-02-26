//
//  ImageMetadata.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/25/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Container for image metadata.
class ImageMetadata
{
    public static let TopLevelName = "  Top Level"
    
    /// Initializer.
    init()
    {
    }
    
    /// Add a new tag (empty) tag group to the metadata.
    ///
    /// - Parameter NewGroupName: Name of the new tag group.
    /// - Returns: The new (and empty) tag group.
    public func AddGroup(_ NewGroupName: String) -> TagGroup
    {
        let NewGroup = TagGroup()
        NewGroup.GroupName = NewGroupName
        Groups.append((NewGroupName, NewGroup))
        return NewGroup
    }
    
    /// Contains a dictionary of groups.
    private var _Groups: [(String, TagGroup)] = [(String, TagGroup)]()
    /// Get or set groups contained in the metadata.
    public var Groups: [(String, TagGroup)]
    {
        get
        {
            return _Groups
        }
        set
        {
            _Groups = newValue
        }
    }
    
    /// Return the number of tags in the specified group.
    ///
    /// - Parameter Index: Determines the group.
    /// - Returns: Number of tags in the specified ground. 0 returned if the index is out of range.
    func TagCountInGroup(_ Index: Int) -> Int
    {
        if Index < 0
        {
            return 0
        }
        if Index > Groups.count - 1
        {
            return 0
        }
        return Groups[Index].1.TagList.count
    }
    
    /// Given a group index and tag index, return the specified tag data.
    ///
    /// - Parameters:
    ///   - GroupIndex: Determines the group.
    ///   - TagIndex: Determines the tag to return.
    /// - Returns: Specified tag on success, nil on index out of range.
    func TagInGroup(GroupIndex: Int, TagIndex: Int) -> TagTypes?
    {
        if GroupIndex < 0
        {
            return nil
        }
        if GroupIndex > Groups.count - 1
        {
            return nil
        }
        if TagIndex < 0
        {
            return nil
        }
        if TagIndex > Groups[GroupIndex].1.TagList.count - 1
        {
            return nil
        }
        return Groups[GroupIndex].1.TagList[TagIndex]
    }

    /// Sort groups by group name. Additionally, all tags in each group are sorted as well.
    func Sort()
    {
        if Groups.count < 1
        {
            return
        }
        Groups.sort{$0.0 < $1.0}
        for Group in Groups
        {
            Group.1.Sort()
        }
    }
    
    /// Export metadata as a string in the specified format.
    ///
    /// - Parameters:
    ///   - As: Determines the format of the returned string.
    ///   - ImageName: Name of the image for whose metadata is being exported.
    /// - Returns: String with metadata in the specified format.
    func Export(As: FilterManager.ExportDataTypes, ImageName: String) -> String
    {
        var Result = ""
        
        switch As
        {
        case .XML:
            Result = "<Metadata Image=\"\(ImageName)\">\n"
            for Group in Groups
            {
                Result = Result + Group.1.Export(As: As)
            }
            Result = Result + "</Metadata>\n"
            
        case .JSON:
            Result = "{\n"
            Result = Result + "\"Image\": \"\(ImageName)\",\n"
            Result = Result + "\"Group\n: [\n"
            for Group in Groups
            {
                Result = Result + Group.1.Export(As: As)
            }
            Result = Result + "]\n"
            Result = Result + "}\n"
            
        case .CSV:
            Result = "\(ImageName),,\n"
            for Group in Groups
            {
                Result = Result + Group.1.Export(As: As)
            }
        }
        
        return Result
    }
}

/// Contains information about a tag group. A tag group is a grouping of like-tags, such as
/// MakeApple or EXIF or similar.
class TagGroup
{
    /// Initializer.
    init()
    {
    }
    
    /// Contains the group name.
    private var _GroupName: String = ""
    /// Get or set the group name.
    public var GroupName: String
    {
        get
        {
            return _GroupName
        }
        set
        {
            _GroupName = newValue
        }
    }
    
    /// Contains the list of tags.
    private var _TagList: [TagTypes] = [TagTypes]()
    /// Get or set the list of tags associated with the group.
    public var TagList: [TagTypes]
    {
        get
        {
            return _TagList
        }
        set
        {
            _TagList = newValue
        }
    }
    
    /// Sorts the list of tags by key name.
    public func Sort()
    {
        TagList.sort{$0.Key < $1.Key}
    }
    
    /// Export the tag group in the format specified.
    ///
    /// - Parameter As: The format of the resultant export.
    /// - Returns: Group exported to a string with the specified format.
    public func Export(As: FilterManager.ExportDataTypes = .XML) -> String
    {
        var Result = ""
        var NiceName = GroupName
        if NiceName == "  Top Level"
        {
            NiceName = "Top Level"
        }
        switch As
        {
        case .XML:
            Result = "<Group Name=\"\(NiceName)\">\n"
            for SomeTag in TagList
            {
                Result = Result + SomeTag.Export(As: As)
            }
            Result = Result + "</Group>\n"
            
        case .JSON:
            Result = "{\n"
            Result = Result + "\"Name\": \"\(NiceName)\"\n"
            Result = Result + "\"Tag\": [\n"
            for SomeTag in TagList
            {
                Result = Result + SomeTag.Export(As: As)
            }
            Result = Result + "]\n"
            Result = Result + "},\n"
            
        case .CSV:
            for SomeTag in TagList
            {
                Result = Result + SomeTag.Export(As: As)
            }
        }
        
        return Result
    }
}

/// Contains tag information.
class TagTypes
{
    /// Initializer.
    ///
    /// - Parameters:
    ///   - InitialKey: The tag's key (name) value.
    ///   - InitialValue: The tag's value. All tag values are cast to strings.
    init(_ InitialKey: String, _ InitialValue: String)
    {
        _Key = InitialKey
        _Value = InitialValue
        _GroupName = ""
    }
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - InitialKey: The tag's key (name) value.
    ///   - InitialValue: The tag's value. All tag values are cast to strings.
    ///   - InitialGroup: the name of the group to which the tag belongs.
    init(_ InitialKey: String, _ InitialValue: String, _ InitialGroup: String)
    {
        _Key = InitialKey
        _Value = InitialValue
        _GroupName = InitialGroup
    }
    
    /// Contains the tag's key name.
    private var _Key: String = ""
    /// Get or set the tag's key name.
    public var Key: String
    {
        get
        {
            return _Key
        }
        set
        {
            _Key = newValue
        }
    }
    
    /// Contains the tag's value.
    private var _Value: String = ""
    /// Get or set the tag's value. All tag values are cast to strings.
    public var Value: String
    {
        get
        {
            return _Value
        }
        set
        {
            _Value = newValue
        }
    }
    
    /// Contains the tag's group name.
    private var _GroupName: String = ""
    /// Get or set the group name associated with the tag.
    public var GroupName: String
    {
        get
        {
            return _GroupName
        }
        set
        {
            _GroupName = newValue
        }
    }
    
    /// Export the tag as a string in the specified format.
    ///
    /// - Parameter As: The format of the resultant string.
    /// - Returns: String representation of the tag in the specified format.
    public func Export(As: FilterManager.ExportDataTypes = .XML) -> String
    {
        var Result = ""
        var FinalValue = Utility.StripNonEssentialWhitespace(From: _Value)
        
        switch As
        {
        case .XML:
            FinalValue = Utility.ReplaceXMLEntities(FinalValue)
            Result = "<Tag Name=\"\(_Key)\" Value=\"\(FinalValue)\"/>\n"
            
        case .JSON:
            FinalValue = Utility.ReplaceJSONEntities(FinalValue)
            Result = "{\n"
            Result = Result + "  \"Name\" : \"\(_Key)\",\n"
            Result = Result + "  \"Value\" : \"\(FinalValue)\",\n"
            Result = Result + "}\n"
            
        case .CSV:
            Result = "\(GroupName),\(_Key),\(FinalValue)\n"
        }
        
        return Result
    }
}
