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
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: PhotoPixelBuffer,
                                                     formatDescriptionOut: &PhotoFormat)
        
        ProcessingQueue.async
            {
                self.FinalPixelBuffer = PhotoPixelBuffer

                let CurrentFilter = self.Filters!.PhotoFilter!.FilterType
                let FilterForPhoto = self.Filters!.CreateFilter(For: CurrentFilter)
                FilterForPhoto?.Initialize(With: PhotoFormat!, BufferCountHint: self.BufferCount)
                guard let FilteredPixelBuffer = FilterForPhoto?.Render(PixelBuffer: self.FinalPixelBuffer) else
                {
                    print("Unable to apply photo filter.")
                    return
                }

                self.FinalPixelBuffer = FilteredPixelBuffer
                
                if let DepthData = photo.depthData
                {
                    let DepthPixelBuffer = DepthData.depthDataMap
                    if !self.PhotoDepthConverter.isPrepared
                    {
                        var DepthFormatDescription: CMFormatDescription? = nil
                        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: DepthPixelBuffer, formatDescriptionOut: &DepthFormatDescription)
                    self.PhotoDepthConverter.prepare(with: DepthFormatDescription!, outputRetainedBufferCountHint: 3)
                        guard let ConvertedDepthPixelBuffer = self.PhotoDepthConverter.render(pixelBuffer: DepthPixelBuffer) else
                        {
                            print("Unable to convert depth pixel buffer.")
                            return
                        }
                        if !self.PhotoDepthMixer.isPrepared
                        {
                            self.PhotoDepthMixer.prepare(with: PhotoFormat!, outputRetainedBufferCountHint: 2)
                        }
                        guard let MixedPixelBuffer = self.PhotoDepthMixer.mix(videoPixelBuffer: self.FinalPixelBuffer,
                                                                              depthPixelBuffer: ConvertedDepthPixelBuffer) else
                        {
                            print("Unable to mix depth and photo buffers.")
                            return
                        }
                        
                        self.FinalPixelBuffer = MixedPixelBuffer
                    }
                }
                
                let MetaData: CFDictionary = photo.metadata as CFDictionary
                self.SaveImageAsJPeg(PixelBuffer: self.FinalPixelBuffer, MetaData: MetaData)
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

            let MetaData: CFDictionary = photo.metadata as CFDictionary
            if SaveImageAsJPeg(PixelBuffer: PhotoPixelBuffer, MetaData: MetaData)
            {
                WhatSaved = "Images"
            }
        }
        
        ShowTransientSaveMessage("\(WhatSaved) Saved")
    }
    
    /// Save the passed pixel data as an image in the user's photo roll.
    ///
    /// - Parameters:
    ///   - PixelBuffer: Pixel data to save.
    ///   - MetaData: Meta data for the image.
    /// - Returns: True on success, false on failure.
    @discardableResult func SaveImageAsJPeg(PixelBuffer: CVPixelBuffer, MetaData: CFDictionary) -> Bool
    {
        guard let JData = MainUIViewer.JpegData(WithPixelBuffer: PixelBuffer, Attachments: MetaData) else
        {
            print("Unable to create Jpeg image.")
            return false
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
        return true
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
    
    @objc func HandleTapForFocus(Location: CGPoint)
    {
        guard let TexturePoint = LiveView.texturePointForView(point: Location) else
        {
            return
        }
        let TextureRect = CGRect(origin: TexturePoint, size: .zero)
        let DeviceRect = VideoDataOutput.metadataOutputRectConverted(fromOutputRect: TextureRect)
        focus(with: .autoFocus, exposureMode: .autoExpose, at: DeviceRect.origin, monitorSubjectAreaChange: true)
    }
}
