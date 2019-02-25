//
//  RunFilterResults.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/25/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit


/// Filter execution result types.
///
/// - Success: Returned on successful execution of a given filter. Result contains the final
///            successful result of the operation.
/// - Failure: Returned on a failed execution of a given filter. Failure(let Reason) will
///            return the reason (in a string) why the filter failed.
public enum RunFilterResults<T>
{
    case Success(Result: T)
    case Failure(Reason: String)
}

/// Equatable extension for the RunFilterResults enum.
extension RunFilterResults: Equatable
{
    /// Compares two RunFilterResults for equality.
    ///
    /// - Parameters:
    ///   - lhs: Left-hand side value.
    ///   - rhs: Right-hand side value.
    /// - Returns: True if the two sides are equal, false if not. Associated values for
    ///            enum cases are not taken into account.
    public static func ==(lhs: RunFilterResults, rhs: RunFilterResults) -> Bool
    {
        switch (lhs, rhs)
        {
        case (.Success, .Success):
            return true
            
        case (.Failure, .Failure):
            return true
            
        default:
            return false
        }
    }
}

