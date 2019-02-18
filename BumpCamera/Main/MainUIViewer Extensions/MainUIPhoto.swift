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
import CoreServices

/// Code for handling photos.
extension MainUIViewer
{
    /// didFinishProcessingPhoto delegate handler.
    ///
    /// - Parameters:
    ///   - output: The output of the photo capture process.
    ///   - photo: Contains photo information.
    ///   - error: If not nil, error information.
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
                
                //let MetaData: CFDictionary = photo.metadata as CFDictionary
                let MetaData = photo.metadata
                self.SaveImageAsJPeg2(PixelBuffer: self.FinalPixelBuffer, MetaData: MetaData)
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

            //let MetaData: CFDictionary = photo.metadata as CFDictionary
            let MetaData = photo.metadata
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
    @discardableResult func SaveImageAsJPeg(PixelBuffer: CVPixelBuffer, MetaData: [String: Any]) -> Bool//CFDictionary) -> Bool
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
    
    func Spaces(_ Count: Int) -> String
    {
        var stemp = ""
        for _ in 0 ..< Count
        {
            stemp = stemp + " "
        }
        return stemp
    }
    
    func DumpMetaData(_ Meta: [String: Any], Title: String, _ Level: Int)
    {
        print("Metadata dump for ==\(Title)==")
        for (Key, Value) in Meta
        {
            switch Key
            {
            case String(kCGImagePropertyExifDictionary):
                DumpMetaData(Value as! [String: Any], Title: "Exif", 2)
                
            case String(kCGImagePropertyExifAuxDictionary):
                DumpMetaData(Value as! [String: Any], Title: "Exif Aux", 2)
                
            case String(kCGImagePropertyTIFFDictionary):
                DumpMetaData(Value as! [String: Any], Title: "Tiff", 2)
                
            case String(kCGImagePropertyIPTCDictionary):
                DumpMetaData(Value as! [String: Any], Title: "Tiff", 2)
                
            case "{MakerApple}":
                DumpMetaData(Value as! [String: Any], Title: "MakerApple", 2)
            
            default:
                print(Spaces(Level) + "\(Key)=\(Value)")
            }
        }
    }
    
    //https://medium.com/@emiswelt/exporting-images-with-metadata-to-the-photo-gallery-in-swift-3-ios-10-66210bbad5d2
    func SaveImageAsJPeg2(PixelBuffer: CVPixelBuffer, MetaData: [String: Any]) -> Bool
    {
        guard let JData = MainUIViewer.JpegData(WithPixelBuffer: PixelBuffer, Attachments: MetaData) else
        {
            print("Error creating jpeg image.")
            return false
        }
        let Image = UIImage(data: JData)
        
        if !FileHandler.ClearDirectory(FileHandler.ScratchDirectory)
        {
            print("Error clearing scratch file directory.")
            return false
        }
        let ScratchFileName = UUID().uuidString + ".jpg"
        let ScratchPath = FileHandler.ScratchDirectoryURL()?.appendingPathComponent(ScratchFileName)
        let FilePath = CFURLCreateWithFileSystemPath(nil, ScratchPath!.path as CFString, CFURLPathStyle.cfurlposixPathStyle, false)
        let Destination = CGImageDestinationCreateWithURL(FilePath!, kUTTypeJPEG, 1, nil)
        
        var Meta = MetaData
        Meta["Copyright"] = "Copyright by me"
        Meta["Software"] = "BumpCamera"
        Meta["XPKeywords"] = "test 0;test 1;test 2"
        DumpMetaData(Meta, Title: "Top-Level", 0)
        //var Exif1 = Meta[kCGImagePropertyExifDictionary as String] as! Dictionary<String,Any>
        //print("Exif:")
        //for (Key, Value) in Exif1
        //{
        //    print(" \(Key)=\(Value)")
        //}
        
        //Exif1[kCGImagePropertyExifUserComment as String] = "Comment test."
        //Meta[kCGImagePropertyExifDictionary as String] = Exif1 as CFDictionary
//        let Exif = [kCGImagePropertyExifUserComment as String: "User comment test."] as CFDictionary
        //let Properties = [kCGImagePropertyExifDictionary as String: Meta] as CFDictionary
        let Properties = Meta as CFDictionary
        
        CGImageDestinationAddImage(Destination!, (Image?.cgImage)!, Properties)
        CGImageDestinationFinalize(Destination!)
        
        try? PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: (ScratchPath?.path)!))
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
