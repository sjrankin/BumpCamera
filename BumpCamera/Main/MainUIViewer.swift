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
import CoreVideo
import AVFoundation
import Photos
import MobileCoreServices

//https://medium.com/@rizwanm/https-medium-com-rizwanm-swift-camera-part-1-c38b8b773b2
//https://github.com/codepath/ios_guides/wiki/Creating-a-Custom-Camera-View

class MainUIViewer: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,
    UICollectionViewDelegate, UICollectionViewDataSource
{
    let _Settings = UserDefaults.standard
    
    var MaskLineSize: Double = 5.0
    var BlockSize: Double = 20.0
    var OnSimulator = false
    var Filters: FilterManager? = nil
    var VideoIsAuthorized = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        VideoIsAuthorized = CheckAuthorization()
        Filters = FilterManager()
        if !_Settings.bool(forKey: "SettingsInstalled")
        {
            InitializeSettings()
        }

        InitializeFilterSelector()
        #if targetEnvironment(simulator)
        OnSimulator = true
        #endif
        AddGridOverlayLayer()
        CommonInitialization()
        let Tap = UITapGestureRecognizer(target: self, action: #selector(HandlePreviewTap))
        Tap.numberOfTapsRequired = 1
        self.OutputView2.addGestureRecognizer(Tap)
        
        //OutputView.layer.borderColor = UIColor.red.cgColor
        //OutputView.layer.borderWidth = 20.0
        
        StatusLabel.layer.cornerRadius = 5.0
        StatusLabel.layer.borderColor = UIColor.black.cgColor
        StatusLabel.layer.borderWidth = 0.5
        StatusLabel.textColor = UIColor.black
        StatusLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        StatusLabel.alpha = 0.0
        
        FilterLabel.textColor = UIColor.white
        FilterLabel.layer.cornerRadius = 15.0
        ShowFilter("No Filter")
        SetFilterLabelVisibility(IsVisible: true)
        
        //https://stackoverflow.com/questions/34883594/cant-make-uitoolbar-black-color-with-white-button-item-tint-ios-9-swift/34885377
        MainBottomToolbar.barTintColor = UIColor.black
        MainBottomToolbar.tintColor = UIColor.white
        MainBottomToolbar.sizeToFit()
        MainBottomToolbar.isTranslucent = false
        //OutputView.addSubview(TestLabel)
        //OutputView.bringSubviewToFront(TestLabel)
        
        PrepareForLiveView()
        StartLiveView()
        StartSettingsMonitor()
    }
    
    var WasGranted: Bool = false
    
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
    
    func PrepareForLiveView()
    {
        let InterfaceOrientation = UIApplication.shared.statusBarOrientation
        StatusBarOrientation = InterfaceOrientation
    }
    
    private var StatusBarOrientation: UIInterfaceOrientation!
    
    private var CaptureSessionContext = 0
    
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
        CaptureSession?.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &CaptureSessionContext)
    }
    
    func RemoveObservers()
    {
        NotificationCenter.default.removeObserver(self)
        CaptureSession?.removeObserver(self, forKeyPath: "running", context: &CaptureSessionContext)
    }
    
    private var RenderingEnabled = false
    
    @objc func DidEnterBackground(notification: NSNotification)
    {
        RenderingEnabled = false
        OutputView2.pixelBuffer = nil
        OutputView2.flushTextureCache()
    }
    
    @objc func WillEnterForeground(notification: NSNotification)
    {
        RenderingEnabled = true
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
            if IsSessionRunning
            {
                IsSessionRunning = (CaptureSession?.isRunning)!
            }
        }
    }
    
    var IsSessionRunning = false
    
    @objc func ThermalStateChanged(notification: NSNotification)
    {
        if let PInfo = notification.object as? ProcessInfo
        {
            var ShowAlert = false
            var ThermalMessage = ""
            switch PInfo.thermalState
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
    }
    
    @objc func SessionWasInterrupted(notification: NSNotification)
    {
        if let UserInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
        let ReasonIntValue = UserInfoValue.integerValue,
            let Reason = AVCaptureSession.InterruptionReason(rawValue: ReasonIntValue)
        {
            print("Capture session was interrupted because \(Reason)")
            if Reason == .videoDeviceInUseByAnotherClient
            {
                //Someone else stole our video session!
            }
            else
            {
                if Reason == .videoDeviceNotAvailableWithMultipleForegroundApps
                {
                    //Someone else is on the screen at the same time!
                }
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
    
    func HandleTapForFocusAndExpose(_ Gesture: UITapGestureRecognizer)
    {
        let Location = Gesture.location(in: OutputView2)
        guard let TexturePoint = OutputView2.texturePointForView(point: Location) else
        {
            return
        }
        let TextureRect = CGRect(origin: TexturePoint, size: .zero)
        let DeviceRect = VideoOutput.metadataOutputRectConverted(fromOutputRect: TextureRect)
        focus(with: .autoFocus, exposureMode: .autoExpose, at: DeviceRect.origin, monitorSubjectAreaChange: true)
    }
    
    var VideoDevice: AVCaptureDeviceInput!
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool)
    {
        let videoDevice = VideoDevice.device
            
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
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
    }
    
    func StartSettingsMonitor()
    {
        _Settings.addObserver(self, forKeyPath: "HideFilterName", options: NSKeyValueObservingOptions.new, context: nil)
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
        if context == &CaptureSessionContext
        {
            let NewValue = change?[.newKey] as AnyObject?
            guard let IsSessionRunning = NewValue?.boolValue else
            {
                return
            }
            CameraSwitchButton.isEnabled = IsSessionRunning
        }
        else
        {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func InitializeSettings()
    {
        _Settings.set(true, forKey: "SettingsInstalled")
        _Settings.set(false, forKey: "HideFilterName")
        _Settings.set(true, forKey: "SaveOriginalImage")
        _Settings.set(false, forKey: "ShowSaveAlert")
        let InitialGroupID = Filters?.GetGroupID(ForGroup: .Standard)
        _Settings.set(InitialGroupID?.uuidString, forKey: "CurrentGroup")
        let InitialFilterID = Filters?.GetFilterID(For: .PassThrough)
        _Settings.set(InitialFilterID?.uuidString, forKey: "CurrentFilter")
        for SomeFilter in Filters!.ImplementedFilters()
        {
            print("Getting implemented filter: \(SomeFilter)")
            if let CamFilter = Filters!.GetFilter(Name: SomeFilter)
            {
                let Packet = CamFilter.Filter?.GetDefaultPacket()
                let FilterID = CamFilter.ID.uuidString
                let EncodedPacket = RenderPacket.Encode(Packet!)
                _Settings.set(EncodedPacket, forKey: FilterID)
            }
            else
            {
                fatalError("Unexpected got bad filter.")
            }
        }
    }
    
    func LoadFilterSettings(For: FilterNames) -> RenderPacket
    {
        let FilterID = Filters!.GetFilterID(For: For)
        let SettingKey = FilterID?.uuidString
        let Raw = _Settings.string(forKey: SettingKey!)
        let FilterSettings = RenderPacket.Decode(ID: FilterID!, Raw!)
        return FilterSettings
    }
    
    @objc func HandlePreviewTap(sender: UITapGestureRecognizer)
    {
        if sender.state == .ended
        {
            if _Settings.bool(forKey: "ShowFilterName")
            {
                let TapLocation = sender.location(in: OutputView2)
                if TapLocation.y <= FilterLabel.frame.minY + FilterLabel.frame.height
                {
                    if FilterLabelIsVisible
                    {
                        SetFilterLabelVisibility(IsVisible: false)
                    }
                    else
                    {
                        SetFilterLabelVisibility(IsVisible: true)
                    }
                    return
                }
            }
            if FiltersAreShowing
            {
                UpdateFilterSelectionVisibility()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        #if false
        CommonInitialization()
        StartLiveView()
        if !UsingRearCamera
        {
            print("Switching to front camera.")
            SwitchToFrontCamera()
        }
        //StartLiveView()
        #endif
    }
    
    func AddGridOverlayLayer()
    {
        SetGridVisibility(IsVisible: true)
    }
    
    func SetGridVisibility(IsVisible: Bool)
    {
        if IsVisible
        {
            if GridLayerIsShowing
            {
                return
            }
            GridLayerIsShowing = true
            GridLayer = MakeGrid()
            OutputView2.layer.addSublayer(GridLayer!)
        }
        else
        {
            if !GridLayerIsShowing
            {
                return
            }
            GridLayerIsShowing = false
            OutputView2.layer.sublayers!.forEach{if $0.name == "Grid Layer"
            {
                $0.removeFromSuperlayer()
                }
            }
        }
    }
    
    func MakeGrid() -> CAShapeLayer
    {
        #if true
        return CAShapeLayer()
        #else
        let Layer = CAShapeLayer()
        Layer.name = "Grid Layer"
        Layer.zPosition = 2000
        Layer.backgroundColor = UIColor.clear.cgColor
        Layer.frame = MainOutputRect
        let FinalSize = Layer.frame.size
        Layer.lineWidth = 1.0
        Layer.strokeColor = UIColor.yellow.cgColor
        let Lines = UIBezierPath()
        Lines.move(to: CGPoint(x: FinalSize.width / 2.0, y: 0))
        Lines.addLine(to: CGPoint(x: FinalSize.width / 2.0, y: FinalSize.height))
        Lines.move(to: CGPoint(x: 0, y: FinalSize.height / 2.0))
        Lines.addLine(to: CGPoint(x: FinalSize.width, y: FinalSize.height / 2.0))
        Layer.path = Lines.cgPath
        return Layer
        #endif
    }
    
    var GridLayerIsShowing: Bool = false
    var GridLayer: CAShapeLayer? = nil
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        coordinator.animate(
            alongsideTransition:
            {
                _ in
                let InterfaceOrientation = UIApplication.shared.statusBarOrientation
                self.StatusBarOrientation = InterfaceOrientation
                if let PhotoOrientation = AVCaptureVideoOrientation(interfaceOrientation: InterfaceOrientation)
                {
                    self.PhotoOutput.connection(with: .video)!.videoOrientation = PhotoOrientation
                }
                let VideoOrientation = self.VideoDataOutput.connection(with: .video)!.videoOrientation
                if let VRotation = PreviewMetalView.Rotation(with: InterfaceOrientation, videoOrientation: VideoOrientation,
                                                             cameraPosition: self.VideoDevice.device.position)
                {
                 self.OutputView2.rotation = VRotation
                }
        }
            , completion: nil)
        /*
        super.viewWillTransition(to: size, with: coordinator)
        InLandscape = size.width > size.height
        #if false
        let CurrentOrientation = UIDevice.current.orientation
        ImageFilterer.PrintOrientation(CurrentOrientation)
        var VideoOrientation: AVCaptureVideoOrientation? = nil
        switch CurrentOrientation
        {
        case .portraitUpsideDown:
            VideoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            
        case .portrait:
            VideoOrientation = AVCaptureVideoOrientation.portrait
            
        case .landscapeLeft:
            VideoOrientation = AVCaptureVideoOrientation.landscapeLeft
            
        case .landscapeRight:
            VideoOrientation = AVCaptureVideoOrientation.landscapeRight
            
        default:
            break
        }
        if let VideoOrientation = VideoOrientation
        {
            VideoPreviewLayer?.connection?.videoOrientation = VideoOrientation
        }
        #endif
 */
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.all
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        //self.CaptureSession?.stopRunning()
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    var InLandscape: Bool = false
    
    func CommonInitialization()
    {
        setNeedsStatusBarAppearanceUpdate()
        #if false
        GBackground = BackgroundServer(BackgroundView)
        BGTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(UpdateBackground), userInfo: nil, repeats: true)
        #endif
    }
    
    var BGTimer: Timer!
    
    var GBackground: BackgroundServer!
    
    @objc func UpdateBackground()
    {
        GBackground.UpdateBackgroundColors()
    }
    
    private func UpdatePreviewLayer(Layer: AVCaptureConnection, Orientation: AVCaptureVideoOrientation)
    {
        Layer.videoOrientation = Orientation
        VideoPreviewLayer!.frame = OutputView2.bounds
    }
    
    //https://stackoverflow.com/questions/15075300/avcapturevideopreviewlayer-orientation-need-landscape
    override func viewDidLayoutSubviews()
    {
        if OnSimulator
        {
            return
        }
        
        if let Connection = VideoPreviewLayer?.connection
        {
            let CurrentDevice = UIDevice.current
            let Orientation = CurrentDevice.orientation
            let PreviewLayerConnection = Connection
            if PreviewLayerConnection.isVideoOrientationSupported
            {
                switch Orientation
                {
                case .portrait:
                    print("Orientation: Portrait")
                    UpdatePreviewLayer(Layer: PreviewLayerConnection, Orientation: .portrait)
                    
                case .landscapeLeft:
                    print("Orientation: Landscape Left")
                    UpdatePreviewLayer(Layer: PreviewLayerConnection, Orientation: .landscapeRight)
                    
                case .landscapeRight:
                    print("Orientation: Landscape Right")
                    UpdatePreviewLayer(Layer: PreviewLayerConnection, Orientation: .landscapeLeft)
                    
                case .portraitUpsideDown:
                    print("Orientation: Portrait Upside Down")
                    UpdatePreviewLayer(Layer: PreviewLayerConnection, Orientation: .portraitUpsideDown)
                    
                default:
                    UpdatePreviewLayer(Layer: PreviewLayerConnection, Orientation: .portrait)
                }
            }
        }
    }
    
    private let VideoDataOutput = AVCaptureVideoDataOutput()
    private let PhotoOutput = AVCapturePhotoOutput()
    
    private let VideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,
                                                                                             .builtInWideAngleCamera],
                                                                               mediaType: .video,
                                                                               position: .unspecified)
    
    func StartLiveView()
    {
        if OnSimulator
        {
            return
        }
        #if true
        let DefaultVideoDevice: AVCaptureDevice? = VideoDeviceDiscoverySession.devices.first
        guard let DVideoDevice = DefaultVideoDevice else
        {
            print("No video device.")
            return
        }
        
        do
        {
            VideoDevice = try AVCaptureDeviceInput(device: DVideoDevice)
        }
        catch
        {
            print("Error creating input video device: \(error.localizedDescription)")
        }
        
        CaptureSession?.beginConfiguration()
        CaptureSession?.sessionPreset = AVCaptureSession.Preset.photo
        
        guard (CaptureSession?.canAddInput(VideoDevice))! else
        {
            print("Could not add video device for session")
            CaptureSession?.commitConfiguration()
            return
        }
        CaptureSession?.addInput(VideoDevice)
        
        if (CaptureSession?.canAddOutput(VideoDataOutput))!
        {
            CaptureSession?.addOutput(VideoDataOutput)
            VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            VideoDataOutput.setSampleBufferDelegate(self, queue: DataOutputQueue)
        }
        else
        {
            print("Error adding video data output to the capture session.")
            CaptureSession?.commitConfiguration()
            return
        }
        
        if (CaptureSession?.canAddOutput(PhotoOutput))!
        {
            CaptureSession?.addOutput(PhotoOutput)
            PhotoOutput.isHighResolutionCaptureEnabled = true
        }
        else
        {
            print("Error adding photo device to session.")
            CaptureSession?.commitConfiguration()
            return
        }
        
        CaptureSession?.commitConfiguration()
        #else
        let CaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do
        {
            let Input = try AVCaptureDeviceInput(device: CaptureDevice!)
            CaptureSession = AVCaptureSession()
            CaptureSession?.addInput(Input)
            
            StillImageOut = AVCapturePhotoOutput()
            StillImageOut.isHighResolutionCaptureEnabled = true
            CaptureSession?.addOutput(StillImageOut)
            
            CaptureSession?.addOutput(VideoOutput)
            VideoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            VideoOutput.setSampleBufferDelegate(self, queue: DataOutputQueue)
            
            VideoPreviewLayer = AVCaptureVideoPreviewLayer(session: CaptureSession!)
            VideoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            VideoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            VideoPreviewLayer?.frame = view.layer.bounds
            OutputView2.layer.addSublayer(VideoPreviewLayer!)
            DispatchQueue.global(qos: .userInitiated).async
                {
                    self.CaptureSession?.startRunning()
            }
        }
        catch
        {
            print(error)
        }
    #endif
    }
    
    var InStillMode = true
    var StillImageOut: AVCapturePhotoOutput!
    let DataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [],
                                        autoreleaseFrequency: .workItem)
    var VideoOutput = AVCaptureVideoDataOutput()
    var CaptureSession: AVCaptureSession? = nil
    var VideoPreviewLayer: AVCaptureVideoPreviewLayer? = nil
    var UsingRearCamera: Bool = true
    
    //https://stackoverflow.com/questions/39060171/switching-camera-with-a-button-in-swift
    @IBAction func HandleCameraSwitchButtonPressed(_ sender: Any)
    {
        DoSwitchCameras()
    }
    
    func SwitchToRearCamera()
    {
        if UsingRearCamera
        {
            return
        }
        DoSwitchCameras()
    }
    
    func SwitchToFrontCamera()
    {
        if !UsingRearCamera
        {
            return
        }
        DoSwitchCameras()
    }
    
    func DoSwitchCameras()
    {
        if OnSimulator
        {
            ShowMessage("Cannot Switch Cameras")
            return
        }
        #if true
        RenderingEnabled = false
        Filters?.CurrentFilter?.Filter!.Reset()
        OutputView2.pixelBuffer = nil
        let InterfaceOrientation = StatusBarOrientation
        let CurrentVideoDevice = VideoDevice.device
        let CurrentPhotoOrientation = PhotoOutput.connection(with: .video)!.videoOrientation
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
        
        let Devices = VideoDeviceDiscoverySession.devices
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
                RenderingEnabled = true
                return
            }
            CaptureSession?.beginConfiguration()
            
            CaptureSession?.removeInput(VideoDevice)
            if (CaptureSession?.canAddInput(VidInput))!
            {
                NotificationCenter.default.removeObserver(self,
                                                          name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                                          object: CurrentVideoDevice)
                NotificationCenter.default.addObserver(self, selector: #selector(SubjectAreaChanged),
                                                       name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                                       object: VideoDevice)
                CaptureSession?.addInput(VidInput)
                VideoDevice = VidInput
            }
            else
            {
                print("Could not add video to device input during switch operation.")
                CaptureSession?.addInput(VideoDevice)
            }
            
            PhotoOutput.connection(with: .video)!.videoOrientation = CurrentPhotoOrientation
            CaptureSession?.commitConfiguration()
        }
        
        let VideoPosition = VideoDevice.device.position
        let VideoOrientation = VideoDataOutput.connection(with: .video)!.videoOrientation
        let Rotation = PreviewMetalView.Rotation(with: InterfaceOrientation!, videoOrientation: VideoOrientation, 
                                                 cameraPosition: VideoPosition)
        
        OutputView2.mirroring = (VideoPosition == .front)
        if let Rotation = Rotation
        {
            OutputView2.rotation = Rotation
        }
        
        RenderingEnabled = true
        #else
        let OldSession = CaptureSession?.inputs[0]
        CaptureSession?.removeInput(OldSession!)
        var NewCamera: AVCaptureDevice!
        NewCamera = AVCaptureDevice.default(for: AVMediaType.video)!
        
        if (OldSession as! AVCaptureDeviceInput).device.position == .back
        {
            UIView.transition(with: self.OutputView2, duration: 0.35, options: .transitionCrossDissolve, animations:
                {
                    NewCamera = self.CameraWithPosition(.front)!
            }, completion: nil)
            UsingRearCamera = false
        }
        else
        {
            UIView.transition(with: self.OutputView2, duration: 0.35, options: .transitionCrossDissolve, animations:
                {
                    NewCamera = self.CameraWithPosition(.back)!
            }, completion: nil)
            UsingRearCamera = true
        }
        do
        {
            try self.CaptureSession?.addInput(AVCaptureDeviceInput(device: NewCamera))
        }
        catch
        {
            print("Error swaping camera: \(error.localizedDescription)")
        }
        #endif
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
    
    @IBOutlet weak var CameraSwitchButton: UIBarButtonItem!
    
    var CapturePhotoOutput: AVCapturePhotoOutput?
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        ProcessLiveViewFrame(Buffer: sampleBuffer)
    }
    
    var CurrentRenderer: Renderer? = nil
    var Parameter: RenderPacket? = nil
    
    func ProcessLiveViewFrame(Buffer: CMSampleBuffer)
    {
        guard let VideoPixelBuffer = CMSampleBufferGetImageBuffer(Buffer),
            let FormatDescription = CMSampleBufferGetFormatDescription(Buffer) else
        {
            print("Error getting format description.")
            return
        }
        let FinalPixelBuffer = VideoPixelBuffer
        if CurrentRenderer == nil
        {
            CurrentRenderer = Noir()
            CurrentRenderer?.Initialize(With: FormatDescription, BufferCountHint: 3)
        }
        guard let FilteredBuffer = CurrentRenderer?.Render(PixelBuffer: FinalPixelBuffer, Parameters: Parameter) else
        {
            print("Renderer.Render returned error (nil result).")
            return
        }
        OutputView2.pixelBuffer = FilteredBuffer
    }
    
    @IBAction func HandleSaveButtonPressed(_ sender: Any)
    {
        if OnSimulator
        {
            ShowMessage("Cannot Save Image")
            return
        }
        #if true
        let Settings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
        StillImageOut.capturePhoto(with: Settings, delegate: self)
        #else
        let Settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        StillImageOut.capturePhoto(with: Settings, delegate: self)
        #endif
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        #if true
        guard let PhotoPixelBuffer = photo.pixelBuffer else
        {
            print("Error capturing photo buffer - no pixel buffer: \((error?.localizedDescription)!)")
            return
        }
        
        var PhotoFormat: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: PhotoPixelBuffer, formatDescriptionOut: &PhotoFormat)
        var FinalPixelBuffer = PhotoPixelBuffer
        if !(Filters!.CurrentFilter?.Filter?.Initialized)!
        {
            Filters!.CurrentFilter?.Filter?.Initialize(With: PhotoFormat!, BufferCountHint: 3)
        }
        let Packet = Filters!.GetParameters(For: (Filters!.CurrentFilter?.FilterType)!)
        guard let FilteredPixelBuffer = Filters!.CurrentFilter?.Filter?.Render(PixelBuffer: FinalPixelBuffer, Parameters: Packet) else
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
        
        if _Settings.bool(forKey: "ShowSaveAlert")
        {
            let Alert = UIAlertController(title: "Saved", message: "Your filtered image was saved to the photo roll.", preferredStyle: UIAlertController.Style.alert)
            Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            present(Alert, animated: true, completion: nil)
        }
        
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
            }
        }

        #else
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
            OriginalImageToSave = Image
            PreviewImage = ApplyFilter(To: Image)
            DoSaveImage()
        }
        else
        {
            print("Error converting image data to image.")
        }
        #endif
    }
    
    var OriginalImageToSave: UIImage? = nil
    
    #if false
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer)
    {
        if let error = error
        {
            let ErrorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            ErrorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            present(ErrorAlert, animated: true)
        }
        else
        {
            if _Settings.bool(forKey: "ShowSaveAlert")
            {
                let Alert = UIAlertController(title: "Saved", message: "Your image was saved to the photo album.", preferredStyle: UIAlertController.Style.alert)
                let AlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                Alert.addAction(AlertAction)
                present(Alert, animated: true)
            }
            else
            {
                ShowTransientSaveMessage("Image saved")
                print("Images saved to photo album successfully.")
            }
        }
    }
    #endif
    
    func ShowTransientSaveMessage(_ Message: String)
    {
        StatusLabel.text = Message
        StatusLabel.alpha = 1.0
        StatusLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
            self.StatusLabel.alpha = 0.0
        }, completion: nil)
    }
    
    func ShowMessage(_ Message: String)
    {
        StatusLabel.text = Message
        StatusLabel.alpha = 1.0
        StatusLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.65)
        UIView.animate(withDuration: 0.5, delay: 5.0, options: [], animations:
            {
                self.StatusLabel.alpha = 0.0
        }, completion: nil)
    }
    
    func ShowFilter(_ Message: String)
    {
        FilterLabel.text = "   " + Message
        if !FilterLabelIsVisible
        {
            return
        }
        FilterLabel.alpha = 1.0
        FilterLabel.textColor = UIColor.white
        FilterLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        UIView.animate(withDuration: 2.5, delay: 5.0, options: [], animations:
            {
                self.FilterLabel.alpha = 0.5
                self.FilterLabel.textColor = UIColor.black
        }
            , completion: nil)
    }
    
    func SetFilterLabelVisibility(IsVisible: Bool)
    {
        FilterLabelIsVisible = IsVisible
        if _Settings.bool(forKey: "HideFilterName")
        {
            self.FilterLabel.alpha = 0.0
            return
        }
        if !FilterLabelIsVisible
        {
            UIView.animate(withDuration: 0.5)
            {
                self.FilterLabel.alpha = 0.0
            }
        }
        else
        {
            UIView.animate(withDuration: 0.5)
            {
                self.FilterLabel.alpha = 0.5
                self.FilterLabel.textColor = UIColor.black
                self.FilterLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
            }
        }
    }
    
    var FilterLabelIsVisible: Bool = false
    
    var ShowNormalSaveAlert: Bool = false
    
    @IBOutlet weak var SaveButton: UIBarButtonItem!
    
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
    
    #if false
    //https://stackoverflow.com/questions/44864432/saving-to-user-photo-library-silently-fails
    func DoSaveImage()
    {
        
        if _Settings.bool(forKey: "SaveOriginalImage")
        {
            UIImageWriteToSavedPhotosAlbum(OriginalImageToSave!, nil, nil, nil)
        }
        if Filters?.CurrentFilterType != .PassThrough
        {
            let SaveMe = FinalizeImage(PreviewImage)
            UIImageWriteToSavedPhotosAlbum(SaveMe, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    #endif
    
    @IBOutlet weak var FilterButton: UIBarButtonItem!
    
    @IBAction func HandleFilterButtonPressed(_ sender: Any)
    {
        UpdateFilterSelectionVisibility()
    }
    
    @IBOutlet weak var OutputView2: PreviewMetalView!
    
    var PreviewImage: UIImage!
    
    @IBOutlet weak var BackgroundView: UIView!
    @IBOutlet var MainUIView: UIView!
    
    
    @IBAction func HandlePhotoAlbumButtonPressed(_ sender: Any)
    {
    }
    
    @IBOutlet weak var PhotoAlbumButton: UIBarButtonItem!
    
    @IBAction func HandleSettingsButtonPressed(_ sender: Any)
    {
        performSegue(withIdentifier: "ToSettings", sender: self)
    }
    
    @IBOutlet weak var StatusLabel: UILabel!
    
    @IBOutlet weak var FilterLabel: UILabel!
    
    @IBOutlet weak var MainBottomToolbar: UIToolbar!
    
    private class func JpegData(WithPixelBuffer PixelBuffer: CVPixelBuffer, Attachments: CFDictionary?) -> Data?
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
    
    // MARK: Filter collection view code.
    
    func UpdateFilterSelectionVisibility()
    {
        if FiltersAreShowing
        {
            UIView.animate(withDuration: 0.4)
            {
                self.FilterCollectionView.frame = self.HiddenFilter
                self.GroupCollectionView.frame = self.GroupHidden
            }
            FiltersAreShowing = false
        }
        else
        {
            FilterCollectionView.isHidden = false
            GroupCollectionView.isHidden = false
            UIView.animate(withDuration: 0.25)
            {
                self.FilterCollectionView.frame = self.FilterRect
                self.GroupCollectionView.frame = self.GroupRect
            }
            FiltersAreShowing = true
            FilterCollectionView.reloadData()
            GroupCollectionView.reloadData()
        }
    }
    
    var FiltersAreShowing = false
    
    func InitializeFilterSelector()
    {
        MainBottomToolbar.layer.zPosition = 1000
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        LastSelectedItem = 0
        FilterCollectionView.register(FilterCollectionCell.self, forCellWithReuseIdentifier: "FilterItem")
        FilterCollectionView.allowsSelection = true
        FilterCollectionView.allowsMultipleSelection = false
        FilterCollectionView.layer.zPosition = 501
        FilterRect = FilterCollectionView.frame
        HiddenFilter = CGRect(x: FilterCollectionView.frame.minX, y: view.frame.height,
                              width: FilterCollectionView.frame.width, height: FilterCollectionView.frame.height)
        UIView.animate(withDuration: 0.1) {
            self.FilterCollectionView.frame = self.HiddenFilter
        }
        FilterCollectionView.isHidden = true
        FilterCollectionView.delegate = self
        FilterCollectionView.dataSource = self
        FilterCollectionView.layer.borderWidth = 0.5
        FilterCollectionView.layer.borderColor = UIColor.white.cgColor
        FilterCollectionView.layer.cornerRadius = 5.0
        FilterCollectionView.clipsToBounds = true
        FilterCollectionView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.35)
        
        LastSelectedGroup = 0
        GroupCollectionView.register(FilterCollectionCell.self, forCellWithReuseIdentifier: "GroupCell")
        GroupCollectionView.allowsSelection = true
        GroupCollectionView.allowsMultipleSelection = false
        GroupCollectionView.layer.zPosition = 500
        GroupRect = GroupCollectionView.frame
        GroupHidden = CGRect(x: GroupCollectionView.frame.minX, y: view.frame.height,
                             width: GroupCollectionView.frame.width, height: GroupCollectionView.frame.height)
        UIView.animate(withDuration: 0.1) {
            self.GroupCollectionView.frame = self.GroupHidden
        }
        GroupCollectionView.isHidden = true
        GroupCollectionView.delegate = self
        GroupCollectionView.dataSource = self
        GroupCollectionView.layer.borderWidth = 0.5
        GroupCollectionView.layer.borderColor = UIColor.white.cgColor
        GroupCollectionView.layer.cornerRadius = 5.0
        GroupCollectionView.clipsToBounds = true
        GroupCollectionView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.35)
        
        GroupTitles = Filters!.GetGroupNames()
        GroupTitles!.sort{$0.2 < $1.2}
        MakeGroupData(GroupTitles!)
        CurrentGroupFilters = (Filters?.FiltersForGroup(GroupNodes[0].GroupType))!
        GroupNodes[0].IsSelected = true
    }
    
    func MakeGroupData(_ FilterGroupList: [(String, FilterGroups, Int)])
    {
        GroupNodes = [GroupDataBlock]()
        GroupCount = FilterGroupList.count
        let AScalar = "A".unicodeScalars.last!
        let CharIndex = AScalar.value
        for Index in 0 ..< GroupCount
        {
            let Group = GroupDataBlock()
            let TheGroup = FilterGroupList[Index].1
            Group.Color = (Filters?.ColorForGroup(TheGroup))!
            Group.GroupType = TheGroup
            let NewScalar = CharIndex + UInt32(Index)
            Group.Title = FilterGroupList[Index].0
            Group.Prefix = String(Character(UnicodeScalar(NewScalar)!))
            Group.ID = Index
            Group.IsSelected = false
            GroupNodes.append(Group)
        }
    }
    
    var GroupCount = 0
    
    var FilterRect: CGRect!
    var HiddenFilter: CGRect!
    var GroupRect: CGRect!
    var GroupHidden: CGRect!
    
    @IBOutlet weak var GroupCollectionView: UICollectionView!
    @IBOutlet weak var FilterCollectionView: UICollectionView!
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if collectionView == FilterCollectionView
        {
            if LastSelectedGroup < 0
            {
                return 0
            }
            let FilterCount: Int = (Filters?.FiltersForGroup(GroupNodes[LastSelectedGroup].GroupType).count)!
            return FilterCount
        }
        if collectionView == GroupCollectionView
        {
            return GroupCount
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        if collectionView == FilterCollectionView
        {
            let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterItem", for: indexPath) as UICollectionViewCell
            var FilterCell: FilterCollectionCell!
            FilterCell = Cell as? FilterCollectionCell
            let TheFilter = CurrentGroupFilters[indexPath.row]
            let Title = Filters!.GetFilterTitle(TheFilter)
            FilterCell.SetCellValue(Title: Title, IsSelected: false, ID: indexPath.row, IsGroup: false,
                                    Color: GroupNodes[LastSelectedGroup].Color)
            if GroupWithSelectedFilter != LastSelectedGroup
            {
                FilterCell.SetSelectionState(Selected: false)
            }
            else
            {
                FilterCell.SetSelectionState(Selected: LastSelectedItem == indexPath.row)
            }
            return FilterCell
        }
        else
        {
            let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath) as UICollectionViewCell
            var GroupCell: FilterCollectionCell!
            GroupCell = Cell as? FilterCollectionCell
            GroupCell.SetCellValue(Title: GroupNodes[indexPath.row].Title, IsSelected: false, ID: indexPath.row,
                                   IsGroup: true, Color: GroupNodes[indexPath.row].Color)
            GroupCell.SetSelectionState(Selected: GroupNodes[indexPath.row].IsSelected)
            return GroupCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if collectionView == FilterCollectionView
        {
            if LastSelectedItem > -1
            {
                collectionView.deselectItem(at: IndexPath(index: LastSelectedItem), animated: true)
            }
            LastSelectedItem = indexPath.row
            guard let Cell = collectionView.cellForItem(at: indexPath) else
            {
                return
            }
            let SelectedCell = Cell as! FilterCollectionCell
            SelectedCell.SetSelectionState(Selected: true)
            GroupWithSelectedFilter = LastSelectedGroup
            let Current = CurrentGroupFilters[LastSelectedItem]
            let NewTitle = Filters!.GetFilterTitle(Current)
            print("Selected \(NewTitle)")
        }
        if collectionView == GroupCollectionView
        {
            LastSelectedGroup = indexPath.row
            CurrentGroupFilters = (Filters?.FiltersForGroup(GroupNodes[LastSelectedGroup].GroupType))!
            GroupNodes.forEach{$0.IsSelected = false}
            GroupNodes[indexPath.row].IsSelected = true
            GroupCollectionView.reloadData()
            FilterCollectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
    {
        if collectionView == FilterCollectionView
        {
            guard let Cell = collectionView.cellForItem(at: indexPath) else
            {
                return
            }
            let SelectedCell = Cell as! FilterCollectionCell
            SelectedCell.SetSelectionState(Selected: false)
        }
    }
    
    var GroupWithSelectedFilter = -1
    var LastSelectedGroup: Int = -1
    var LastSelectedItem: Int = -1
    var CurrentGroupFilters = [FilterNames]()
    var GroupNodes = [GroupDataBlock]()
    var FilterNodes = [GroupDataBlock]()
    var GroupTitles: [(String, FilterGroups, Int)]? = nil
}

