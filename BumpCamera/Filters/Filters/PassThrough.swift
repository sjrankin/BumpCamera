//
//  PassThrough.swift
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

class PassThrough: Renderer
{
    var _ID: UUID = UUID(uuidString: "e18b32bf-e965-41c6-a1f5-4bb4ed6ba472")!
    var ID: UUID
    {
        get
        {
            return _ID
        }
        set
        {
            _ID = newValue
        }
    }
    
    var Description: String = "No Filter"
    
    var Initialized = false
    
    private var PrimaryFilter: CIFilter? = nil
    
    private var SecondaryFilter: CIFilter? = nil
    
    private var Context: CIContext? = nil
    
    private var BufferPool: CVPixelBufferPool? = nil
    
    private var ColorSpace: CGColorSpace? = nil
    
    private(set) var OutputFormatDescription: CMFormatDescription? = nil
    
    private(set) var InputFormatDescription: CMFormatDescription? = nil
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    {
        Reset()
        (BufferPool, ColorSpace, OutputFormatDescription) = CreateBufferPool(From: FormatDescription, BufferCountHint: BufferCountHint)
        if BufferPool == nil
        {
            return
        }
        InputFormatDescription = FormatDescription
        Context = CIContext()
        PrimaryFilter = nil
        Initialized = true
    }
    
    func Reset()
    {
        Context = nil
        PrimaryFilter = nil
        ColorSpace = nil
        BufferPool = nil
        OutputFormatDescription = nil
        InputFormatDescription = nil
        Initialized = false
    }
    
    func Render(PixelBuffer: CVPixelBuffer, Parameters: RenderPacket? = nil) -> CVPixelBuffer?
    {
        return PixelBuffer
    }
    
    func Render(Image: UIImage, Parameters: RenderPacket? = nil) -> UIImage?
    {
        return Image
    }
    
    func Render(Image: CIImage, Parameters: RenderPacket? = nil) -> CIImage?
    {
        return Image
    }
    
    func Merge(_ Top: CIImage, _ Bottom: CIImage) -> CIImage?
    {
        return nil
    }
}
