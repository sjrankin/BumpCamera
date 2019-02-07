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

protocol Renderer: class
{
    var Description: String {get}
    
    var Initialized: Bool {get}
    
    var IconName: String {get}
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    
    func Reset(_ CalledBy: String)
    func Reset()
    
    func ID() -> UUID
    
    var InstanceID: UUID {get}
    
    var OutputFormatDescription: CMFormatDescription? {get}
    
    var InputFormatDescription: CMFormatDescription? {get}
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?

    func Render(Image: UIImage) -> UIImage?

    func Render(Image: CIImage) -> CIImage?
    
    func LastImageRendered(AsUIImage: Bool) -> Any?
    
    func SupportedFields() -> [FilterManager.InputFields]
    
    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    
    func InitializeForImage()
    
    func SettingsStoryboard() -> String?
    
    func IsSlow() -> Bool
    
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

