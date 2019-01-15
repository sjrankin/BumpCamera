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
    
    func Initialize(With FormatDescription: CMFormatDescription, BufferCountHint: Int)
    
    func Reset()
    
    var ID: UUID {get set}
    
    var OutputFormatDescription: CMFormatDescription? {get}
    
    var InputFormatDescription: CMFormatDescription? {get}
    
    func Render(PixelBuffer: CVPixelBuffer, Parameters: RenderPacket?) -> CVPixelBuffer?
    
    func Render(Image: UIImage, Parameters: RenderPacket?) -> UIImage?
    
    func Render(Image: CIImage, Parameters: RenderPacket?) -> CIImage?
    
    func Merge(_ Top: CIImage, _ Bottom: CIImage) -> CIImage?
}

func CreateBufferPool(From: CMFormatDescription, BufferCountHint: Int) ->
    (BufferPool: CVPixelBufferPool?, ColorSpace: CGColorSpace?, FormatDescription: CMFormatDescription?)
{
    let InputSubType = CMFormatDescriptionGetMediaSubType(From)
    if InputSubType != kCVPixelFormatType_32BGRA
    {
        print("Invalid pixel buffer type \(InputSubType)")
        return (nil, nil, nil)
    }
    
    let InputSize = CMVideoFormatDescriptionGetDimensions(From)
    var PixelBufferAttrs: [String: Any] =
        [
            kCVPixelBufferPixelFormatTypeKey as String: UInt(InputSubType),
            kCVPixelBufferWidthKey as String: Int(InputSize.width),
            kCVPixelBufferHeightKey as String: Int(InputSize.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]
    
    var GColorSpace = CGColorSpaceCreateDeviceRGB()
    if let FromEx = CMFormatDescriptionGetExtensions(From) as Dictionary?
    {
        let ColorPrimaries = FromEx[kCVImageBufferColorPrimariesKey]
        if let ColorPrimaries = ColorPrimaries
        {
            var ColorSpaceProps: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: ColorPrimaries]
            if let YCbCrMatrix = FromEx[kCVImageBufferYCbCrMatrixKey]
            {
                ColorSpaceProps[kCVImageBufferYCbCrMatrixKey as String] = YCbCrMatrix
            }
            if let XferFunc = FromEx[kCVImageBufferTransferFunctionKey]
            {
                ColorSpaceProps[kCVImageBufferTransferFunctionKey as String] = XferFunc
            }
            PixelBufferAttrs[kCVBufferPropagatedAttachmentsKey as String] = ColorSpaceProps
        }
        if let CVColorSpace = FromEx[kCVImageBufferCGColorSpaceKey]
        {
            GColorSpace = CVColorSpace as! CGColorSpace
        }
        else
        {
            if (ColorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String)
            {
                GColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
            }
        }
    }
    
    let PoolAttrs = [kCVPixelBufferPoolMinimumBufferCountKey as String: BufferCountHint]
    var CVPixBufPool: CVPixelBufferPool?
    CVPixelBufferPoolCreate(kCFAllocatorDefault, PoolAttrs as NSDictionary?,
                            PixelBufferAttrs as NSDictionary?,
                            &CVPixBufPool)
    guard let BufferPool = CVPixBufPool else
    {
        print("Allocation failure - could not allocate pixel buffer pool.")
        return (nil, nil, nil)
    }
    
    PreAllocateBuffers(Pool: BufferPool, AllocationThreshold: BufferCountHint)
    
    var PixelBuffer: CVPixelBuffer?
    var OutFormatDesc: CMFormatDescription?
    let AuxAttrs = [kCVPixelBufferPoolAllocationThresholdKey as String: BufferCountHint] as NSDictionary
    CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, BufferPool, AuxAttrs, &PixelBuffer)
    if let PixelBuffer = PixelBuffer
    {
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: PixelBuffer, formatDescriptionOut: &OutFormatDesc)
    }
    PixelBuffer = nil
    
    return(BufferPool, GColorSpace, OutFormatDesc)
}

func PreAllocateBuffers(Pool: CVPixelBufferPool, AllocationThreshold: Int)
{
    var PixelBuffers = [CVPixelBuffer]()
    var Error: CVReturn = kCVReturnSuccess
    let AuxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: AllocationThreshold] as NSDictionary
    var PixelBuffer: CVPixelBuffer?
    while Error == kCVReturnSuccess
    {
        Error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, Pool, AuxAttributes, &PixelBuffer)
        if let PixelBuffer = PixelBuffer
        {
            PixelBuffers.append(PixelBuffer)
        }
        PixelBuffer = nil
    }
    PixelBuffers.removeAll()
}

/// Images are rotated when they shouldn't be so we have to rotate them back.
///
/// - Parameter Image: The image to rotate.
/// - Returns: Properly oriented image.
func RotateImage(_ Image: CIImage) -> CIImage
{
    return Image.oriented(CGImagePropertyOrientation.right)
}

