//
//  StringExtensions.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation

//https://stackoverflow.com/questions/45562662/how-can-i-use-string-slicing-subscripts-in-swift-4
extension String
{
    subscript(Value: NSRange) -> Substring
    {
        return self[Value.lowerBound ..< Value.upperBound]
    }
}

extension String
{
    subscript(value: CountableClosedRange<Int>) -> Substring
    {
        get
        {
            return self[index(at: value.lowerBound)...index(at: value.upperBound)]
        }
    }
    
    subscript(value: CountableRange<Int>) -> Substring
    {
        get
        {
            return self[index(at: value.lowerBound)..<index(at: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeUpTo<Int>) -> Substring
    {
        get
        {
            return self[..<index(at: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeThrough<Int>) -> Substring
    {
        get
        {
            return self[...index(at: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeFrom<Int>) -> Substring
    {
        get
        {
            return self[index(at: value.lowerBound)...]
        }
    }
    
    func index(at offset: Int) -> String.Index
    {
        return index(startIndex, offsetBy: offset)
    }
}
