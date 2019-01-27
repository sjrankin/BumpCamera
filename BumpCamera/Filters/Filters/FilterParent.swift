//
//  FilterParent.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import Metal
import CoreMedia
import CoreVideo
import CoreImage

class FilterParent
{
    // MARK: Common convenience functions.
    
    func Merge(_ Top: CIImage, _ Bottom: CIImage) -> CIImage?
    {
        let InvertFilter = CIFilter(name: "CIColorInvert")
        InvertFilter?.setDefaults()
        let AlphaMaskFilter = CIFilter(name: "CIMaskToAlpha")
        AlphaMaskFilter?.setDefaults()
        let MergeSourceAtop = CIFilter(name: "CISourceAtopCompositing")
        MergeSourceAtop?.setDefaults()
        
        var FinalTop: CIImage? = nil
        InvertFilter?.setDefaults()
        AlphaMaskFilter?.setDefaults()
        
        InvertFilter?.setValue(Top, forKey: kCIInputImageKey)
        if let TopResult = InvertFilter?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            AlphaMaskFilter?.setValue(TopResult, forKey: kCIInputImageKey)
            if let MaskResult = AlphaMaskFilter?.value(forKey: kCIOutputImageKey) as? CIImage
            {
                InvertFilter?.setValue(MaskResult, forKey: kCIInputImageKey)
                if let InvertedAgain = InvertFilter?.value(forKey: kCIOutputImageKey) as? CIImage
                {
                    FinalTop = InvertedAgain
                }
                else
                {
                    print("Error returned by second call to inversion filter.")
                    return nil
                }
            }
            else
            {
                print("Error returned by alpha mask filter.")
                return nil
            }
        }
        else
        {
            print("Error return by call to inversion filter.")
            return nil
        }
        
        MergeSourceAtop?.setDefaults()
        MergeSourceAtop?.setValue(FinalTop, forKey: kCIInputImageKey)
        MergeSourceAtop?.setValue(Bottom, forKey: kCIInputBackgroundImageKey)
        if let Merged = MergeSourceAtop?.value(forKey: kCIOutputImageKey) as? CIImage
        {
            return Merged
        }
        else
        {
            print("Error returned by call to image merge filter.")
            return nil
        }
    }
    
    //https://stackoverflow.com/questions/44462087/how-to-convert-a-uiimage-to-a-cvpixelbuffer
    func GetPixelBufferFrom(_ Image: UIImage) -> CVPixelBuffer?
    {
        let Attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                          kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var PixelBuffer: CVPixelBuffer? = nil
        let Status = CVPixelBufferCreate(kCFAllocatorDefault, Int(Image.size.width),
                                         Int(Image.size.height),
                                         kCVPixelFormatType_32BGRA, Attributes,
                                         &PixelBuffer)
        guard Status == kCVReturnSuccess else
        {
            var ErrorName: String  = ""
            switch Status
            {
            case -6681:
                ErrorName = "kCVReturnInvalidSize"
                
            case -6682:
                ErrorName = "kCVReturnInvalidPixelBufferAttributes"
                
            case -6680:
                ErrorName = "kCVReturnInvalidPixelFormat"
                
            case -6684:
                ErrorName = "kCVReturnPixelBufferNotMetalCompatible"
                
            case -6683:
                ErrorName = "kCVReturnPixelBufferNotOpenGLCompatible"
                
            default:
                ErrorName = "\(Status)"
            }
            print("FilterParent: Error copying pixels in GetPixelBufferFrom. Error: \(ErrorName).")
            print("Width: \(Image.size.width), Height: \(Image.size.height)")
            return nil
        }
        CVPixelBufferLockBaseAddress(PixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let PixelData = CVPixelBufferGetBaseAddress(PixelBuffer!)
        let RGBSpace = CGColorSpaceCreateDeviceRGB()
        let Context = CGContext(data: PixelData, width: Int(Image.size.width), height: Int(Image.size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(PixelBuffer!),
                                space: RGBSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        Context?.translateBy(x: 0, y: Image.size.height)
        Context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(Context!)
        Image.draw(in: CGRect(x: 0, y: 0, width: Image.size.width, height: Image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(PixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return PixelBuffer
    }
    
    // MARK: Metal common functions and variables.
    
    var TextureCache: CVMetalTextureCache!
    
    func MakeTextureFromCVPixelBuffer(pixelBuffer: CVPixelBuffer, textureFormat: MTLPixelFormat) -> MTLTexture?
    {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Create a Metal texture from the image buffer
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, TextureCache, pixelBuffer, nil, textureFormat, width, height, 0, &cvTextureOut)
        
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            CVMetalTextureCacheFlush(TextureCache, 0)
            
            return nil
        }
        
        return texture
    }
    
    // MARK: Common pixel buffer allocation functions.
    
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
}
