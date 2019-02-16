//
//  Renderer.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreVideo
import CoreImage

/// Protocol for filter wrapper classes.
protocol Renderer: class
{
    /// Get a description of the filter.
    var Description: String {get}
    
    /// Get the initialized flag for the filter.
    var Initialized: Bool {get}
    
    /// Get the icon name for the filter.
    var IconName: String {get}
    
    /// Initialize the filter.
    ///
    /// - Parameters:
    ///   - FormatDescription: Format of the pixel buffer.
    ///   - BufferCountHint: Number of buffers to keep in the buffer pool.
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    
    /// Reset the filter. After calling this function, Initialize must be called again before using the filter.
    ///
    /// - Parameter CalledBy: Description of who called this function. Used for debugging.
    func Reset(_ CalledBy: String)
    
    /// Reset the filter. After calling this function, Initialize must be called again before using the filter.
    func Reset()
    
    /// Returns the ID of the filter. (Static version also available.) The ID of the filter is guarenteed to remain
    /// the same across app sessions.
    func ID() -> UUID
    
    /// Get the instance ID of the filter. This ID will change for each app session.
    var InstanceID: UUID {get}
    
    /// Get the pixel format description for the output buffer.
    var OutputFormatDescription: CMFormatDescription? {get}
    
    /// Get the pixel format description for the input buffer.
    var InputFormatDescription: CMFormatDescription? {get}
    
    /// Render the image with the filter.
    ///
    /// - Parameter PixelBuffer: Pixel buffer of the image that is the source for the filter.
    /// - Returns: Pixel buffer of the result of the filtering operation.
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?

    /// Render the image with the filter.
    ///
    /// - Parameter Image: The UIImage that is the source for the filter.
    /// - Returns: UIImage with the result of the filtering operation. Returned image is CGImage-backed, which makes it
    ///            a lot easier to use built-in APIs to save it.
    func Render(Image: UIImage) -> UIImage?

    /// Render the image with the filter.
    ///
    /// - Parameter Image: The CIImage that is the source for the filter.
    /// - Returns: CIImage with the result of the filtering operation. Returned image is CGImage-backed, which makes it
    ///            a lot easier to use built-in APIs to save it.
    func Render(Image: CIImage) -> CIImage?
    
    /// Return the last image rendered with either Render(:UIImage) or Render(:CIImage).
    ///
    /// - Parameter AsUIImage: Determines the format of the returned image. If true, the image returned is a UIImage.
    ///                        Otherwise, the image is a CIImage.
    /// - Returns: The last image rendered by Render(:UIImage) or Render(:CIImage). If no image was previously rendered,
    ///            nil is returned.
    func LastImageRendered(AsUIImage: Bool) -> Any?
    
    /// Returns a list of supported/required input fields. Also available as a static function. These fields are read
    /// from user settings at run time and sent to the filters to control how they operate.
    ///
    /// - Returns: List of supported/required input fields.
    func SupportedFields() -> [FilterManager.InputFields]
    
    /// Returns a list of default values for the supported/required input fields. This is used when the app first runs on
    /// the user's device to set up standard (and reasonable) default values in user settings.
    ///
    /// - Parameter Field: The field type whose input type and default value will be returned.
    /// - Returns: Tuple of the field's type and default value on success, value indicating no type and nil on failure.
    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    
    /// Initialize the filter for image processing. Call this for still image processing, not live view processing.
    func InitializeForImage()
    
    /// Returns the name of the storyboard to use to let the user change settings for the filter. Also available as
    /// a static function.
    ///
    /// - Returns: Name of the storyboard to use to let the user change settings. Nil if no storyboard available.
    func SettingsStoryboard() -> String?
    
    /// Flag that indicates whether the filter is "slow" or not.
    ///
    /// - Returns: True if the filter is "slow," false if it has reasonable performance.
    func IsSlow() -> Bool
    
    /// Returns a list of valid targets to use the filter on. See FilterTargets for list and description. Filters should be used
    /// only on targets in this list.
    ///
    /// - Returns: List of valid filter targets.
    func FilterTarget() -> [FilterTargets]
}

/// Valid targets for the various filters. A target is something the filter can reasonably process, where "reasonable" means
/// won't take a long time.
///
/// - Still: Image files.
/// - Video: Video files.
/// - LiveView: Live view scene.
enum FilterTargets
{
    case Still
    case Video
    case LiveView
}

