//
//  FilterManager.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Types of filters that can be run on live views and static images.
///
/// - PassThrough: Filter that does nothing.
/// - Noir: Noir (dramatic black and white) filter.
/// - LineScreen: Line screen - makes images look like old CRT images.
/// - CircularScreen: Circular screen.
/// - DotScreen: Dot screen.
/// - HatchScreen: Hatch screen.
/// - Pixellate: Pixellate.
/// - CircleAndLines: Combination of a line screen and a circular screen.
/// - CMYKHalftone: CMYK halftone filter.
/// - PaletteShifting: Reduce image (via Octree) colors then palette shift.
/// - NotSet: Used to indicate no filter set.
enum FilterNames: Int
{
    case PassThrough = 0
    case Noir = 1
    case LineScreen = 2
    case CircularScreen = 3
    case DotScreen = 4
    case HatchScreen = 5
    case Pixellate = 6
    case CircleAndLines = 7
    case CMYKHalftone = 8
    case PaletteShifting = 9
    case Comic = 10
    case XRay = 11
    case LineOverlay = 12
    case BumpyPixels = 13
    case BumpyTriangles = 14
    case Embossed = 15
    case ColorDelta = 16
    case FilterDelta = 17
    case PatternDelta = 18
    case Mirror = 19
    case NotSet = 1000
}

/// Logical groups of filters.
///
/// - Standard: Standard iOS filters.
/// - Combined: Combination of standard filters.
/// - Bumpy: Bumpy, eg, pseudo-3D filters.
/// - Delta: Filters that show delta values between sequences (eg, videos).
/// - Colors: Filters that show colors in unstandard ways.
/// - Tiles: Filters related to distortions.
/// - NotSet: Used to indicate no group set.
enum FilterGroups: Int
{
    case Standard = 0
    case Combined = 1
    case Bumpy = 2
    case Motion = 3
    case Colors = 4
    case Tiles = 5
    case NotSet = 1000
}

/// Manages the set of filters for the camera and general image processing.
class FilterManager
{
    /// Initialize the class. All filters loaded.
    init()
    {
        PreloadFilters()
    }
    
    init(_ StartingFilter: FilterNames)
    {
        PreloadFilters()
        SetCurrentFilter(Name: StartingFilter)
    }
    
    init(_ StartingFilterValue: Int)
    {
        PreloadFilters()
        if let Start: FilterNames = FilterNames.init(rawValue: StartingFilterValue)
        {
            SetCurrentFilter(Name: Start)
        }
    }
    
    /// Load all of the filter classes into the filter manager.
    private func PreloadFilters()
    {
        for (FilterName, _) in FilterMap
        {
        if let NewRenderer = CreateFilter(For: FilterName)
        {
            let NewCamera = CameraFilter(WithFilter: NewRenderer, AndType: FilterName, ID: FilterMap[FilterName]!)
            FilterList.append(NewCamera)
            NewCamera.Parameters = RenderPacket(ID: FilterMap[FilterName]!)
        }
        }
    }
    
    /// Set the current filter to the specified filter type. Returns the filter (which can also be accessed via
    /// the property CurrentFilter). If the filter hasn't been constructed yet, it will be constructed and added
    /// to the filter list before being returned.
    ///
    /// - Parameter Name: The type of filter to set as the current filter.
    /// - Returns: The new current filter (which may be a pre-existing one). Nil returned on error.
    @discardableResult public func SetCurrentFilter(Name: FilterNames) -> CameraFilter?
    {
        _CurrentFilter = GetFilter(Name: Name)
        return CurrentFilter
    }
    
    private var _CurrentFilter: CameraFilter?
    /// Get the current filter. If nil, either no current filter set (see SetCurrentFilter) or an error occurred.
    public var CurrentFilter: CameraFilter?
    {
        get
        {
            return _CurrentFilter
        }
    }
    
    /// Return the camera filter bundle for the specified filter type.
    ///
    /// - Parameter For: Determines the camera filter to return.
    /// - Returns: The specified camera filter on success, nil if not found.
    public func GetCameraFilter(For: FilterNames) -> CameraFilter?
    {
        return GetFilter(Name: For)
    }
    
    /// Return the parameter block for the specified filter.
    ///
    /// - Parameter For: Determines the filter whose parameter block is returned.
    /// - Returns: The parameter block for the specified filter on success, nil if not found or on error.
    public func GetParameterBlock(For: FilterNames) -> RenderPacket?
    {
        if let Filter = GetCameraFilter(For: For)
        {
            return Filter.Parameters
        }
        return nil
    }
    
    /// Get the type of the current filter. If no filter is set, .NotSet is returned.
    public var CurrentFilterType: FilterNames
    {
        get
        {
            if let Filter = CurrentFilter
            {
                return Filter.FilterType
            }
            return .NotSet
        }
    }
    
    /// Get the specified type of filter. If it does not yet exist, it will be constructed. If the filter is created, it will be
    /// placed in the filter list for reuse purposes.
    ///
    /// - Parameter Name: The type of filter to return.
    /// - Returns: The specified camera filter type on success, nil on error.
    public func GetFilter(Name: FilterNames) -> CameraFilter?
    {
        for Camera in FilterList
        {
            if Camera.FilterType == Name
            {
                return Camera
            }
        }
        if let NewRenderer = CreateFilter(For: Name)
        {
            let NewCamera = CameraFilter(WithFilter: NewRenderer, AndType: Name, ID: FilterMap[Name]!)
            FilterList.append(NewCamera)
            NewCamera.Parameters = RenderPacket(ID: FilterMap[Name]!)
            return NewCamera
        }
        return nil
    }
    
    /// Returns the parameter block for the specified camera type.
    ///
    /// - Parameter For: The filter type whose parameters will be returned.
    /// - Returns: The current set of parameters for the specified filter type. Nil on error.
    public func GetParameters(For: FilterNames) -> RenderPacket?
    {
        for Camera in FilterList
        {
            if Camera.FilterType == For
            {
                return Camera.Parameters
            }
        }
        return nil
    }
    
    /// Creates a filter class for the specified filter type.
    ///
    /// - Parameter For: The type of filter class to create.
    /// - Returns: The newly-created filter class. Nil returned on error.
    private func CreateFilter(For: FilterNames) -> Renderer?
    {
        switch For
        {
        case .CircularScreen:
            return CircularScreen()
            
        case .CMYKHalftone:
            return CMYKHalftone()
            
        case .DotScreen:
            return DotScreen()
            
        case .HatchScreen:
            return HatchScreen()
            
        case .LineScreen:
            return LineScreen()
            
        case .CircleAndLines:
            return CircleAndLines()
            
        case .Noir:
            return Noir()
            
        case .PassThrough:
            return PassThrough()
            
        case .Pixellate:
            return Pixellate()
            
        case .XRay:
            return XRay()
            
        case .Comic:
            return Comic()
            
        case .LineOverlay:
            return LineOverlay()
            
        default:
            return nil
        }
    }
    
    private var _FilterList = [CameraFilter]()
    /// Get or set the list of filters.
    public var FilterList: [CameraFilter]
    {
        get
        {
            return _FilterList
        }
        set
        {
            _FilterList = newValue
        }
    }
    
    /// Return the name of the icon for the specified filter type.
    ///
    /// - Parameter Name: The filter type whose icon name will be returned.
    /// - Returns: The name of the icon on success, empty string if no filter found.
    public func FilterIconName(_ Name: FilterNames) -> String
    {
        if let Camera = GetFilter(Name: Name)
        {
            return (Camera.Filter?.IconName)!
        }
        return ""
    }
    
    /// Return the human-readable title for the specified filter.
    ///
    /// - Parameter Name: The filter type whose title will be returned.
    /// - Returns: The title of the filter on success, empty string if no filter found.
    public func FilterTitle(_ Name: FilterNames) -> String
    {
        if let Camera = GetFilter(Name: Name)
        {
            return (Camera.Filter?.Description)!
        }
        return ""
    }
    
    /// Given a filter, return its ID.
    ///
    /// - Parameter For: The the filter whose ID will be returned.
    /// - Returns: The ID of the passed filter on success, nil if not found.
    public func GetFilterID(For: FilterNames) -> UUID?
    {
        return FilterMap[For]
    }
    
    /// Given a filter ID, return it's description.
    ///
    /// - Parameter ID: ID of the filter whose description will be returned.
    /// - Returns: Description of the filter with the passed ID on success, nil if not found.
    public func GetFilterFrom(ID: UUID) -> FilterNames?
    {
        for (Name, FilterID) in FilterMap
        {
            if FilterID == ID
            {
                return Name
            }
        }
        return nil
    }
    
    /// Map between filter types and filter IDs.
    private let FilterMap: [FilterNames: UUID] =
        [
            .Noir: UUID(uuidString: "7215048f-15ea-46a1-8b11-a03e104a568d")!,
            .LineScreen: UUID(uuidString: "03d25ebe-1536-4088-9af6-150490262467")!,
            .CircularScreen: UUID(uuidString: "43a29cb4-4f85-40a7-b535-3cd659edd3cb")!,
            .DotScreen: UUID(uuidString: "48145942-f695-436a-a9bc-94158d3b469a")!,
            .HatchScreen: UUID(uuidString: "49a3792a-f46a-40c5-8831-51ff7834e8c7")!,
            .Pixellate: UUID(uuidString: "0f56b55b-0d77-4c3a-98eb-cadc62be7f4d")!,
            .CircleAndLines: UUID(uuidString: "0c84fc21-e06a-4b49-ae0e-90594abeeb4a")!,
            .CMYKHalftone: UUID(uuidString: "13c40f19-3d54-492c-92bc-2680f4cf2a2f")!,
            .PassThrough: UUID(uuidString: "e18b32bf-e965-41c6-a1f5-4bb4ed6ba472")!,
            .Comic: UUID(uuidString: "e730f3ba-c4d7-4d06-8754-b878c92260aa")!,
            .XRay: UUID(uuidString: "47d5ac1d-7878-4623-b3df-55559b9d7087")!,
            .LineOverlay: UUID(uuidString: "910d04a3-729d-4fdf-b19e-654904b0eeeb")!,
            .BumpyPixels: UUID(uuidString: "11c13687-8166-4549-a328-cfac37bd7954")!,
            .BumpyTriangles: UUID(uuidString: "72f7bdf9-bf19-4fd6-a37d-c453223b7a2d")!,
            .Embossed: UUID(uuidString: "35c4e25e-5579-4f4a-8a8d-f0d56597226b")!,
            .ColorDelta: UUID(uuidString: "7d35d31b-15bd-4953-a80d-38ef06fceee6")!,
            .FilterDelta: UUID(uuidString: "fc913b9c-8567-4fb2-b2ff-4b1f6e849978")!,
            .PatternDelta: UUID(uuidString: "0ce80007-9d48-4a4f-95ae-0d059a1710c2")!,
            .Mirror: UUID(uuidString: "0ddca374-7a76-4f2e-ae0b-1bca602025a1")!,
            ]
    
    /// Map between group type and filters in the group.
    private let GroupMap: [FilterGroups: [(FilterNames, Int)]] =
    [
        .Standard: [(.PassThrough, 0), (.Noir, 1), (.LineScreen, 4), (.DotScreen, 5), (.CircularScreen, 7),
                    (.HatchScreen, 6), (.CMYKHalftone, 8), (.Pixellate, 9), (.Comic, 2), (.XRay, 3)],
        .Combined: [(.CircleAndLines, 0)],
        .Colors: [(.PaletteShifting, 0)],
        .Bumpy: [(.BumpyPixels, 1), (.BumpyTriangles, 2), (.Embossed, 0)],
        .Motion: [(.ColorDelta, 0), (.FilterDelta, 1), (.PatternDelta, 2)],
        .Tiles: [(.Mirror, 0)],
    ]
    
    /// Map from group descriptions to their respective IDs.
    private let GroupIDs: [FilterGroups: UUID] =
    [
        .Standard: UUID(uuidString: "ce79f6b5-dce4-4280-b291-2b5af6a7f617")!,
        .Combined: UUID(uuidString: "99a6054e-8b60-4c7d-9a7a-3ea8ecacf874")!,
        .Colors: UUID(uuidString: "28cae223-4e86-4d53-b8e9-419e08d9c823")!,
        .Bumpy: UUID(uuidString: "68c21b65-17df-4e18-8231-cac6bb884b85")!,
        .Motion: UUID(uuidString: "75d17717-6daf-4e69-b7f9-ed1a7e3214f0")!,
        .Tiles: UUID(uuidString: "b641cbc9-7ad1-4bdf-9afe-bbf715020525")!
    ]
    
    /// Given a group description, return its ID.
    ///
    /// - Parameter ForGroup: The description of the group whose ID will be returned.
    /// - Returns: The ID of the passed group on success, nil on failure.
    public func GetGroupID(ForGroup: FilterGroups) -> UUID?
    {
        return GroupIDs[ForGroup]
    }
    
    /// Given an ID, return the associated group description.
    ///
    /// - Parameter ID: ID of the group whose description will be returned.
    /// - Returns: The group associated with the passed ID. Nil if not found.
    public func GetGroupFrom(ID: UUID) -> FilterGroups?
    {
        for (Group, GroupID) in GroupIDs
        {
            if GroupID == ID
            {
                return Group
            }
        }
        return nil
    }
    
    /// Map between group type and group name and sort order.
    private let GroupNameMap: [FilterGroups: (String, Int)] =
    [
        .Standard: ("Standard", 0),
        .Combined: ("Combined", 1),
        .Colors: ("Colors", 2),
        .Bumpy: ("3D", 4),
        .Motion: ("Motion", 5),
        .Tiles: ("Distortion", 3),
    ]
    
    /// Map between group type and group color.
    private let GroupColors: [FilterGroups: UIColor] =
    [
        .Standard: UIColor(named: "HoneyDew")!,
        .Combined: UIColor(named: "PastelYellow")!,
        .Colors: UIColor(named: "GreenPastel")!,
        .Tiles: UIColor(named: "LightBlue")!,
        .Bumpy: UIColor(named: "Thistle")!,
        .Motion: UIColor(named: "Gold")!,
    ]
    
    /// Get the color for the specified group. Colors are used as a visual cue for the user to associate filters with given
    /// filter groups.
    ///
    /// - Parameter Group: The group whose color will be returned.
    /// - Returns: The color for the group on success, UIColor.red if the group cannot be found.
    public func ColorForGroup(_ Group: FilterGroups) -> UIColor
    {
        if let GroupColor = GroupColors[Group]
        {
            return GroupColor
        }
        return UIColor.red
    }
    
    /// Return all filters for the specified group.
    ///
    /// - Parameter Group: The group whose filters will be returned.
    /// - Parameter InOrder: Flag that indicates the filter types will be returned in order (as defined internally in this class)
    ///                      or in whatever order the compiler decides when the code is compiled.
    /// - Returns: List of filters for the specified group. If no group found, an empty list is returned.
    public func FiltersForGroup(_ Group: FilterGroups, InOrder: Bool = true) -> [FilterNames]
    {
        if GroupMap[Group] == nil
        {
            return [FilterNames]()
        }
        if !InOrder
        {
            var Final = [FilterNames]()
            for (Name, _) in GroupMap[Group]!
            {
                Final.append(Name)
            }
            return Final
        }
        var Filters = GroupMap[Group]!
        Filters.sort{$0.1 < $1.1}
        let Final = Array(Filters.map{$0.0})
        return Final
    }
    
    /// Return a list of group names (and associated meta data).
    ///
    /// - Returns: List of group names. The data is returned in a tuple in the following order: Group title, Filter group enum,
    ///            sort order.
    public func GetGroupNames() -> [(String, FilterGroups, Int)]
    {
        var Final = [(String, FilterGroups, Int)]()
        for (GroupEnum, (GroupName, SortOrder)) in GroupNameMap
        {
            Final.append((GroupName, GroupEnum, SortOrder))
        }
        return Final
    }
    
    /// Given a filter description, return its title.
    ///
    /// - Parameter Filter: Description of the filter.
    /// - Returns: Title of the filter on success, "No Title" if the filter description cannot be found.
    public func GetFilterTitle(_ Filter: FilterNames) -> String
    {
        if let Title = FilterTitles[Filter]
        {
            return Title
        }
        return "No Title"
    }
    
    /// Map between filter types and their titles.
    private let FilterTitles: [FilterNames: String] =
    [
        .PassThrough: "No Filter",
        .Noir: "Noir",
        .LineScreen: "Line Screen",
        .CircularScreen: "Circular Screen",
        .DotScreen: "Dot Screen",
        .HatchScreen: "Hatch Screen",
        .Pixellate: "Pixelate",
        .CircleAndLines: "Circle and Lines",
        .CMYKHalftone: "CMYK Halftone",
        .PaletteShifting: "Palette Shifting",
        .Comic: "Comic",
        .XRay: "X-Ray",
        .LineOverlay: "Line Overlay",
        .BumpyPixels: "3D Pixelate",
        .BumpyTriangles: "3D Triangles",
        .Embossed: "Embossed",
        .ColorDelta: "Motion Delta",
        .FilterDelta: "Filter Delta",
        .PatternDelta: "Pattern Delta",
        .Mirror: "Reflection"
    ]
    
    /// Implementation map for filter types.
    private let Implemented: [FilterNames: Bool] =
    [
        .PassThrough: true,
        .Noir: true,
        .LineScreen: true,
        .CircularScreen: true,
        .DotScreen: true,
        .HatchScreen: true,
        .Pixellate: true,
        .CircleAndLines: true,
        .CMYKHalftone: true,
        .PaletteShifting: false,
        .Comic: true,
        .XRay: true,
        .LineOverlay: true,
        .BumpyPixels: false,
        .BumpyTriangles: false,
        .Embossed: false,
        .ColorDelta: false,
        .FilterDelta: false,
        .PatternDelta: false,
        .Mirror: false
    ]
    
    /// Map of filter types to parameter existence. A false value means the filter can receive a parameter but it is ignored so
    /// there is no need to pass it or update any of its values.
    private let HasParametersMap: [FilterNames: Bool] =
    [
        .PassThrough: false,
        .Noir: false,
        .LineScreen: true,
        .CircularScreen: true,
        .DotScreen: true,
        .HatchScreen: true,
        .Pixellate: true,
        .CircleAndLines: true,
        .CMYKHalftone: true,
        .PaletteShifting: false,
        .Comic: false,
        .XRay: false,
        .LineOverlay: true,
        .BumpyPixels: false,
        .BumpyTriangles: false,
        .Embossed: false,
        .ColorDelta: false,
        .FilterDelta: false,
        .PatternDelta: false,
        .Mirror: false
    ]
    
    /// Returns a value indicating whether the passed filter has parameters or not. (Technically, all filters have parameters, but
    /// some filters have parameters that are unused.)
    ///
    /// - Parameter Filter: The filter whose parameter existence will be returned.
    /// - Returns: True if the filter has parameters, false if not or no filter found.
    public func FilterHasParameters(_ Filter: FilterNames) -> Bool
    {
        if let HasParameters = HasParametersMap[Filter]
        {
            return HasParameters
        }
        return false
    }
    
    /// Determines if the given filter type is implemented.
    ///
    /// - Parameter FilterType: The filter type to check for implementation status.
    /// - Returns: True if the filter is implemented, false if not or cannot be found.
    public func IsImplemented(_ FilterType: FilterNames) -> Bool
    {
        if let ImplementedFlag = Implemented[FilterType]
        {
            return ImplementedFlag
        }
        return false
    }
    
    /// Returns a list of implemented filters (with each filter represented by its description).
    ///
    /// - Returns: List of implemented filters.
    public func ImplementedFilters() -> [FilterNames]
    {
        var Result = [FilterNames]()
        for (Name, IsImp) in Implemented
        {
            if IsImp
            {
                Result.append(Name)
            }
        }
        return Result
    }
}
