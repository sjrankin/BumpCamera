//
//  MainUIObserving.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import Photos

/// Extension that manages observers for various functionality. Also contains handlers as well as
/// adding and removing observers. Some of the observing functions are used by settings management.
extension MainUIViewer
{
    /// Add observers to events that require changes to the behavior of the camera.
    func AddObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(DidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SessionRuntimeError),
                                               name: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ThermalStateChanged),
                                               name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SessionWasInterrupted),
                                               name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SessionInterruptionEnded),
                                               name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SubjectAreaChanged),
                                               name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
        CaptureSession.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &CaptureSessionContext)
    }
    
    /// Remove observers.
    func RemoveObservers()
    {
        NotificationCenter.default.removeObserver(self)
        CaptureSession.removeObserver(self, forKeyPath: "running", context: &CaptureSessionContext)
    }
    
    @objc func DidEnterBackground(notification: NSNotification)
    {
        DataOutputQueue.async
            {
                self.RenderingEnabled = false
                self.Filters?.VideoFilter?.Filter?.Reset("Video: DidEnterBackground")
                self.CurrentDepthPixelBuffer = nil
                self.VideoDepthConverter.reset()
                self.LiveView.pixelBuffer = nil
                self.LiveView.FlushTextureCache()
        }
        ProcessingQueue.async
            {
                self.Filters?.PhotoFilter?.Filter?.Reset("Photo: DidEnterBackground")
                self.PhotoDepthMixer.reset()
                self.PhotoDepthConverter.reset()
        }
    }
    
    @objc func WillEnterForeground(notification: NSNotification)
    {
        DataOutputQueue.async
            {
                self.RenderingEnabled = true
        }
    }
    
    @objc func SessionRuntimeError(notification: NSNotification)
    {
        guard let ErrorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else
        {
            //Error getting the error - for now, just give up and return.
            return
        }
        let TheError = AVError(_nsError: ErrorValue)
        print("Session runtime error: \(TheError.localizedDescription)")
        if TheError.code == .mediaServicesWereReset
        {
            self.SessionQueue.async
                {
                    if self.IsSessionRunning
                    {
                        self.CaptureSession.startRunning()
                        self.IsSessionRunning = self.CaptureSession.isRunning
                    }
            }
        }
    }
    
    @objc func SessionWasInterrupted(notification: NSNotification)
    {
        if let UserInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let ReasonIntValue = UserInfoValue.integerValue,
            let Reason = AVCaptureSession.InterruptionReason(rawValue: ReasonIntValue)
        {
            switch Reason
            {
            case .videoDeviceInUseByAnotherClient:
                print("Session interruped because video device not available due to being used by other client.")
                
            case .videoDeviceNotAvailableWithMultipleForegroundApps:
                print("Session interruped because video device not available with multiple foreground apps.")
                
            case .videoDeviceNotAvailableInBackground:
                print("Session interruped because video device not available when app in the background.")
                
            case .videoDeviceNotAvailableDueToSystemPressure:
                print("Session interruped because video device not available due to system pressure.")
                
            case .audioDeviceInUseByAnotherClient:
                print("Session interruped because audio in use by other client.")
            }
        }
    }
    
    @objc func SessionInterruptionEnded(notification: NSNotification)
    {
        //For whatever reason why the session was interrupted, it's gone now so we can restore the UI if needed.
    }
    
    @objc func SubjectAreaChanged(notification: NSNotification)
    {
        let DevicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: DevicePoint, monitorSubjectAreaChange: false)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        coordinator.animate(
            alongsideTransition:
            {
                _ in
                let InterfaceOrientation = UIApplication.shared.statusBarOrientation
                self.StatusBarOrientation = InterfaceOrientation
                self.SessionQueue.async
                    {
                        if let PhotoOrientation = AVCaptureVideoOrientation(interfaceOrientation: InterfaceOrientation)
                        {
                            self.PhotoOutput.connection(with: .video)!.videoOrientation = PhotoOrientation
                        }
                        let VideoOrientation = self.VideoDataOutput.connection(with: .video)!.videoOrientation
                        if let VRotation = LiveMetalView.Rotation(with: InterfaceOrientation, videoOrientation: VideoOrientation,
                                                                  cameraPosition: self.VideoDeviceInput.device.position)
                        {
                            self.LiveView.rotation = VRotation
                        }
                }
                DispatchQueue.main.async
                    {
                    self.FilterUIOrientationChange()
                }
        }
            , completion: nil)
    }
    
    @objc func ThermalStateChanged(notification: NSNotification)
    {
        if let PInfo = notification.object as? ProcessInfo
        {
            DispatchQueue.main.async
                {
                    self.ThermalStateUserNotification(PInfo.thermalState)
            }
        }
    }
    
    func ThermalStateUserNotification(_ State: ProcessInfo.ThermalState)
    {
        var ShowAlert = false
        var ThermalMessage = ""
        switch State
        {
        case .nominal:
            ThermalMessage = "Thermal state is nominal."
            
        case .fair:
            ThermalMessage = "Thermal state is fair."
            
        case .serious:
            ShowAlert = true
            ThermalMessage = "Thermal state is serious."
            
        case .critical:
            ShowAlert = true
            ThermalMessage = "Thermal state is critical."
        }
        print(ThermalMessage)
        if ShowAlert
        {
            let Alert = UIAlertController(title: "Bumpy Camera Thermal Alert", message: ThermalMessage, preferredStyle: .alert)
            Alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(Alert, animated: true)
        }
    }
    
    //https://stackoverflow.com/questions/47150577/error-an-observevalueforkeypathofobjectchangecontext-message-was-received
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        if keyPath == "HideFilterName"
        {
            FilterLabelIsVisible = true
            SetFilterLabelVisibility(IsVisible: FilterLabelIsVisible)
            return
        }
        if keyPath == "HideFilterSelectionUI"
        {
            if _Settings.bool(forKey: "HideFilterSelectionUI")
            {
                StartHidingTimer()
            }
            else
            {
                StopHideTimer()
            }
            return
        }
        if context == &CaptureSessionContext
        {
            let NewValue = change?[.newKey] as AnyObject?
            guard let IsSessionRunning = NewValue?.boolValue else
            {
                return
            }
            DispatchQueue.main.async
                {
                    self.CameraSwitchButton.isEnabled = IsSessionRunning && self.VideoDeviceDiscoverySession.devices.count > 1
            }
        }
        else
        {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
