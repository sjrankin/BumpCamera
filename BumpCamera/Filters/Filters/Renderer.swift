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
    
    var ID: UUID {get set}
    
    var InstanceID: UUID {get}
    
    var OutputFormatDescription: CMFormatDescription? {get}
    
    var InputFormatDescription: CMFormatDescription? {get}
    
    func Render(PixelBuffer: CVPixelBuffer) -> CVPixelBuffer?

    func Render(Image: UIImage) -> UIImage?

    func Render(Image: CIImage) -> CIImage?
    
    //func Merge(_ Top: CIImage, _ Bottom: CIImage) -> CIImage?
    
    func SupportedFields() -> [FilterManager.InputFields]
    
    func DefaultFieldValue(Field: FilterManager.InputFields) -> (FilterManager.InputTypes, Any?)
    
    func InitializeForImage()
    
    func SettingsStoryboard() -> String?
}

