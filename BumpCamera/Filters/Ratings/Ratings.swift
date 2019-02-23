//
//  Ratings.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation

/// Encapsulates user ratings for a single filter. Each filter has its own instance of this class.
class Ratings
{
    let _Settings = UserDefaults.standard
    
    /// Default constructor.
    init()
    {
    }
    
    /// Constructor. Loads ratings from user defaults.
    ///
    /// - Parameter ForFilter: The filter associated with these ratings.
    init(Filter: FilterManager.FilterTypes)
    {
        ForFilter = Filter
        LoadRatings()
    }
    
    /// Holds the filter type for these ratings.
    private var _ForFilter: FilterManager.FilterTypes = FilterManager.FilterTypes.NotSet
    /// Get or set the filter associated with the ratings in this instance.
    public var ForFilter: FilterManager.FilterTypes
    {
        get
        {
            return _ForFilter
        }
        set
        {
            _ForFilter = newValue
            FilterID = FilterManager.GetFilterID(For: _ForFilter)
            FilterPrefix = "\((FilterID)!)_"
        }
    }
    
    /// The ID of the filter.
    private var FilterID: UUID? = nil
    /// The string prefix to use for user defaults.
    private var FilterPrefix: String = ""
    
    /// Holds the fave value for the filter.
    private var _Faved: Bool = false
    /// Get or set the fave value for the filter.
    public var Faved: Bool
    {
        get
        {
            return _Faved
        }
        set
        {
            _Faved = newValue
            SaveRatings()
        }
    }
    
    /// Holds the ratings (in terms of star count) for the filter.
    private var _StarCount: Int = 0
    /// Get or set the rating for the filter.
    public var StarCount: Int
    {
        get
        {
            return _StarCount
        }
        set
        {
            _StarCount = newValue
            SaveRatings()
        }
    }
    
    /// Load settings for this filter from user defaults.
    ///
    /// - Note: If called before the filter type is set, no action takes place.
    func LoadRatings()
    {
        if FilterID == nil
        {
            print("Tried to load filter ratings without knowing which filter to use.")
            return
        }
        let FaveName = FilterPrefix + "Faved"
        _Faved = _Settings.bool(forKey: FaveName)
        let StarName = FilterPrefix + "Stars"
        _StarCount = _Settings.integer(forKey: StarName)
    }
    
    /// Save settings into user defaults.
    ///
    /// - Note: If called before the filter type is set, no action takes place.
    func SaveRatings()
    {
        if FilterID == nil
        {
            print("Tried to save filter ratings without knowing which filter to use.")
            return
        }
        let FaveName = FilterPrefix + "Faved"
        _Settings.set(_Faved, forKey: FaveName)
        let StarName = FilterPrefix + "Stars"
        _Settings.set(_StarCount, forKey: StarName)
    }
}
