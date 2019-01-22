//
//  MainUIPhoto.swift
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

/// Code for handling photos.
extension MainUIViewer
{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        guard let PhotoPixelBuffer = photo.pixelBuffer else
        {
            print("Error capturing photo buffer - no pixel buffer: \((error?.localizedDescription)!)")
            return
        }
        
        var PhotoFormat: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: PhotoPixelBuffer,
                                                     formatDescriptionOut: &PhotoFormat)
        
        ProcessingQueue.async
            {
                var FinalPixelBuffer = PhotoPixelBuffer
                if !(self.Filters!.PhotoFilter!.Filter?.Initialized)!
                {
                    self.Filters!.PhotoFilter?.Filter?.Initialize(With: PhotoFormat!, BufferCountHint: self.BufferCount)
                }
                guard let FilteredPixelBuffer = self.Filters!.PhotoFilter?.Filter?.Render(PixelBuffer: FinalPixelBuffer) else
                {
                    print("Unable to apply photo filter.")
                    return
                }
                FinalPixelBuffer = FilteredPixelBuffer
                
                let MetaData: CFDictionary = photo.metadata as CFDictionary
                guard let JData = MainUIViewer.JpegData(WithPixelBuffer: FinalPixelBuffer, Attachments: MetaData) else
                {
                    print("Unable to create Jpeg image.")
                    return
                }
                
                PHPhotoLibrary.requestAuthorization
                    {
                        Status in
                        if Status == .authorized
                        {
                            PHPhotoLibrary.shared().performChanges(
                                {
                                    let CreationRequest = PHAssetCreationRequest.forAsset()
                                    CreationRequest.addResource(with: .photo, data: JData, options: nil)
                            },
                                completionHandler:
                                {
                                    _, error in
                                    if let error = error
                                    {
                                        print("Error saving photo to library: \(error.localizedDescription)")
                                    }
                            }
                            )
                        }
                }
        }
        
        if _Settings.bool(forKey: "ShowSaveAlert")
        {
            let Alert = UIAlertController(title: "Saved", message: "Your filtered image was saved to the photo roll.", preferredStyle: UIAlertController.Style.alert)
            Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            present(Alert, animated: true, completion: nil)
        }
        
        var WhatSaved = "Image"
        if _Settings.bool(forKey: "SaveOriginalImage")
        {
            guard let ImageData = photo.fileDataRepresentation() else
            {
                print("Error getting data for original photo.")
                return
            }
            if let Image = UIImage(data: ImageData)
            {
                UIImageWriteToSavedPhotosAlbum(Image, nil, nil, nil)
                WhatSaved = "Images"
            }
            else
            {
                print("Error converting image data to image.")
                return
            }
        }
        
        ShowTransientSaveMessage("\(WhatSaved) Saved")
    }
    
    func FinalizeImage(_ Source: UIImage) -> UIImage
    {
        #if false
        let fred = Source.ciImage
        let Context = CIContext()
        let cgimg = Context.createCGImage(fred!, from: fred!.extent)
        return UIImage(cgImage: cgimg!)
        #else
        if let cimg = CIImage(image: Source)
        {
            let Context = CIContext()
            if let cgimg = Context.createCGImage(cimg, from: cimg.extent)
            {
                let final = UIImage(cgImage: cgimg)
                return final
            }
            fatalError("Error creating CG image from context.")
        }
        fatalError("Error converting UIImage to CIImage.")
        #endif
    }
}
