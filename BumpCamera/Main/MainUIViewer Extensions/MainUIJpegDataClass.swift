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
    class func JpegData(WithPixelBuffer PixelBuffer: CVPixelBuffer, Attachments: CFDictionary?) -> Data?
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
        
        CGImageDestinationAddImage(CGImageDestination, RenderedCGImage, Attachments)
        if CGImageDestinationFinalize(CGImageDestination)
        {
            return IData as Data
        }
        
        print("Error finalizing image.")
        return nil
    }
}
