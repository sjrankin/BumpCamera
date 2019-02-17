//
//  FilterManager.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Manages the set of filters for the camera and general image processing.
class FilterManager
{
    /// Initialize the class. All filters loaded.
    ///
    /// - Parameter Preload: If true, preload all of the filters.
    init(Preload: Bool = true)
    {
        if Preload
        {
            PreloadFilters()
        }
    }
    
    init(_ StartingFilter: FilterTypes)
    {
        PreloadFilters()
        SetCurrentFilter(FilterType: StartingFilter)
    }
    
    init(_ StartingFilterValue: Int)
    {
        PreloadFilters()
        if let Start: FilterTypes = FilterTypes.init(rawValue: StartingFilterValue)
        {
            SetCurrentFilter(FilterType: Start)
        }
    }
    
    /// Load all of the filter classes into the filter manager.
    private func PreloadFilters()
    {
        FilterSettingsMap = [FilterManager.FilterTypes: String?]()
        for (FilterName, _) in FilterManager.FilterMap
        {
            FilterSettingsMap![FilterName] = nil
            if !IsImplemented(FilterName)
            {
                #if false
                let Raw = FilterName.rawValue
                let Filtered = FilterTypes(rawValue: Raw)
                print("\((Filtered)!) is not implemented.")
                #endif
                continue
            }
            if let NewRenderer = CreateFilter(For: FilterName)
            {
                let NewPhotoCamera = CameraFilter(WithFilter: NewRenderer, AndType: FilterName, ID: FilterManager.FilterMap[FilterName]!)
                NewPhotoCamera.Parameters = RenderPacket(ID: FilterManager.FilterMap[FilterName]!)
                PhotoFilterList.append(NewPhotoCamera)
                let NewVideoCamera = CameraFilter(WithFilter: NewRenderer, AndType: FilterName, ID: FilterManager.FilterMap[FilterName]!)
                NewVideoCamera.Parameters = RenderPacket(ID: FilterManager.FilterMap[FilterName]!)
                VideoFilterList.append(NewVideoCamera)
                FilterSettingsMap![FilterName] = NewRenderer.SettingsStoryboard()
            }
            else
            {
                fatalError("Error creating filter.")
            }
        }
    }
    
    /// Returns the number of parameters for the passed filter type.
    ///
    /// - Parameter Filter: The filter whose number of parameters will be returned.
    /// - Returns: Number of parameters used by the passed filter. 0 if no filter found. (0 may also be returned
    ///            if the filter doesn't have any parameters.)
    public static func ParameterCountFor(_ Filter: FilterManager.FilterTypes) -> Int
    {
        if ParameterCount == nil
        {
            FilterManager.LoadParameterCount()
        }
        if let Count = ParameterCount![Filter]
        {
            return Count
        }
        return 0
    }
    
    /// Load the number of parameters per filter.
    private static func LoadParameterCount()
    {
        ParameterCount = [FilterManager.FilterTypes: Int]()
        
        ParameterCount![.PassThrough] = PassThrough.SupportedFields().count
        ParameterCount![.Noir] = Noir.SupportedFields().count
        ParameterCount![.Pixellate] = Pixellate.SupportedFields().count
        ParameterCount![.PixellateMetal] = Pixellate_Metal.SupportedFields().count
        ParameterCount![.DotScreen] = DotScreen.SupportedFields().count
        ParameterCount![.LineScreen] = LineScreen.SupportedFields().count
        ParameterCount![.HatchScreen] = HatchScreen.SupportedFields().count
        ParameterCount![.CircularScreen] = CircularScreen.SupportedFields().count
        ParameterCount![.CircleAndLines] = CircleAndLines.SupportedFields().count
        ParameterCount![.CMYKHalftone] = CMYKHalftone.SupportedFields().count
        ParameterCount![.LineOverlay] = LineOverlay.SupportedFields().count
        ParameterCount![.ChannelMixer] = ChannelMixer.SupportedFields().count
        ParameterCount![.XRay] = ChannelMixer.SupportedFields().count
        ParameterCount![.DesaturateColors] = DesaturateColors.SupportedFields().count
        ParameterCount![.GrayscaleKernel] = GrayscaleAdjust.SupportedFields().count
        ParameterCount![.Comic] = Comic.SupportedFields().count
        ParameterCount![.Mirroring] = MirroringDistortion.SupportedFields().count
        ParameterCount![.Solarize] = Solarize.SupportedFields().count
        ParameterCount![.Threshold] = Threshold.SupportedFields().count
        ParameterCount![.MonochromeColor] = MonochromeColors.SupportedFields().count
        ParameterCount![.EdgeWork] = EdgeWork.SupportedFields().count
        ParameterCount![.FalseColor] = FalseColor.SupportedFields().count
        ParameterCount![.CornerGradient] = CornerGradient.SupportedFields().count
        ParameterCount![.DilateErode] = DilateErode.SupportedFields().count
        ParameterCount![.Posterize] = Posterize.SupportedFields().count
        ParameterCount![.Chrome] = Chrome.SupportedFields().count
        ParameterCount![.Instant] = Instant.SupportedFields().count
        ParameterCount![.ProcessEffect] = ProcessEffect.SupportedFields().count
        ParameterCount![.TransferEffect] = TransferEffect.SupportedFields().count
        ParameterCount![.SepiaTone] = SepiaTone.SupportedFields().count
        ParameterCount![.BayerDecode] = BayerDecode.SupportedFields().count
    }
    
    private static var ParameterCount: [FilterManager.FilterTypes: Int]? = nil
    
    /// Given a filter type, return the associated settings storyboard.
    ///
    /// - Parameter Filter: The filter type whose storyboard name will be returned.
    /// - Returns: The name of the storyboard on success, nil if not found (or none defined).
    public static func StoryboardFor(_ Filter: FilterTypes) -> String?
    {
        if StoryboardList == nil
        {
            LoadStoryboardList()
        }
        if let ProvisionalName = StoryboardList![Filter]
        {
            return ProvisionalName
        }
        return nil
    }
    
    /// Load all storyboard names into the storyboard list.
    private static func LoadStoryboardList()
    {
        StoryboardList = [FilterManager.FilterTypes: String?]()
        
        StoryboardList![.PassThrough] = PassThrough.SettingsStoryboard()
        StoryboardList![.Noir] = Noir.SettingsStoryboard()
        StoryboardList![.Pixellate] = Pixellate.SettingsStoryboard()
        StoryboardList![.PixellateMetal] = Pixellate_Metal.SettingsStoryboard()
        StoryboardList![.DotScreen] = DotScreen.SettingsStoryboard()
        StoryboardList![.LineScreen] = LineScreen.SettingsStoryboard()
        StoryboardList![.HatchScreen] = HatchScreen.SettingsStoryboard()
        StoryboardList![.CircularScreen] = CircularScreen.SettingsStoryboard()
        StoryboardList![.CircleAndLines] = CircleAndLines.SettingsStoryboard()
        StoryboardList![.CMYKHalftone] = CMYKHalftone.SettingsStoryboard()
        StoryboardList![.LineOverlay] = LineOverlay.SettingsStoryboard()
        StoryboardList![.ChannelMixer] = ChannelMixer.SettingsStoryboard()
        StoryboardList![.XRay] = XRay.SettingsStoryboard()
        StoryboardList![.DesaturateColors] = DesaturateColors.SettingsStoryboard()
        StoryboardList![.GrayscaleKernel] = GrayscaleAdjust.SettingsStoryboard()
        StoryboardList![.Comic] = Comic.SettingsStoryboard()
        StoryboardList![.Mirroring] = MirroringDistortion.SettingsStoryboard()
        StoryboardList![.Grid] = GridGenerator.SettingsStoryboard()
        StoryboardList![.Solarize] = Solarize.SettingsStoryboard()
        StoryboardList![.Threshold] = Threshold.SettingsStoryboard()
        StoryboardList![.MonochromeColor] = MonochromeColors.SettingsStoryboard()
        StoryboardList![.EdgeWork] = EdgeWork.SettingsStoryboard()
        StoryboardList![.FalseColor] = FalseColor.SettingsStoryboard()
        StoryboardList![.CornerGradient] = CornerGradient.SettingsStoryboard()
        StoryboardList![.DilateErode] = DilateErode.SettingsStoryboard()
        StoryboardList![.Posterize] = Posterize.SettingsStoryboard()
        StoryboardList![.Chrome] = Chrome.SettingsStoryboard()
        StoryboardList![.Instant] = Instant.SettingsStoryboard()
        StoryboardList![.ProcessEffect] = ProcessEffect.SettingsStoryboard()
        StoryboardList![.TransferEffect] = TransferEffect.SettingsStoryboard()
        StoryboardList![.SepiaTone] = SepiaTone.SettingsStoryboard()
        StoryboardList![.BayerDecode] = BayerDecode.SettingsStoryboard()
    }
    
    private static var StoryboardList: [FilterTypes: String?]? = nil
    
    public var FilterSettingsMap: [FilterManager.FilterTypes: String?]? = nil
    
    /// Set the current filter to the specified filter type. Calling this function sets both the current video and photo
    /// filters. If the filter isn't in the appropriate filter list, it will be created and added.
    ///
    /// - Parameter FilterType: The type of filter to set as the current filter.
    /// - Returns: True on success, false if the filter cannot be found or is not implemented.
    @discardableResult public func SetCurrentFilter(FilterType: FilterTypes) -> Bool
    {
        if FilterManager.Implemented[FilterType] == nil
        {
            return false
        }
        if !FilterManager.Implemented[FilterType]!
        {
            return false
        }
        if let VF = _VideoFilter
        {
            VF.Filter?.Reset("Video: FilterManager.SetCurrentFilter")
        }
        if let PF = _PhotoFilter
        {
            PF.Filter?.Reset("Photo: FilterManager.SetCurrentFilter")
        }
        _VideoFilter = GetFilter(Name: FilterType, .Video)
        _PhotoFilter = GetFilter(Name: FilterType, .Photo)
        #if true
        print("FilterManager.SetCurrentFilter(\((FilterManager.FilterTitles[FilterType])!))")
        #endif
        return true
    }
    
    private var _VideoFilter: CameraFilter?
    /// Get the current video filter. Set via the SetCurrentFilter function.
    public var VideoFilter: CameraFilter?
    {
        get
        {
            return _VideoFilter
        }
    }
    
    private var _PhotoFilter: CameraFilter?
    /// Get the current photo filter. Set via the SetCurrentFilter function.
    public var PhotoFilter: CameraFilter?
    {
        get
        {
            return _PhotoFilter
        }
    }
    
    /// Return the camera filter bundle for the specified filter type.
    ///
    /// - Parameter For: Determines the camera filter to return.
    /// - Parameter Location: Where the filter will be applied.
    /// - Returns: The specified camera filter on success, nil if not found.
    public func GetCameraFilter(For: FilterTypes, Location: FilterLocations) -> CameraFilter?
    {
        return GetFilter(Name: For, Location)
    }
    
    private var _CurrentPhotoFilterType: FilterTypes = .NotSet
    /// Get the current photo filter type. It's intended to be the same as the current video filter.
    public var CurrentPhotoFilterType: FilterTypes
    {
        get
        {
            return _CurrentPhotoFilterType
        }
    }
    
    private var _CurrentVideoFilterType: FilterTypes = .NotSet
    /// Get the current video filter type. It's intended to be the same as the current photo filter.
    public var CurrentVideoFilterType: FilterTypes
    {
        get
        {
            return _CurrentVideoFilterType
        }
    }
    
    /// Get the specified type of filter. If it does not yet exist, it will be constructed. If the filter is created, it will be
    /// placed in the filter list for reuse purposes.
    ///
    /// - Parameter Name: The type of filter to return.
    /// - Returns: The specified camera filter type on success, nil on error.
    public func GetFilter(Name: FilterTypes, _ For: FilterLocations) -> CameraFilter?
    {
        for Camera in GetFilterList(For: For)
        {
            if Camera.FilterType == Name
            {
                return Camera
            }
        }
        if let NewRenderer = CreateFilter(For: Name)
        {
            let NewCamera = CameraFilter(WithFilter: NewRenderer, AndType: Name,
                                         ID: FilterManager.FilterMap[Name]!)
            switch For
            {
            case .Photo:
                PhotoFilterList.append(NewCamera)
                
            case .Video:
                VideoFilterList.append(NewCamera)
            }
            NewCamera.Parameters = RenderPacket(ID: FilterManager.FilterMap[Name]!)
            return NewCamera
        }
        return nil
    }
    
    public func GetFilterList(For: FilterLocations) -> [CameraFilter]
    {
        switch For
        {
        case .Photo:
            return PhotoFilterList
            
        case .Video:
            return VideoFilterList
        }
    }
    
    /// Creates a filter class for the specified filter type.
    ///
    /// - Parameter For: The type of filter class to create.
    /// - Returns: The newly-created filter class. Nil returned on error.
    public func CreateFilter(For: FilterTypes) -> Renderer?
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
            
        case .HueAdjust:
            return HueAdjust()
            
        case .HSBAdjust:
            return HSBAdjust()
            
        case .DesaturateColors:
            return DesaturateColors()
            
        case .ChannelMixer:
            return ChannelMixer()
            
        case .GrayscaleKernel:
            return GrayscaleAdjust()
            
        case .Kuwahara:
            return KuwaharaEffect()
            
        case .PixellateMetal:
            return Pixellate_Metal()
            
        case .Mirroring:
            return MirroringDistortion()
            
        case .Grid:
            return GridGenerator()
            
        case .Solarize:
            return Solarize()
            
        case .Threshold:
            return Threshold()
            
        case .MonochromeColor:
            return MonochromeColors()
            
        case .EdgeWork:
            return EdgeWork()
            
        case .FalseColor:
            return FalseColor()
            
        case .CornerGradient:
            return CornerGradient()
            
        case .DilateErode:
            return DilateErode()
            
        case .Posterize:
            return Posterize()
            
        case .Chrome:
            return Chrome()
            
        case .Instant:
            return Instant()
            
        case .ProcessEffect:
            return ProcessEffect()
            
        case .TransferEffect:
            return TransferEffect()
            
        case .SepiaTone:
            return SepiaTone()
            
        case .BayerDecode:
            return BayerDecode()
            
        default:
            return nil
        }
    }
    
    private var _PhotoFilterList = [CameraFilter]()
    /// Get or set the list of photo filters.
    public var PhotoFilterList: [CameraFilter]
    {
        get
        {
            return _PhotoFilterList
        }
        set
        {
            _PhotoFilterList = newValue
        }
    }
    
    private var _VideoFilterList = [CameraFilter]()
    /// Get or set the list of video filters.
    public var VideoFilterList: [CameraFilter]
    {
        get
        {
            return _VideoFilterList
        }
        set
        {
            _VideoFilterList = newValue
        }
    }
    
    /// Return the name of the icon for the specified filter type.
    ///
    /// - Parameter Name: The filter type whose icon name will be returned.
    /// - Parameter For: The location of where the filter will be applied.
    /// - Returns: The name of the icon on success, empty string if no filter found.
    public func FilterIconName(_ Name: FilterTypes, _ For: FilterLocations) -> String
    {
        if let Camera = GetFilter(Name: Name, For)
        {
            return (Camera.Filter?.IconName)!
        }
        return ""
    }
    
    /// Return the human-readable title for the specified filter.
    ///
    /// - Parameter Name: The filter type whose title will be returned.
    /// - Parameter For: The location of where the filter will be applied.
    /// - Returns: The title of the filter on success, empty string if no filter found.
    public func FilterTitle(_ Name: FilterTypes, _ For: FilterLocations) -> String
    {
        if let Camera = GetFilter(Name: Name, For)
        {
            return (Camera.Filter?.Description)!
        }
        return ""
    }
    
    /// Given a filter, return its ID.
    ///
    /// - Parameter For: The the filter whose ID will be returned.
    /// - Returns: The ID of the passed filter on success, nil if not found.
    public func GetFilterID(For: FilterTypes) -> UUID?
    {
        return FilterManager.FilterMap[For]
    }
    
    public static func GetFilterID(For: FilterTypes) -> UUID?
    {
        return FilterManager.FilterMap[For]
    }
    
    /// Given a filter ID, return it's type. Instance version.
    ///
    /// - Parameter ID: ID of the filter whose description will be returned.
    /// - Returns: Type of the filter with the passed ID on success, nil if not found.
    public func GetFilterTypeFrom(ID: UUID) -> FilterTypes?
    {
        return FilterManager.GetFilterTypeFrom(ID: ID)
    }
    
    /// Given a filter ID, return it's type. Static version.
    ///
    /// - Parameter ID: ID of the filter whose description will be returned.
    /// - Returns: Type of the filter with the passed ID on success, nil if not found.
    public static func GetFilterTypeFrom(ID: UUID) -> FilterTypes?
    {
        for (Name, FilterID) in FilterManager.FilterMap
        {
            if FilterID == ID
            {
                return Name
            }
        }
        return nil
    }
    
    /// Map between filter types and filter IDs.
    static let FilterMap: [FilterTypes: UUID] =
        [
            .Noir: Noir.ID(),
            .LineScreen: LineScreen.ID(),
            .CircularScreen: CircularScreen.ID(),
            .DotScreen: DotScreen.ID(),
            .HatchScreen: HatchScreen.ID(),
            .Pixellate: Pixellate.ID(),
            .CircleAndLines: CircleAndLines.ID(),
            .CMYKHalftone: CMYKHalftone.ID(),
            .PassThrough: PassThrough.ID(),
            .Comic: Comic.ID(),
            .XRay: XRay.ID(),
            .LineOverlay: LineOverlay.ID(),
            /*
             .BumpyPixels: BumpyPixels.ID(),
             .BumpyTriangles: BumpyTriangles.ID(),
             .Embossed: Embossed.ID(),
             .ColorDelta: ColorDelta.ID(),
             .FilterDelta: FilterDelta.ID(),
             .PatternDelta: PatternDelta.ID(),
             */
            .HueAdjust: HueAdjust.ID(),
            .HSBAdjust: HSBAdjust.ID(),
            .ChannelMixer: ChannelMixer.ID(),
            .DesaturateColors: DesaturateColors.ID(),
            .GrayscaleKernel: GrayscaleAdjust.ID(),
            .Kuwahara: KuwaharaEffect.ID(),
            .PixellateMetal: Pixellate_Metal.ID(),
            .Mirroring: MirroringDistortion.ID(),
            .Grid: GridGenerator.ID(),
            .Solarize: Solarize.ID(),
            .Threshold: Threshold.ID(),
            .Dither: Dithering.ID(),
            .MonochromeColor: MonochromeColors.ID(),
            .EdgeWork: EdgeWork.ID(),
            .FalseColor: FalseColor.ID(),
            .CornerGradient: CornerGradient.ID(),
            .DilateErode: DilateErode.ID(),
            .Posterize: Posterize.ID(),
            .Chrome: Chrome.ID(),
            .Instant: Instant.ID(),
            .ProcessEffect: ProcessEffect.ID(),
            .TransferEffect: TransferEffect.ID(),
            .SepiaTone: SepiaTone.ID(),
            .BayerDecode: BayerDecode.ID(),
            ]
    
    /// Map between group type and filters in the group.
    private static let GroupMap: [FilterGroups: [(FilterTypes, Int)]] =
        [
            .Standard: [(.PassThrough, 0), (.LineScreen, 4), (.DotScreen, 5), (.CircularScreen, 7),
                        (.HatchScreen, 6), (.CMYKHalftone, 8), (.Pixellate, 11), (.Comic, 2),
                        (.LineOverlay, 9), (.EdgeWork, 10), (.Posterize, 13)],
            .Combined: [(.CircleAndLines, 0)],
            .Effects: [(.PixellateMetal, 0), (.DilateErode, 1), (.Kuwahara, 2), (.BayerDecode, 3)],
            .PhotoEffects: [(.Noir, 0), (.Chrome, 1), (.XRay, 2), (.Instant, 2), (.ProcessEffect, 3),
                            (.TransferEffect, 4), (.SepiaTone, 5)],
            .Colors: [(.HueAdjust, 0), (.HSBAdjust, 1), (.Solarize, 2), (.ChannelMixer, 3),
                      (.DesaturateColors, 4), (.Threshold, 5), (.MonochromeColor, 6), (.FalseColor, 7),
                      (.PaletteShifting, 8)],
            .Gray: [(.GrayscaleKernel, 0), (.Dither, 1)],
            //.Bumpy: [(.BumpyPixels, 1), (.BumpyTriangles, 2), (.Embossed, 0)],
            //.Motion: [(.ColorDelta, 0), (.FilterDelta, 1), (.PatternDelta, 2)],
            .Tiles: [(.Mirroring, 0)],
            .Generator: [(.Grid, 0), (.CornerGradient, 1)]
    ]
    
    /// Map from group descriptions to their respective IDs.
    static let GroupIDs: [FilterGroups: UUID] =
        [
            .Standard: UUID(uuidString: "ce79f6b5-dce4-4280-b291-2b5af6a7f617")!,
            .Combined: UUID(uuidString: "99a6054e-8b60-4c7d-9a7a-3ea8ecacf874")!,
            .Colors: UUID(uuidString: "28cae223-4e86-4d53-b8e9-419e08d9c823")!,
            .Bumpy: UUID(uuidString: "68c21b65-17df-4e18-8231-cac6bb884b85")!,
            .Motion: UUID(uuidString: "75d17717-6daf-4e69-b7f9-ed1a7e3214f0")!,
            .Tiles: UUID(uuidString: "b641cbc9-7ad1-4bdf-9afe-bbf715020525")!,
            .Effects: UUID(uuidString: "fae8b7f3-db91-47c9-8599-7227ef0d9fdb")!,
            .Generator: UUID(uuidString: "fc757ea9-8300-47a9-9fa0-0855d86100bb")!,
            .Gray: UUID(uuidString: "d004805c-4571-40d1-b2af-fb6d9b680816")!,
            .PhotoEffects: UUID(uuidString: "a8a857f4-ddbf-4fbb-a998-e48395f3ca10")!,
            ]
    
    /// Given a group description, return its ID.
    ///
    /// - Parameter ForGroup: The description of the group whose ID will be returned.
    /// - Returns: The ID of the passed group on success, nil on failure.
    public func GetGroupID(ForGroup: FilterGroups) -> UUID?
    {
        return FilterManager.GroupIDs[ForGroup]
    }
    
    public static func GetGroupID(ForGroup: FilterGroups) -> UUID?
    {
        return GroupIDs[ForGroup]
    }
    
    /// Given a group ID, return the associated group description.
    ///
    /// - Parameter ID: ID of the group whose description will be returned.
    /// - Returns: The group associated with the passed ID. Nil if not found.
    public static func GetGroupFrom(ID: UUID) -> FilterGroups?
    {
        for (Group, GroupID) in FilterManager.GroupIDs
        {
            if GroupID == ID
            {
                return Group
            }
        }
        return nil
    }
    
    public func GetGroupFrom(ID: UUID) -> FilterGroups?
    {
        return FilterManager.GetGroupFrom(ID: ID)
    }
    
    public static func GroupFromFilter(Type: FilterTypes) -> FilterGroups?
    {
        for (GroupType, FiltersInGroup) in GroupMap
        {
            for (FilterType, _) in FiltersInGroup
            {
                if FilterType == Type
                {
                    return GroupType
                }
            }
        }
        return nil
    }
    
    public static func GroupFromFilter(ID: UUID) -> FilterGroups?
    {
        if let FilterType = GetFilterTypeFrom(ID: ID)
        {
            return GroupFromFilter(Type: FilterType)
        }
        return nil
    }
    
    /// Map between group type and group name and sort order.
    private static let GroupNameMap: [FilterGroups: (String, Int)] =
        [
            .Standard: ("Standard", 0),
            .Combined: ("Combined", 1),
            .Colors: ("Colors", 2),
            .Effects: ("Effects", 4),
            .Bumpy: ("3D", 7),
            .Motion: ("Motion", 8),
            .Tiles: ("Distortion", 6),
            .Generator: ("Generators", 9),
            .Gray: ("Mono- chrome", 3),
            .PhotoEffects: ("Photo Effects", 5),
            ]
    
    /// Map between group type and group color.
    private static let GroupColors: [FilterGroups: UIColor] =
        [
            .Standard: UIColor(named: "HoneyDew")!,
            .Combined: UIColor(named: "PastelYellow")!,
            .Colors: UIColor(named: "GreenPastel")!,
            .Effects: UIColor(named: "PinkPastel")!,
            .PhotoEffects: UIColor.orange,
            .Tiles: UIColor(named: "LightBlue")!,
            .Bumpy: UIColor(named: "Thistle")!,
            .Motion: UIColor(named: "Gold")!,
            .Generator: UIColor(named: "Mauve")!,
            .Gray: UIColor(named: "PaleGray")!,
            ]
    
    public func ColorForGroup(_ Group: FilterGroups) -> UIColor
    {
        return FilterManager.ColorForGroup(Group)
    }
    
    /// Get the color for the specified group. Colors are used as a visual cue for the user to associate filters with given
    /// filter groups.
    ///
    /// - Parameter Group: The group whose color will be returned.
    /// - Returns: The color for the group on success, UIColor.red if the group cannot be found.
    public static func ColorForGroup(_ Group: FilterGroups) -> UIColor
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
    public static func FiltersForGroup(_ Group: FilterGroups, InOrder: Bool = true) -> [FilterTypes]
    {
        if FilterManager.GroupMap[Group] == nil
        {
            return [FilterTypes]()
        }
        if !InOrder
        {
            var Final = [FilterTypes]()
            for (Name, _) in FilterManager.GroupMap[Group]!
            {
                Final.append(Name)
            }
            return Final
        }
        var Filters = FilterManager.GroupMap[Group]!
        Filters.sort{$0.1 < $1.1}
        let Final = Array(Filters.map{$0.0})
        return Final
    }
    
    public func FiltersForGroup(_ Group: FilterGroups, InOrder: Bool = true) -> [FilterTypes]
    {
        return FilterManager.FiltersForGroup(Group, InOrder: InOrder)
    }
    
    /// Return a list of group names (and associated meta data).
    ///
    /// - Returns: List of group names. The data is returned in a tuple in the following order: Group title, Filter group type,
    ///            sort order.
    public func GetGroupNames() -> [(String, FilterGroups, Int)]
    {
        return FilterManager.GetGroupNames()
    }
    
    public static func GetGroupNames() -> [(String, FilterGroups, Int)]
    {
        var Final = [(String, FilterGroups, Int)]()
        for (GroupType, (GroupName, SortOrder)) in GroupNameMap
        {
            Final.append((GroupName, GroupType, SortOrder))
        }
        return Final
    }
    
    /// Return a list of filters for a given group. Included in the returned list are titles, sort order, and implementation status.
    ///
    /// - Parameter ForGroup: The group whose filter data will be returned.
    /// - Returns: List of filters for the specified group in order of: Title, Filter Type, Sort Order, Implementation Status.
    public func GetFilterData(ForGroup: FilterGroups) -> [(String, FilterTypes, Int, Bool)]
    {
        var Final = [(String, FilterTypes, Int, Bool)]()
        if let FiltersInGroup = FilterManager.GroupMap[ForGroup]
        {
            for (GroupFilter, SortOrder) in FiltersInGroup
            {
                let FilterTitle = FilterManager.FilterTitles[GroupFilter]
                let ImplementationFlag = IsImplemented(GroupFilter)
                Final.append((FilterTitle!, GroupFilter, SortOrder, ImplementationFlag))
            }
        }
        return Final
    }
    
    /// Given a filter description, return its title.
    ///
    /// - Parameter Filter: Description of the filter.
    /// - Returns: Title of the filter on success, "No Title" if the filter description cannot be found.
    public func GetFilterTitle(_ Filter: FilterTypes) -> String
    {
        if let Title = FilterManager.GetFilterTitle(Filter)
        {
            return Title
        }
        return "No Title"
    }
    
    /// Given a filter's ID, return its title.
    ///
    /// - Parameter FilterID: ID of the filter whose title will be returned.
    /// - Returns: Title of the filter on success, "No Title" if the filter cannot be found.
    public func GetFilterTitle(_ FilterID: UUID) -> String
    {
        if let FilterType = GetFilterTypeFrom(ID: FilterID)
        {
            return GetFilterTitle(FilterType)
        }
        return "No Title"
    }
    
    /// Map between filter types and their titles.
    private static let FilterTitles: [FilterTypes: String] =
        [
            .PassThrough: "Pass Through",
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
            .Mirroring: "Reflection",
            .HueAdjust: "Hue Settings",
            .HSBAdjust: "Color Settings",
            .ChannelMixer: "Channel Mixer",
            .DesaturateColors: "Desaturate Colors",
            .GrayscaleKernel: "Grayscale",
            .Kuwahara: "Kuwahara",
            .PixellateMetal: "Pixellate Metal",
            .Grid: "Grid Generator",
            .Dither: "Dithing",
            .Solarize: "Solarize",
            .Threshold: "Threshold",
            .MonochromeColor: "Mono- Colors",
            .EdgeWork: "Edge Work",
            .FalseColor: "False Color",
            .CornerGradient: "Corner Gradient",
            .DilateErode: "Dilate & Erode",
            .Posterize: "Posterize",
            .Chrome: "Chrome",
            .Instant: "Instant Photo",
            .ProcessEffect: "Process Effect",
            .TransferEffect: "Transfer Effect",
            .SepiaTone: "Sepia Tone",
            .BayerDecode: "Bayer Decode",
            ]
    
    public static func GetFilterTitle(_ Filter: FilterTypes) -> String?
    {
        if let Title = FilterTitles[Filter]
        {
            return Title
        }
        return nil
    }
    
    /// Implementation map for filter types.
    private static let Implemented: [FilterTypes: Bool] =
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
            .Mirroring: true,
            .HueAdjust: true,
            .HSBAdjust: true,
            .ChannelMixer: true,
            .DesaturateColors: true,
            .GrayscaleKernel: true,
            .Kuwahara: true,
            .PixellateMetal: true,
            .Grid: true,
            .Threshold: true,
            .Dither: false,
            .Solarize: true,
            .MonochromeColor: true,
            .EdgeWork: true,
            .FalseColor: true,
            .CornerGradient: false,
            .DilateErode: true,
            .Posterize: true,
            .Chrome: true,
            .Instant: true,
            .ProcessEffect: true,
            .TransferEffect: true,
            .SepiaTone: true,
            .BayerDecode: true,
            ]
    
    /// Determines if the given filter type is implemented.
    ///
    /// - Parameter FilterType: The filter type to check for implementation status.
    /// - Returns: True if the filter is implemented, false if not or cannot be found.
    public func IsImplemented(_ FilterType: FilterTypes) -> Bool
    {
        return FilterManager.IsImplemented(FilterType)
    }
    
    /// Determines if the given filter type is implemented.
    ///
    /// - Parameter FilterType: The filter type to check for implementation status.
    /// - Returns: True if the filter is implemented, false if not or cannot be found.
    public static func IsImplemented(_ FilterType: FilterTypes) -> Bool
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
    public func ImplementedFilters() -> [FilterTypes]
    {
        var Result = [FilterTypes]()
        for (Name, IsImp) in FilterManager.Implemented
        {
            if IsImp
            {
                Result.append(Name)
            }
        }
        return Result
    }
    
    public static let FieldMap: [InputFields: InputTypes] =
        [
            .InputThreshold: .DoubleType,
            .InputContrast: .DoubleType,
            .EdgeIntensity: .DoubleType,
            .Center: .PointType,
            .Width: .DoubleType,
            .Angle: .DoubleType,
            .MergeWithBackground: .BoolType,
            .AdjustInLandscape: .BoolType,
            .CenterInImage: .BoolType,
            .NRSharpness: .DoubleType,
            .NRNoiseLevel: .DoubleType,
            .InputSaturation: .DoubleType,
            .InputBrightness: .DoubleType,
            .InputCContrast: .DoubleType,
            .InputHue: .DoubleType,
            .OutputColorSpace: .IntType,
            .RGBMap: .StringType,
            .HSBMap: .StringType,
            .CMYKMap: .StringType,
            .Normal: .Normal,
            .ChannelOrder: .IntType,
            .RedChannel: .IntType,
            .GreenChannel: .IntType,
            .BlueChannel: .IntType,
            .HueChannel: .IntType,
            .SaturationChannel: .IntType,
            .BrightnessChannel: .IntType,
            .CyanChannel: .IntType,
            .MagentaChannel: .IntType,
            .YellowChannel: .IntType,
            .BlackChannel: .IntType,
            .Command: .IntType,
            .RAdjustment: .DoubleType,
            .GAdjustment: .DoubleType,
            .BAdjustment: .DoubleType,
            .Channel1: .IntType,
            .Channel2: .IntType,
            .Channel3: .IntType,
            .Radius: .DoubleType,
            .BlockWidth: .IntType,
            .BlockHeight: .IntType,
            .HighlightColor: .BoolType,
            .HighlightSaturation: .BoolType,
            .HighlightBrightness: .BoolType,
            .MirroringDirection: .IntType,
            .HorizontalSide: .IntType,
            .VerticalSide: .IntType,
            .Quadrant: .IntType,
            .GridX: .IntType,
            .GridY: .IntType,
            .GridColor: .ColorType,
            .GridBackground: .ColorType,
            .InvertColor: .BoolType,
            .InvertBackgroundColor: .BoolType,
            .LineWidth: .IntType,
            .InvertRed: .BoolType,
            .InvertGreen: .BoolType,
            .InvertBlue: .BoolType,
            .SolarizeMethod: .IntType,
            .SolarizeThreshold: .DoubleType,
            .HueRangeLow: .DoubleType,
            .HueRangeHigh: .DoubleType,
            .BrightnessThreshold: .DoubleType,
            .SaturationThreshold: .DoubleType,
            .SolarizeIfGreater: .BoolType,
            .ThresholdValue: .DoubleType,
            .ThresholdInput: .IntType,
            .ApplyThresholdIfHigher: .BoolType,
            .LowThresholdColor: .ColorType,
            .HighThresholdColor: .ColorType,
            .BrightChannels: .BoolType,
            .RGBColorspace: .BoolType,
            .ForRed: .BoolType,
            .ForGreen: .BoolType,
            .ForBlue: .BoolType,
            .ForCyan: .BoolType,
            .ForMagenta: .BoolType,
            .ForYellow: .BoolType,
            .ForBlack: .BoolType,
            .ConditionalPixellation: .BoolType,
            .InvertConditionalPixellationRange: .BoolType,
            .ConditionalHueRangeLow: .DoubleType,
            .ConditionalHueRangeHigh: .DoubleType,
            .ConditionalBrightness: .DoubleType,
            .ConditionalSaturation: .DoubleType,
            .ConditionalBackground: .IntType,
            .ConditionalPixellationSelector: .IntType,
            .PixellationHighlighting: .IntType,
            .HueSegmentCount: .IntType,
            .MonochromeColorspace: .IntType,
            .HueSelectedSegment: .IntType,
            .Color0: .ColorType,
            .Color1: .ColorType,
            .ULColor: .ColorType,
            .URColor: .ColorType,
            .LLColor: .ColorType,
            .LRColor: .ColorType,
            .HasULColor: .BoolType,
            .HasURColor: .BoolType,
            .HasLLColor: .BoolType,
            .HasLRColor: .BoolType,
            .AlphaGradiates: .BoolType,
            .WindowSize: .IntType,
            .ValueDetermination: .IntType,
            .Operation: .IntType,
            .PosterizeLevel: .IntType,
            .SepiaToneLevel: .DoubleType,
            .BayerPattern: .IntType,
            .BayerDecodeMethod: .IntType,
            ]
    
    public static let FieldStorageMap: [InputFields: String] =
        [
            .InputThreshold: "_InputThreshold",
            .InputContrast: "_InputContrast",
            .EdgeIntensity: "_EdgeIntensity",
            .Center: "_Center",
            .Width: "_Width",
            .Angle: "_Angle",
            .MergeWithBackground: "_MergeWithBackground",
            .AdjustInLandscape: "_AdjustInLandscape",
            .CenterInImage: "_CenterInImage",
            .NRSharpness: "_NRSharpness",
            .NRNoiseLevel: "_NRNoiseLevel",
            .InputSaturation: "_InputSaturation",
            .InputBrightness: "_InputBrightness",
            .InputCContrast: "_InputColorContrast",
            .InputHue: "_InputHue",
            .OutputColorSpace: "_OutputColorSpace",
            .RGBMap: "_RGBMap",
            .HSBMap: "_HSBMap",
            .CMYKMap: "_CMYKMap",
            .Normal: "_Normal",
            .ChannelOrder: "_ChannelOrder",
            .RedChannel: "_RedChannel",
            .GreenChannel: "_GreenChannel",
            .BlueChannel: "_BlueChannel",
            .HueChannel: "_HueChannel",
            .SaturationChannel: "_SaturationChannel",
            .BrightnessChannel: "_BrightnessChannel",
            .CyanChannel: "_CyanChannel",
            .MagentaChannel: "_MagentaChannel",
            .YellowChannel: "_YellowChannel",
            .BlackChannel: "_BlackChannel",
            .Command: "_Command",
            .RAdjustment: "_RAdjustment",
            .GAdjustment: "_GAdjustment",
            .BAdjustment: "_BAdjustment",
            .Channel1: "_Channel1",
            .Channel2: "_Channel2",
            .Channel3: "_Channel3",
            .Radius: "_Radius",
            .BlockWidth: "_BlockWidth",
            .BlockHeight: "_BlockHeight",
            .HighlightColor: "_HighlightColor",
            .HighlightSaturation: "_HighlightSaturation",
            .HighlightBrightness: "_HighlightBrightness",
            .MirroringDirection: "_MirrorDirection",
            .HorizontalSide: "_HorizontalSide",
            .VerticalSide: "_VerticalSide",
            .Quadrant: "_Quadrant",
            .GridX: "_GridX",
            .GridY: "_GridY",
            .GridColor: "_GridColor",
            .GridBackground: "_GridBackground",
            .InvertColor: "_InvertGridColor",
            .InvertBackgroundColor: "_InvertSourceColor",
            .LineWidth: "_LineWidth",
            .InvertRed: "_InvertRed",
            .InvertGreen: "_InvertGreen",
            .InvertBlue: "_InvertBlue",
            .SolarizeMethod: "_Method",
            .SolarizeThreshold: "_Threshold",
            .HueRangeLow: "_HueRange:Low",
            .HueRangeHigh: "_HueRange:High",
            .BrightnessThreshold: "_BrightnessThreshold",
            .SaturationThreshold: "_SaturationThreshold",
            .SolarizeIfGreater: "_SolarizeIfGreater",
            .ThresholdValue: "_Threshold",
            .ThresholdInput: "_ThresholdInput",
            .LowThresholdColor: "_LowThresholdColor",
            .HighThresholdColor: "_HighThresholdColor",
            .ApplyThresholdIfHigher: "_ApplyIfHigher",
            .BrightChannels: "_UseBrightChannels",
            .RGBColorspace: "_RGBColorspace",
            .ForRed: "_ForRed",
            .ForGreen: "_ForGreen",
            .ForBlue: "_ForBlue",
            .ForCyan: "_ForCyan",
            .ForMagenta: "_ForMagenta",
            .ForYellow: "_ForYellow",
            .ForBlack: "_ForBlack",
            .ConditionalPixellation: "_ConditionalPixellation",
            .InvertConditionalPixellationRange: "_InvertConditionalPixellationValue",
            .ConditionalHueRangeLow: "_CondPixHueLow",
            .ConditionalHueRangeHigh: "_CondPixHueHigh",
            .ConditionalBrightness: "_CondPixBright",
            .ConditionalSaturation: "_CondPixSat",
            .ConditionalBackground: "_CondBackType",
            .ConditionalPixellationSelector: "_ConditionOn",
            .PixellationHighlighting: "_PixellationHighlighting",
            .HueSegmentCount: "_HueSegmentCount",
            .MonochromeColorspace: "_MonochromeColorspace",
            .HueSelectedSegment: "_HueIndex",
            .Color0: "_Color0",
            .Color1: "_Color1",
            .ULColor: "_ULColor",
            .URColor: "_URcolor",
            .LLColor: "_LLColor",
            .LRColor: "_LRColor",
            .HasULColor: "_HasULColor",
            .HasURColor: "_HasURColor",
            .HasLLColor: "_HasLLColor",
            .HasLRColor: "_HasLRColor",
            .AlphaGradiates: "_IncludeAlpha",
            .WindowSize: "_WindowSize",
            .ValueDetermination: "_ValueDetermination",
            .Operation: "_FilterOperation",
            .PosterizeLevel: "_PosterizeLevel",
            .SepiaToneLevel: "_SepiaToneLevel",
            .BayerPattern: "_SourceBayerPattern",
            .BayerDecodeMethod: "_BayerDecodeMethod",
            ]
}

