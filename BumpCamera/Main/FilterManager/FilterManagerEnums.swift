//
//  FilterManagerEnums.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation

extension FilterManager
{
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
    enum FilterTypes: Int
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
        case HueAdjust = 20
        case HSBAdjust = 21
        case ChannelMixer = 22
        case DesaturateColors = 23
        case GrayscaleKernel = 24
        case Kuwahara = 25
        case PixellateMetal = 26
        case Mirroring = 27
        case Grid = 28
        case Solarize = 29
        case Dither = 30
        case Threshold = 31
        case MonochromeColor = 32
        case EdgeWork = 33
        case FalseColor = 34
        case CornerGradient = 35
        case DilateErode = 36
        case Posterize = 37
        case Chrome = 38
        case Instant = 39
        case ProcessEffect = 40
        case TransferEffect = 41
        case SepiaTone = 42
        case BayerDecode = 43
        case Thermal = 44
        case NotSet = 10000
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
        case Effects = 3
        case Motion = 4
        case Colors = 5
        case Tiles = 6
        case Generator = 7
        case Gray = 8
        case PhotoEffects = 9
        case NotSet = 10000
    }
    
    /// Describes where a filter may be applied.
    ///
    /// - Photo: Apply the filter to a photo.
    /// - Video: Apply the filter to a video (or live view).
    enum FilterLocations
    {
        case Photo
        case Video
    }
    
    public enum InputFields: Int
    {
        case InputThreshold = 0
        case InputContrast = 1
        case EdgeIntensity = 2
        case Center = 3
        case Width = 4
        case Angle = 5
        case MergeWithBackground = 6
        case AdjustInLandscape = 7
        case CenterInImage = 8
        case NRSharpness = 9
        case NRNoiseLevel = 10
        case InputSaturation = 11
        case InputBrightness = 12
        case InputCContrast = 13
        case InputHue = 14
        case OutputColorSpace = 15
        case CMYKMap = 16
        case RGBMap = 17
        case HSBMap = 18
        case Normal = 19
        case ChannelOrder = 20
        case RedChannel = 21
        case GreenChannel = 22
        case BlueChannel = 23
        case HueChannel = 25
        case SaturationChannel = 26
        case BrightnessChannel = 27
        case CyanChannel = 28
        case MagentaChannel = 29
        case YellowChannel = 30
        case BlackChannel = 24
        case Command = 31
        case RAdjustment = 32
        case GAdjustment = 33
        case BAdjustment = 34
        case Channel1 = 35
        case Channel2 = 36
        case Channel3 = 37
        case Radius = 38
        case BlockWidth = 39
        case BlockHeight = 40
        case HighlightColor = 41
        case HighlightSaturation = 42
        case HighlightBrightness = 43
        case MirroringDirection = 44
        case HorizontalSide = 45
        case VerticalSide = 46
        case Quadrant = 47
        case GridX = 48
        case GridY = 49
        case GridColor = 50
        case GridBackground = 51
        case InvertColor = 52
        case InvertBackgroundColor = 53
        case LineWidth = 54
        case InvertRed = 55
        case InvertGreen = 56
        case InvertBlue = 57
        case SolarizeMethod = 58
        case SolarizeThreshold = 59
        case HueRangeLow = 60
        case HueRangeHigh = 61
        case BrightnessThreshold = 62
        case SaturationThreshold = 63
        case SolarizeIfGreater = 64
        case ThresholdValue = 65
        case ThresholdInput = 66
        case ApplyThresholdIfHigher = 67
        case LowThresholdColor = 68
        case HighThresholdColor = 69
        case BrightChannels = 70
        case RGBColorspace = 71
        case ForRed = 72
        case ForGreen = 73
        case ForBlue = 74
        case ForCyan = 75
        case ForMagenta = 76
        case ForYellow = 77
        case ForBlack = 78
        case ConditionalPixellation = 79
        case InvertConditionalPixellationRange = 80
        case ConditionalHueRangeLow = 81
        case ConditionalHueRangeHigh = 82
        case ConditionalBrightness = 83
        case ConditionalSaturation = 84
        case ConditionalBackground = 85
        case ConditionalPixellationSelector = 86
        case PixellationHighlighting = 87
        case HueSegmentCount = 88
        case MonochromeColorspace = 89
        case HueSelectedSegment = 90
        case Color0 = 91
        case Color1 = 92
        case ULColor = 93
        case URColor = 94
        case LLColor = 95
        case LRColor = 96
        case HasULColor = 97
        case HasURColor = 98
        case HasLLColor = 99
        case HasLRColor = 100
        case AlphaGradiates = 101
        case WindowSize = 102
        case ValueDetermination = 103
        case Operation = 104
        case PosterizeLevel = 105
        case SepiaToneLevel = 106
        case BayerPattern = 107
        case BayerDecodeMethod = 108
        case RenderImageCount = 109
        case CumulativeImageRenderDuration = 110
        case RenderLiveCount = 111
        case CumulativeLiveRenderDuration = 112
        case NoField = 10000
    }
    
    /// Describes the expected data type for various input fields used as parameters
    /// for filters.
    ///
    /// - DoubleType: Double value.
    /// - IntType: Int value.
    /// - BoolType: Bool value.
    /// - PointType: CGPoint value.
    /// - StringType: String value.
    /// - Normal: Double nominally clamped from 0.0 to 1.0.
    /// - ColorType: UIColor type.
    /// - NoType: No type - returned on error.
    public enum InputTypes: Int
    {
        case DoubleType = 0
        case IntType = 1
        case BoolType = 2
        case PointType = 3
        case StringType = 4
        case Normal = 5
        case ColorType = 6
        case NoType = 1000
    }
    
    /// Describes how the filter was implemented.
    ///
    /// - CIFilter: Filter implemented with a built-in CIFilter.
    /// - Metal: Filter implemented with a custom Metal kernel.
    /// - MPS: Filter implemented with a built-in Metal Performance Shader kernel.
    /// - Accelerate: Filter implemented with the Accelerate framework.
    /// - Software: Filter implemented in code running on the CPU (one hopes not too
    ///             many of these...).
    public enum FilterKernelTypes: Int
    {
        case CIFilter = 0
        case Metal = 1
        case MPS = 2
        case Accelerate = 3
        case Software = 4
    }
}
