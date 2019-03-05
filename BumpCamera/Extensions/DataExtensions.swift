//
//  DataExtensions.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation

/// Data extensions.
extension Data
{
    /// Append the data to a file whose URL is passed to us.
    ///
    /// - Note:
    ///    - [Append text or data to text file in Swift.](https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift)
    ///
    /// - Parameter FileURL: The URL of the file to append to.
    /// - Throws: Throws an exception if unable to get the file handle or on error writing to the file.
    func Append(To FileURL: URL) throws
    {
        if let FileHandle = try? FileHandle(forWritingTo: FileURL)
        {
            defer
            {
                FileHandle.closeFile()
            }
            FileHandle.seekToEndOfFile()
            FileHandle.write(self)
        }
        else
        {
            try write(to: FileURL)
        }
    }
}
