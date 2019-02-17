//
//  MainUIJpegDataClass.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import CoreVideo
import AVFoundation
import Photos
import MobileCoreServices

/// Contains a jpg data class as an extension to the MainUIViewer.
extension MainUIViewer
{
    class func JpegData(WithPixelBuffer PixelBuffer: CVPixelBuffer, Attachments: [String: Any]?) -> Data?//CFDictionary?) -> Data?
    {
        let Context = CIContext()
        let RenderedCIImage = CIImage(cvImageBuffer: PixelBuffer)
        
        guard let RenderedCGImage = Context.createCGImage(RenderedCIImage, from: RenderedCIImage.extent) else
        {
            print("Error creating CGImage in JpegData")
            return nil
        }
        
        guard let IData = CFDataCreateMutable(kCFAllocatorDefault, 0) else
        {
            print("Create CFData error.")
            return nil
        }
        
        guard let CGImageDestination = CGImageDestinationCreateWithData(IData, kUTTypeJPEG, 1, nil) else
        {
            print("Error creating destination image.")
            return nil
        }
        
        #if false
        let RawMetaData = CMCopyDictionaryOfAttachments(allocator: nil, target: IData, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, RawMetaData) as NSMutableDictionary
        let ExifData = metadata.value(forKey: kCGImagePropertyExifDictionary as String) as? NSMutableDictionary
        ExifData?.setValue("Will this one work?", forKey: kCGImagePropertyExifUserComment as String)
        let FinalAttachments = ExifData! as CFDictionary
        #else
        let FinalAttachments = Attachments
        #endif
        CGImageDestinationAddImage(CGImageDestination, RenderedCGImage, FinalAttachments! as CFDictionary)
        if CGImageDestinationFinalize(CGImageDestination)
        {
            return IData as Data
        }
        
        print("Error finalizing image.")
        return nil
    }
}
