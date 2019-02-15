//
//  GeneralResults.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Filter execution result types.
///
/// - Success: Returned on successful execution of a given operation. Result contains the final
///            successful result of the operation.
/// - Failure: Returned on a failed execution of a given operation. Failure(let Reason) will
///            return the reason (in a string) why the operation failed.
public enum GeneralResults<T>
{
    case Success(Result: T)
    case Failure(Reason: String)
}

/// Equatable extension for the GeneralResults enum.
extension GeneralResults: Equatable
{
    /// Compares two GeneralResults for equality.
    ///
    /// - Parameters:
    ///   - lhs: Left-hand side value.
    ///   - rhs: Right-hand side value.
    /// - Returns: True if the two sides are equal, false if not. Associated values for
    ///            enum cases are not taken into account.
    public static func ==(lhs: GeneralResults, rhs: GeneralResults) -> Bool
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
