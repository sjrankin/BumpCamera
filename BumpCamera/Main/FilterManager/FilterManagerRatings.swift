//
//  FilterManagerRatings.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Extension to FilterManager that manages and maintains ratings for filters.
extension FilterManager
{
    /// Load ratings for each filter.
    public static func LoadFilterRatings()
    {
        print("Loading filter ratings.")
        FilterManager.RatingsList = [FilterTypes: Ratings]()
        for (Filter_Type, _) in FilterManager.FilterInfoMap
        {
            let Rating = Ratings(Filter: Filter_Type)
            FilterManager.RatingsList![Filter_Type] = Rating
        }
    }
    
    /// Return the ratings for the specified filter type.
    ///
    /// - Parameter FilterType: The filter type for which ratings will be returned.
    /// - Parameter CreateOnDemand: If the filter ratings have not yet been loaded, create them and return the new ratings
    ///                             instantiation. Newly created ratings will be saved to the RatingsList.
    /// - Returns: The ratings for the specified filter on success, nil if not found.
    public static func RatingsFor(_ FilterType: FilterTypes, CreateOnDemand: Bool = false) -> Ratings?
    {
        if let RatingsValue = RatingsList![FilterType]
        {
            return RatingsValue
        }
        if !CreateOnDemand
        {
            return nil
        }
        let NewRatings = Ratings(Filter: FilterType)
        RatingsList![FilterType] = NewRatings
        return NewRatings
    }
    
    /// Return the ratings for the specified filter type.
    ///
    /// - Parameter FilterID: The filter ID for which ratings will be returned.
    /// - Parameter CreateOnDemand: If the filter ratings have not yet been loaded, create them and return the new ratings
    ///                             instantiation. Newly created ratings will be saved to the RatingsList.
    /// - Returns: The ratings for the specified filter on success, nil if not found.
    public static func RatingsFor(_ FilterID: UUID, CreateOnDemand: Bool = false) -> Ratings?
    {
        let FilterType = GetFilterTypeFrom(ID: FilterID)
        return RatingsFor(FilterType!)
    }
    
    /// Return all filters with the specified fave value.
    ///
    /// - Parameter Value: Fave value to return.
    /// - Returns: List of tuples with (filter types and ratings).
    public static func GetFiltersWithFave(Value: Bool) -> [(FilterTypes, Ratings)]
    {
        var Results = [(FilterTypes, Ratings)]()
        for (TheType, TheRating) in RatingsList!
        {
            if TheRating.Faved == Value
            {
                Results.append((TheType, TheRating))
            }
        }
        return Results
    }
    
    /// Return all filters with the specified number of stars.
    ///
    /// - Parameter StarCount: Number of stars the filter must have to be returned.
    /// - Returns: List of tuples with (filter types and ratings).
    public static func GetFiltersWith(StarCount: Int) -> [(FilterTypes, Ratings)]
    {
        var Results = [(FilterTypes, Ratings)]()
        for (TheType, TheRating) in RatingsList!
        {
            if TheRating.StarCount == StarCount
            {
                Results.append((TheType, TheRating))
            }
        }
        return Results
    }
    
    /// Return all filters with at least the specified number of stars.
    ///
    /// - Parameter StarCountOf: Minimum number of stars needed for a filter to be returned.
    /// - Returns: List of tuples with (filter types and ratings).
    public static func GetFiltersWithAtLeast(StarCountOf: Int) -> [(FilterTypes, Ratings)]
    {
        var Results = [(FilterTypes, Ratings)]()
        for (TheType, TheRating) in RatingsList!
        {
            if TheRating.StarCount >= StarCountOf
            {
                Results.append((TheType, TheRating))
            }
        }
        return Results
    }
}
