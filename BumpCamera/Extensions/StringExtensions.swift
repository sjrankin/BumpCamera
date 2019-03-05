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
    /// Appends the contents of the string instance to a file whose URL is passed to us. Relies on the Data
    /// extension Append.
    ///
    /// - Note:
    ///    - [Append text or data to text file in Swift.](https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift)
    ///
    /// - Parameter FileURL: The URL of the file to append the string to.
    /// - Throws: Exception thrown from Append if error occurs there.
    func AppendSelf(To FileURL: URL) throws
    {
        let SomeData = self.data(using: String.Encoding.utf8)
        try SomeData?.Append(To: FileURL)
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
