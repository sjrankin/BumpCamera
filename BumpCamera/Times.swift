//
//  Times.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/12/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Functions for calculating percent of elapsed time for various time periods.
class Times
{
    /// Returns the number of seconds the passed time is from the start of the passed time period.
    ///
    /// - Parameters:
    ///   - OfPeriod: The time period.
    ///   - From: The date used to calculate number of seconds into the specified time period.
    /// - Returns: Number of seconds in the specified time period that have elapsed. If an unknown
    ///            time period is passed, minutes are assumed to be the time period.
    public static func SecondsFromStart(OfPeriod: Int, From: Date) -> Int
    {
        let Cal = Calendar.current
        switch OfPeriod
        {
        case 0:
            let Seconds = Cal.component(.second, from: From)
            return Seconds
            
        case 1:
            let Seconds = Cal.component(.second, from: From)
            let Minutes = Cal.component(.minute, from: From)
            return (Minutes * 60) + Seconds
            
        case 2:
            let Seconds = Cal.component(.second, from: From)
            let Minutes = Cal.component(.minute, from: From)
            let Hours = Cal.component(.hour, from: From)
            return (Hours * 60 * 60) + (Minutes * 60) + Seconds
            
        case 3:
            let Seconds = Cal.component(.second, from: From)
            let Minutes = Cal.component(.minute, from: From)
            let Hours = Cal.component(.hour, from: From)
            let Days = Cal.component(.day, from: From)
            return ((Days - 1) * 24 * 60 * 60) + (Hours * 60 * 60) + (Minutes * 60) + Seconds
            
        default:
            let Seconds = Cal.component(.second, from: From)
            return Seconds
        }
    }
    
    /// Returns the number of seconds in the specified time period.
    ///
    /// - Parameters:
    ///   - Period: Time period.
    ///   - In: Date - needed for number of seconds in the current month.
    /// - Returns: Number of seconds in the specified time period. If an unknown period type is passed,
    ///            The number of seconds in a minute is returned.
    public static func SecondsIn(Period: Int, In: Date) -> Int
    {
        switch Period
        {
        case 0:
            return 60
            
        case 1:
            return 60 * 60
            
        case 2:
            return 60 * 60 * 24
            
        case 3:
            let Cal = Calendar.current
            let Interval = Cal.dateInterval(of: .month, for: In)
            let Days = Cal.dateComponents([.day], from: Interval!.start, to: Interval!.end).day!
            return Days * 60 * 60 * 24
            
        default:
            return 60
        }
    }
    
    /// Returns the current percent of the way through the specified time period.
    ///
    /// - Parameters:
    ///   - Period: Determines the period. 0 = Minute, 1 = Hour, 2 = Day, 3 = Month
    ///   - Now: Current time the percent is desired for.
    /// - Returns: Percent of the way through the period.
    public static func Percent(Period: Int, Now: Date) -> Double
    {
        let TotalTime = SecondsIn(Period: Period, In: Now)
        let FromStart = SecondsFromStart(OfPeriod: Period, From: Now)
        let TimePercent = Double(FromStart) / Double(TotalTime)
        return TimePercent
    }
}
