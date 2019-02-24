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
    let _Settings = UserDefaults.standard
    
    // MARK: Common convenience functions.
    
    /// Merge two images using the SourceAtop compositing filter.
    ///
    /// - Parameters:
    ///   - Top: The top image (eg, closest to the viewer).
    ///   - Bottom: The bottom image (eg, the background image).
    /// - Returns: Merged image on success, nil on error.
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
    
    /// Invert the colors of the passed image.
    ///
    /// - Parameter Image: The image whose colors will be inverted.
    /// - Returns: New image based on inverted colors of the source image.
    func InvertImage(Image: CIImage) -> CIImage?
    {
        let Inverter = CIFilter(name: "CIColorInvert")
        Inverter?.setValue(Image, forKey: kCIInputImageKey)
        return Inverter?.value(forKey: kCIOutputImageKey) as? CIImage
    }
    
    /// Convert the colors of the passed image to grayscale.
    ///
    /// - Parameter Image: The image whose colors will be converted to grayscale.
    /// - Returns: New image based on grayscale values of the source image.
    func GrayscaleImage(Image: CIImage) -> CIImage?
    {
        let Gray = CIFilter(name: "CIPhotoEffectMono")
        Gray?.setValue(Image, forKey: kCIInputImageKey)
        return Gray?.value(forKey: kCIOutputImageKey) as? CIImage
    }
    
    /// Return a new image with a solid color.
    ///
    /// - Parameters:
    ///   - Image: The base image - only the exent will be used to determine the size of the returned image.
    ///   - Color: The color of the new image.
    /// - Returns: Image with a solid color.
    func SolidColorImage(Image: CIImage, Color: UIColor) -> CIImage?
    {
        let Size = CGSize(width: Image.extent.width, height: Image.extent.height)
        let NewImage = UIImage.MakeColorImage(SolidColor: Color, Size: Size)
        let Result = CIImage(image: NewImage!)
        return Result
    }
    
    /// Get the pixel buffer from the passed image.
    ///
    /// - Note:
    ///     - [How to convert a UUImage to a CVPixelBuffer](https://stackoverflow.com/questions/44462087/how-to-convert-a-uiimage-to-a-cvpixelbuffer)
    ///
    /// - Parameter Image: The image that is the source of the returned pixel buffer.
    /// - Returns: Pixel buffer with image data from the passed image on success, nil on error.
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
    
    /// Return a metal texture from a pixel buffer.
    ///
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer that serves as the source for the resultant metal texture.
    ///   - textureFormat: Format description of the texture.
    /// - Returns: Metal texture with the contents as the pixel buffer.
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
    
    /// Create a buffer pool with the suggested number of entries and passed format.
    ///
    /// - Parameters:
    ///   - From: Format to use for the buffer.
    ///   - BufferCountHint: Suggested number of entries in the buffer pool.
    /// - Returns: Tuple with the following contents: (The buffer pool to use, the color space of
    ///            the buffer pool, and a description of the format of the buffer pool).
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
    
    /// Allocate buffers before use.
    ///
    /// - Parameters:
    ///   - Pool: The pool of pixel buffers.
    ///   - AllocationThreshold: Threshold value for allocation.
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
    
    /// Images are rotated when they shouldn't be so we have to rotate them back. Rotat the image right by
    /// 90°.
    ///
    /// - Parameter Image: The image to rotate.
    /// - Parameter AndMirror: If true, the image is mirrored left-to-right as well as
    ///                        being rotated.
    /// - Returns: Properly oriented image.
    func RotateImageRight(_ Image: CIImage, AndMirror: Bool = false) -> CIImage
    {
        if AndMirror
        {
            var Rotated = Image.oriented(CGImagePropertyOrientation.downMirrored)
            Rotated = Rotated.oriented(CGImagePropertyOrientation.right)
            return Rotated
        }
        else
        {
            return Image.oriented(CGImagePropertyOrientation.right)
        }
    }
    
    /// Rotate the passed image by 180°.
    ///
    /// - Parameter Image: The image to rotate.
    /// - Returns: Image rotated 180°.
    func RotateImage180(_ Image: CIImage) -> CIImage
    {
        let Rotated = Image.oriented(CGImagePropertyOrientation.downMirrored)
        return Rotated
    }
}

/// Filter execution result types.
///
/// - Success: Returned on successful execution of a given filter. Result contains the final
///            successful result of the operation.
/// - Failure: Returned on a failed execution of a given filter. Failure(let Reason) will
///            return the reason (in a string) why the filter failed.
public enum RunFilterResults<T>
{
    case Success(Result: T)
    case Failure(Reason: String)
}

/// Equatable extension for the RunFilterResults enum.
extension RunFilterResults: Equatable
{
    /// Compares two RunFilterResults for equality.
    ///
    /// - Parameters:
    ///   - lhs: Left-hand side value.
    ///   - rhs: Right-hand side value.
    /// - Returns: True if the two sides are equal, false if not. Associated values for
    ///            enum cases are not taken into account.
    public static func ==(lhs: RunFilterResults, rhs: RunFilterResults) -> Bool
    {
        switch (lhs, rhs)
        {
        case (.Success, .Success):
            return true
            
        case (.Failure, .Failure):
            return true
            
        default:
            return false
        }
    }
}
