//
//  MainUICamera.swift
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

extension MainUIViewer
{
    func CheckAuthorization() -> Bool
    {
        switch AVCaptureDevice.authorizationStatus(for: .video)
        {
        case .authorized:
            return true
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler:
                {
                    Granted in
                    if !Granted
                    {
                        self.WasGranted = false
                    }
                    else
                    {
                        self.WasGranted = true
                    }
            })
            return WasGranted
            
        default:
            return false
        }
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool)
    {
        SessionQueue.async
            {
                let videoDevice = self.VideoDeviceInput.device
                
                do {
                    try videoDevice.lockForConfiguration()
                    if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                        videoDevice.focusPointOfInterest = devicePoint
                        videoDevice.focusMode = focusMode
                    }
                    
                    if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                        videoDevice.exposurePointOfInterest = devicePoint
                        videoDevice.exposureMode = exposureMode
                    }
                    
                    videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    videoDevice.unlockForConfiguration()
                }
                catch
                {
                    print("Could not lock device for configuration: \(error)")
                }
        }
    }
    
    func HandleTapForFocusAndExpose(_ Gesture: UITapGestureRecognizer)
    {
        let Location = Gesture.location(in: LiveView)
        guard let TexturePoint = LiveView.texturePointForView(point: Location) else
        {
            return
        }
        let TextureRect = CGRect(origin: TexturePoint, size: .zero)
        let DeviceRect = VideoOutput.metadataOutputRectConverted(fromOutputRect: TextureRect)
        focus(with: .autoFocus, exposureMode: .autoExpose, at: DeviceRect.origin, monitorSubjectAreaChange: true)
    }
    
    func PrepareForLiveView()
    {
        let InterfaceOrientation = UIApplication.shared.statusBarOrientation
        StatusBarOrientation = InterfaceOrientation
    }
    
    func UpdatePreviewLayer(Layer: AVCaptureConnection, Orientation: AVCaptureVideoOrientation)
    {
        Layer.videoOrientation = Orientation
        VideoPreviewLayer!.frame = LiveView.bounds
    }
    
    func ConfigureLiveView()
    {
        if OnSimulator
        {
            return
        }
        
        let DefaultVideoDevice: AVCaptureDevice? = VideoDeviceDiscoverySession.devices.first
        guard let DefVideoDevice = DefaultVideoDevice else
        {
            print("No video device.")
            return
        }
        
        do
        {
            VideoDeviceInput = try AVCaptureDeviceInput(device: DefVideoDevice)
        }
        catch
        {
            print("Error creating input video device: \(error.localizedDescription)")
        }
        
        CaptureSession.beginConfiguration()
        CaptureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        guard CaptureSession.canAddInput(VideoDeviceInput) else
        {
            print("Could not add video device for session")
            CaptureSession.commitConfiguration()
            return
        }
        CaptureSession.addInput(VideoDeviceInput)
        
        if CaptureSession.canAddOutput(VideoDataOutput)
        {
            CaptureSession.addOutput(VideoDataOutput)
            VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            VideoDataOutput.setSampleBufferDelegate(self, queue: DataOutputQueue)
        }
        else
        {
            print("Error adding video data output to the capture session.")
            CaptureSession.commitConfiguration()
            return
        }
        
        if CaptureSession.canAddOutput(PhotoOutput)
        {
            CaptureSession.addOutput(PhotoOutput)
            PhotoOutput.isHighResolutionCaptureEnabled = false
        }
        else
        {
            print("Error adding photo device to session.")
            CaptureSession.commitConfiguration()
            return
        }
        
        CaptureSession.commitConfiguration()
    }
    
    func SwitchToRearCamera()
    {
        DoSwitchCameras()
    }
    
    func DoSwitchCameras()
    {
        if OnSimulator
        {
            ShowMessage("Cannot switch cameras on simulator")
            return
        }
        
        DataOutputQueue.sync
            {
                self.RenderingEnabled = false
                self.Filters?.VideoFilter?.Filter!.Reset("Video: DoSwitchCameras")
                self.LiveView.pixelBuffer = nil
        }
        
        ProcessingQueue.sync
            {
                self.Filters?.PhotoFilter?.Filter!.Reset("Photo: DoSwitchCameras")
        }
        
        let InterfaceOrientation = StatusBarOrientation
        
        SessionQueue.async
            {
                let CurrentVideoDevice = self.VideoDeviceInput.device
                let CurrentPhotoOrientation = self.PhotoOutput.connection(with: .video)!.videoOrientation
                var PreferredPosition = AVCaptureDevice.Position.unspecified
                switch CurrentVideoDevice.position
                {
                case .unspecified:
                    fallthrough
                case .front:
                    PreferredPosition = .back
                    
                case .back:
                    PreferredPosition = .front
                }
                
                let Devices = self.VideoDeviceDiscoverySession.devices
                if let PreferredDevice = Devices.first(where: {$0.position == PreferredPosition})
                {
                    var VidInput: AVCaptureDeviceInput
                    do
                    {
                        VidInput = try AVCaptureDeviceInput(device: PreferredDevice)
                    }
                    catch
                    {
                        print("Error creating video device during camera switch: \(error.localizedDescription)")
                        self.DataOutputQueue.async
                            {
                                self.RenderingEnabled = true
                        }
                        return
                    }
                    
                    self.CaptureSession.beginConfiguration()
                    
                    self.CaptureSession.removeInput(self.VideoDeviceInput)
                    if self.CaptureSession.canAddInput(VidInput)
                    {
                        NotificationCenter.default.removeObserver(self,
                                                                  name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                                                  object: CurrentVideoDevice)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.SubjectAreaChanged),
                                                               name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                                               object: PreferredDevice)
                        self.CaptureSession.addInput(VidInput)
                        self.VideoDeviceInput = VidInput
                    }
                    else
                    {
                        print("Could not add video to device input during switch operation.")
                        self.CaptureSession.addInput(self.VideoDeviceInput)
                    }
                    
                    self.PhotoOutput.connection(with: .video)!.videoOrientation = CurrentPhotoOrientation
                    
                    if self.PhotoOutput.isDepthDataDeliverySupported
                    {
                        self.PhotoOutput.isDepthDataDeliveryEnabled = self._Settings.bool(forKey: "EnableDepthData")
                        self.DepthDataOutput.connection(with: .depthData)!.isEnabled = self._Settings.bool(forKey: "EnableDepthData")
                        if self._Settings.bool(forKey: "EnableDepthData") && self.OutputSynchronizer == nil
                        {
                            self.OutputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.VideoDataOutput, self.DepthDataOutput])
                            self.OutputSynchronizer!.setDelegate(self, queue: self.DataOutputQueue)
                        }
                        if let FrameDuration = PreferredDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration
                        {
                            do
                            {
                                try PreferredDevice.lockForConfiguration()
                                PreferredDevice.activeVideoMinFrameDuration = FrameDuration
                                PreferredDevice.unlockForConfiguration()
                            }
                            catch
                            {
                                print("Could not lock device for configuration: \(error.localizedDescription)")
                            }
                        }
                    }
                    else
                    {
                        self.OutputSynchronizer = nil
                    }
                    
                    self.CaptureSession.commitConfiguration()
                }
                
                let VideoPosition = self.VideoDeviceInput.device.position
                let VideoOrientation = self.VideoDataOutput.connection(with: .video)!.videoOrientation
                let Rotation = PreviewMetalView.Rotation(with: InterfaceOrientation!, videoOrientation: VideoOrientation,
                                                         cameraPosition: VideoPosition)
                
                print("Video position is front: \(VideoPosition == .front)")
                self.LiveView.mirroring = (VideoPosition == .front)
                if let Rotation = Rotation
                {
                    self.LiveView.rotation = Rotation
                }
                
                self.DataOutputQueue.async
                    {
                        self.RenderingEnabled = true
                }
        }
    }
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection)
    {
        if let SyncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: DepthDataOutput) as? AVCaptureSynchronizedDepthData
        {
            if !SyncedDepthData.depthDataWasDropped
            {
                let DepthData = SyncedDepthData.depthData
                processDepth(depthData: DepthData)
            }
        }
        if let SyncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: VideoDataOutput) as? AVCaptureSynchronizedSampleBufferData
        {
            if !SyncedVideoData.sampleBufferWasDropped
            {
                let VidSampleBuf = SyncedVideoData.sampleBuffer
                ProcessLiveViewFrame(Buffer: VidSampleBuf)
            }
        }
    }
    
    func depthDataOutput(_ depthDataOutput: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData,
                         timestamp: CMTime, connection: AVCaptureConnection)
    {
        processDepth(depthData: depthData)
    }
    
    func processDepth(depthData: AVDepthData)
    {
        if !RenderingEnabled
        {
            return
        }
        if !_Settings.bool(forKey: "EnableDepthData")
        {
            return
        }
        if !VideoDepthConverter.isPrepared
        {
            var DepthFormatDescription: CMFormatDescription? = nil
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: depthData.depthDataMap, formatDescriptionOut: &DepthFormatDescription)
            VideoDepthConverter.prepare(with: DepthFormatDescription!, outputRetainedBufferCountHint: BufferCount)
        }
        guard let DepthPixelBuffer = VideoDepthConverter.render(pixelBuffer: depthData.depthDataMap) else
        {
            print("Unable to process depth.")
            return
        }
        
        CurrentDepthPixelBuffer = DepthPixelBuffer
    }
    
    func CameraWithPosition(_ Position: AVCaptureDevice.Position) -> AVCaptureDevice?
    {
        let DeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        for Device in DeviceDiscoverySession.devices
        {
            if Device.position == Position
            {
                return Device
            }
        }
        return nil
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        ProcessLiveViewFrame(Buffer: sampleBuffer)
    }
    
    func ProcessLiveViewFrame(Buffer: CMSampleBuffer)
    {
        guard let VideoPixelBuffer = CMSampleBufferGetImageBuffer(Buffer) else
        {
            print("Error getting sample buffer in ProcessLiveViewFrame.")
            return
        }
        guard let FormatDescription = CMSampleBufferGetFormatDescription(Buffer) else
        {
            print("Error getting format description.")
            return
        }
        let FinalPixelBuffer = VideoPixelBuffer
        
        if Filters?.VideoFilter == nil
        {
            print("Setting filter to NotSet")
            Filters?.SetCurrentFilter(FilterType: .NotSet)
        }
        //let Current = Filters?.VideoFilter?.FilterType
        //print("Current video filter: \((Filters?.GetFilterTitle(Current!))!), Raw=\(Current!.rawValue)")
        if !(Filters?.VideoFilter?.Filter?.Initialized)!
        {
            Filters?.VideoFilter?.Filter?.Initialize(With: FormatDescription, BufferCountHint: BufferCount)
        }
        
        guard let FilteredBuffer = Filters?.VideoFilter?.Filter?.Render(PixelBuffer: FinalPixelBuffer) else
        {
            print("Render for current filter returned nil - skipping frame. (Did you just change filters?)")
            return
        }
        
        LiveView.pixelBuffer = FilteredBuffer
    }
}
