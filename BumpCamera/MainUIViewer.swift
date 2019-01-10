//
//  ViewController.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/8/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import AVFoundation

//https://medium.com/@rizwanm/https-medium-com-rizwanm-swift-camera-part-1-c38b8b773b2
//https://github.com/codepath/ios_guides/wiki/Creating-a-Custom-Camera-View

class MainUIViewer: UIViewController, AVCapturePhotoCaptureDelegate
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        ApplyButton.title = "Still"
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.CaptureSession?.stopRunning()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        StartLiveView()
    }
    
    func StartLiveView()
    {
        let CaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do
        {
            let Input = try AVCaptureDeviceInput(device: CaptureDevice!)
            CaptureSession = AVCaptureSession()
            CaptureSession?.addInput(Input)
            StillImageOut = AVCapturePhotoOutput()
            CaptureSession?.addOutput(StillImageOut)
            VideoPreviewLayer = AVCaptureVideoPreviewLayer(session: CaptureSession!)
            VideoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            VideoPreviewLayer?.frame = view.layer.bounds
            OutputView.layer.addSublayer(VideoPreviewLayer!)
            #if true
            DispatchQueue.global(qos: .userInitiated).async
                {
                    self.CaptureSession?.startRunning()
            }
            #else
            CaptureSession?.startRunning()
            #endif
        }
        catch
        {
            print(error)
        }
    }
    
    var InStillMode = true
    var StillImageOut: AVCapturePhotoOutput!
    
    var CaptureSession: AVCaptureSession? = nil
    var VideoPreviewLayer: AVCaptureVideoPreviewLayer? = nil
    
    @IBAction func HandleApplyButtonPressed(_ sender: Any)
    {
        if InStillMode
        {
            InStillMode = false
            ApplyButton.title = "Movie"
        }
        else
        {
            InStillMode = true
            ApplyButton.title = "Still"
        }
    }
    
    @IBOutlet weak var ApplyButton: UIBarButtonItem!
    
    var CapturePhotoOutput: AVCapturePhotoOutput?
    
    @IBAction func HandleSaveButtonPressed(_ sender: Any)
    {
        let Settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        StillImageOut.capturePhoto(with: Settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        if error != nil
        {
            print(error!)
            return
        }
        guard let ImageData = photo.fileDataRepresentation()
            else
        {
            print("Error getting data for photo.")
            return
        }
        if let Image = UIImage(data: ImageData)
        {
            UIImageWriteToSavedPhotosAlbum(Image, nil, #selector(PhotoSavedOK), nil)
        }
        else
        {
            print("Error converting image data to image.")
        }
    }
    
    @objc func PhotoSavedOK()
    {
        let Alert = UIAlertController(title: "Saved", message: "Your image was saved to the photo album.", preferredStyle: UIAlertController.Style.alert)
        let AlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        Alert.addAction(AlertAction)
        present(Alert, animated: true)
    }
    
    @IBOutlet weak var SaveButton: UIBarButtonItem!
    
    @IBOutlet weak var ModeButton: UIBarButtonItem!
    
    @IBAction func HandleModeButtonPressed(_ sender: Any)
    {
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return .default
    }
    
    @IBOutlet weak var OutputView: UIImageView!
}

