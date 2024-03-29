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

//// Code to run the main UI for the Bumpy Camera. Large sections of the code for the UI are in extensions to the MainUIView class.
/// - Extension map
///     - *MainUICamera*: Code to get images from the camera. Code to run the live view. Code to react to device settings changes.
///     - *MainUIPhoto*: Code related to getting and saving photos to the camera roll.
///     - *MainUISettings*: Code related to user settings and abstraction thereof.
///     - *MainUIObserving*: Code related to setting and removing as well as responding to observers. This is mostly for keeping the camera
///       in sync with the device's current state.
///     - *MainUIFilterSelection*: Code related to running the UI to allow the user to select filter groups and individual filters.
///     - *MainUIJpegDataClass*: Code for the JpegData class used for saving images.
///     - *MainUIDebug*: Debug code and visual debug code.
///     - *MainUILabelManagement*: Code related to showing and animating the visibility of transient labels on the main UI.
///     - *MainUIUserInteractions*: Code to handle taps for focus/exposure and hiding parts of the UI.
///     - *MainUIExif*: Code related to EXIF handling.
/// - Protocols
///     - *MainUIProtocol*: Used by classes to communicate with the Main UI.
///
///  - Notes:
///    - [Creating a Custom Camera View](https://github.com/codepath/ios_guides/wiki/Creating-a-Custom-Camera-View)
///    - [Swift Camera Part 1](https://medium.com/@rizwanm/https-medium-com-rizwanm-swift-camera-part-1-c38b8b773b2)
class MainUIViewer: UIViewController,
    AVCapturePhotoCaptureDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureDepthDataOutputDelegate,
    AVCaptureDataOutputSynchronizerDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    MainUIProtocol
{
    let _Settings = UserDefaults.standard
    
    var MaskLineSize: Double = 5.0
    var BlockSize: Double = 20.0
    var OnSimulator = false
    var Filters: FilterManager? = nil
    var VideoIsAuthorized = false
    var DepthDataSupported = false
    var ADelegate: AppDelegate? = nil
    var OnDebugger = false
    var StartUpTime: Date!
    var ExternalScreen: UIScreen? = nil
    var ExternalWindow: UIWindow? = nil
    var HaveExternalDisplay: Bool = false
    var ExVC: ExternalViewControllerCode? = nil
    var Windows = [UIWindow]()
    
    /// Main setup.
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        StartUpTime = Date()
        
        let NC = NetComm()
        
        HaveExternalDisplay = FindExternalDisplay()
        print("Found external display: \(HaveExternalDisplay)")
        if HaveExternalDisplay
        {
            ConnectToExternalDisplay(ExScreen: ExternalScreen!)
        }
        
        NotificationCenter.default.addObserver(forName: UIScreen.didConnectNotification,
                                               object: nil,
                                               queue: nil)
        {
            (notification) in
            print("External display connected.")
            self.ExternalScreen = notification.object as? UIScreen
        }
        NotificationCenter.default.addObserver(forName: UIScreen.didDisconnectNotification,
                                               object: nil,
                                               queue: nil)
        {
            (notification) in
            print("External display disconnected.")
            let Screen = notification.object as? UIScreen
            self.DisconnectFromExternalDisplay(ExScreen: Screen!)
        }
        
        MainBottomToolbar.layer.zPosition = 1000
        MainBottomToolbar.layer.borderColor = UIColor.white.cgColor
        MainBottomToolbar.layer.borderWidth = 0.5
        
        FrameCountLabel.textColor = UIColor.clear
        FrameCountLabel.backgroundColor = UIColor.clear
        FPSLabel.textColor = UIColor.clear
        FPSLabel.backgroundColor = UIColor.clear
        
        ADelegate = UIApplication.shared.delegate as? AppDelegate
        
        OnDebugger = (ADelegate?.OnDebugger)!
        print("OnDebugger=\(OnDebugger)")
        
        VideoIsAuthorized = CheckAuthorization()
        //Filters must be created before checking for settings.
        FilterManager.LoadFilterRatings(self)
        ADelegate!.Filters = FilterManager(FilterManager.FilterTypes.PassThrough)
        Filters = ADelegate!.Filters
        //Filters = FilterManager(FilterManager.FilterTypes.PassThrough)
        if !_Settings.bool(forKey: "SettingsInstalled")
        {
            InitializeSettings()
        }
        InitializeFilterUIData()
        ParameterManager.Initialize(Filters: Filters!, Preload: true)
        DepthDataSupported = PhotoOutput.isDepthDataDeliverySupported
        print("DepthDataSupported = \(DepthDataSupported)")
        
        FilterCollectionView.register(FilterCollectionCell.self, forCellWithReuseIdentifier: "FilterItem")
        GroupCollectionView.register(FilterCollectionCell.self, forCellWithReuseIdentifier: "GroupCell")
        
        AvailableBottom = MainBottomToolbar.frame.minY - 1
        InitializeFilterSelector()
        #if targetEnvironment(simulator)
        OnSimulator = true
        #endif
        AddGridOverlayLayer()
        setNeedsStatusBarAppearanceUpdate()
        let Tap = UITapGestureRecognizer(target: self, action: #selector(HandlePreviewTap))
        Tap.numberOfTapsRequired = 1
        self.LiveView.addGestureRecognizer(Tap)
        
        ModeSelection.Initialize(SelectedButton: _Settings.integer(forKey: "ProgramMode"), TopOfToolBar: MainBottomToolbar.frame.minY)
        ModeSelection.MainDelegate = self
        if !_Settings.bool(forKey: "ShowModeUI")
        {
            DoHandleModeButtonPressed(Duration: 0.001)
        }
        InitializeLabels()
        
        //Make sure the file structure is OK... If not, create expected directories.
        if !FileHandler.CreateIfDoesNotExist(DirectoryName: FileHandler.SampleDirectory)
        {
            ShowFatalErrorMessage(Title: "Directory Error", Message: "Error getting or setting the sample directory. Unable to continue.")
            fatalError("Error creating \(FileHandler.SampleDirectory).")
        }
        if !FileHandler.CreateIfDoesNotExist(DirectoryName: FileHandler.ScratchDirectory)
        {
            ShowFatalErrorMessage(Title: "Directory Error", Message: "Error getting or setting the scratch directory. Unable to continue.")
            fatalError("Error creating \(FileHandler.ScratchDirectory).")
        }
        if !FileHandler.CreateIfDoesNotExist(DirectoryName: FileHandler.PerformanceDirectory)
        {
            ShowFatalErrorMessage(Title: "Directory Error", Message: "Error getting or setting the performance directory. Unable to continue.")
            fatalError("Error creating \(FileHandler.PerformanceDirectory).")
        }
        if !FileHandler.CreateIfDoesNotExist(DirectoryName: FileHandler.RuntimeDirectory)
        {
            ShowFatalErrorMessage(Title: "Directory Error", Message: "Error getting or setting the runtime directory. Unable to continue.")
            fatalError("Error creating \(FileHandler.SampleDirectory).")
        }
        #if DEBUG
        if !FileHandler.CreateIfDoesNotExist(DirectoryName: FileHandler.DebugDirectory)
        {
            ShowFatalErrorMessage(Title: "Directory Error", Message: "Error getting or setting the debug directory. Unable to continue.")
        }
        #endif
        ActivityLog.Initialize(TimeStamp: Date())
        
        if _Settings.bool(forKey: "ClearRuntimeAtStartup")
        {
            FileHandler.ClearDirectory(FileHandler.RuntimeDirectory)
        }
        if _Settings.bool(forKey: "ClearScratchAtStartup")
        {
            FileHandler.ClearDirectory(FileHandler.ScratchDirectory)
        }
        
        //https://stackoverflow.com/questions/34883594/cant-make-uitoolbar-black-color-with-white-button-item-tint-ios-9-swift/34885377
        MainBottomToolbar.barTintColor = UIColor.black
        MainBottomToolbar.tintColor = UIColor.white
        MainBottomToolbar.sizeToFit()
        MainBottomToolbar.isTranslucent = false
        
        switch AVCaptureDevice.authorizationStatus(for: .video)
        {
        case .authorized:
            break;
            
        case .notDetermined:
            SessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler:
                {
                    granted in
                    if !granted
                    {
                        self.SetupResult = .NotAuthorized
                    }
                    self.SessionQueue.resume()
            })
            
        default:
            SetupResult = .NotAuthorized
        }
        
        PrepareForLiveView()
        SessionQueue.async
            {
                self.SetupResult = self.ConfigureLiveView()
        }
        StartSettingsMonitor()
        //StartHeartBeat()
    }
    
    func LoadExternalWindow(With: UIWindow)
    {
        ExVC = UIStoryboard(name: "ExternalViewController", bundle: nil).instantiateInitialViewController() as? ExternalViewControllerCode
        With.rootViewController = ExVC
    }
    
    func ConnectToExternalDisplay(ExScreen: UIScreen)
    {
        let Dimensions = ExScreen.bounds
        ExternalWindow = UIWindow(frame: Dimensions)
        LoadExternalWindow(With: ExternalWindow!)
        ExternalWindow?.isHidden = false
        ExternalWindow?.makeKeyAndVisible()
        Windows.append(ExternalWindow!)
    }
    
    func DisconnectFromExternalDisplay(ExScreen: UIScreen)
    {
        for Window in self.Windows
        {
            if Window.screen == ExScreen
            {
                let Index = Windows.firstIndex(of: Window)
                Windows.remove(at: Index!)
                break
            }
        }
    }
    
    /// Find external displays.
    ///
    /// - Returns: True if an external display was found and "created", false if not.
    func FindExternalDisplay() -> Bool
    {
        if UIScreen.screens.count == 1
        {
            return false
        }
        ExternalScreen = UIScreen.screens[1]
        return true
    }
    
    /// Start the heartbeat timer.
    func StartHeartBeat()
    {
        if HeartBeatTimer != nil
        {
            HeartBeatTimer?.invalidate()
            HeartBeatTimer = nil
        }
        if _Settings.bool(forKey: "EnableHeartBeat")
        {
            //DispatchSourceTimer
            ActivityLog.LogMessage("Started heartbeat timer.")
            let Interval = _Settings.integer(forKey: "HeartBeatInterval")
            if Interval <= 0
            {
                ActivityLog.LogMessage("Heart beat timer enabled but invalid interval. No action taken.")
                return
            }
            HeartBeatTimer = Timer.scheduledTimer(timeInterval: Double(Interval), target: self, selector: #selector(HandleHeartBeatEvent), userInfo: nil, repeats: true)
        }
    }
    
    func StopHeartBeat()
    {
        ActivityLog.LogMessage("Stopped heartbeat timer.")
        if HeartBeatTimer != nil
        {
            HeartBeatTimer?.invalidate()
            HeartBeatTimer = nil
        }
    }
    
    @objc func HandleHeartBeatEvent()
    {
        DispatchQueue.main.async
            {
                ActivityLog.LogMessage("Bump camera heart beat.")
        }
    }
    
    func InstanceFilterManager() -> FilterManager?
    {
        return Filters
    }
    
    var HeartBeatTimer: Timer? = nil
    
    @IBOutlet weak var ModeSelection: ModeSelectorUI!
    
    var ShowedCrashDialog = false
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if ShowedCrashDialog
        {
            return
        }
        if (ADelegate?.DidCrash)!
        {
            ShowedCrashDialog = true
            #if DEBUG
            if _Settings.bool(forKey: "IgnorePriorCrashes")
            {
                return
            }
            #endif
            let PreviousFilter: String = (ADelegate?.CrashedFilterName)!
            #if DEBUG
            _Settings.set(PreviousFilter, forKey: "LastCrashedFilter")
            #endif
            var AlertTitle = "Crash Detected"
            var LastSentence = ""
            if OnDebugger
            {
                AlertTitle = "Possible Crash Detected"
                LastSentence = " Because you were running with the debugger, it's possible the debugger closed BumpCamera uncleanly."
            }
            let Alert = UIAlertController(title: AlertTitle,
                                          message: "BumpCamera crashed the last time it ran. (Previous filter: \(PreviousFilter).) Resetting the filter to Pass Through." + LastSentence,
                                          preferredStyle: UIAlertController.Style.alert)
            Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            present(Alert, animated: true)
        }
    }
    
    /// Handles changes to user favorites and settings.
    func UserFavoritesChanged()
    {
        let OldFiltersShowing = FiltersAreShowing
        if FiltersAreShowing
        {
            HideFilterUI(WithDuration: 0.1)
        }
        GroupData.LoadFavoriteFilters(ForTargets: [.LiveView])
        GroupData.LoadFiveStarFilters(ForTargets: [.LiveView])
        if OldFiltersShowing
        {
            ShowFilterUI(WithDuration: 0.1)
        }
    }
    
    func ShowFatalErrorMessage(Title: String, Message: String)
    {
        let Alert = UIAlertController(title: Title, message: Message, preferredStyle: UIAlertController.Style.alert)
        Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        present(Alert, animated: true)
    }
    
    let BufferCount: Int = 3
    
    var WasGranted: Bool = false
    
    var StatusBarOrientation: UIInterfaceOrientation = .portrait
    
    var CaptureSessionContext = 0
    
    var RenderingEnabled = false
    
    var IsSessionRunning = false
    
    var VideoDeviceInput: AVCaptureDeviceInput!
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        let InterfaceOrientation = UIApplication.shared.statusBarOrientation
        StatusBarOrientation = InterfaceOrientation
        let InitialThermalState = ProcessInfo.processInfo.thermalState
        if InitialThermalState == .serious || InitialThermalState == .critical
        {
            ThermalStateUserNotification(InitialThermalState)
        }
        
        SessionQueue.async {
            switch self.SetupResult
            {
            case .Success:
                self.AddObservers()
                if let PhotoOrientation = AVCaptureVideoOrientation(interfaceOrientation: InterfaceOrientation)
                {
                    self.PhotoOutput.connection(with: .video)!.videoOrientation = PhotoOrientation
                }
                let VideoOrientation = self.VideoDataOutput.connection(with: .video)!.videoOrientation
                let VideoDevicePosition = self.VideoDeviceInput.device.position
                let Rotation = LiveMetalView.Rotation(with: InterfaceOrientation,
                                                      videoOrientation: VideoOrientation,
                                                      cameraPosition: VideoDevicePosition)
                self.LiveView.mirroring = (VideoDevicePosition == .front)
                if let Rotation = Rotation
                {
                    self.LiveView.rotation = Rotation
                }
                self.DataOutputQueue.async
                    {
                        self.RenderingEnabled = true
                }
                self.CaptureSession.startRunning()
                self.IsSessionRunning = self.CaptureSession.isRunning
                
            case .NotAuthorized:
                DispatchQueue.main.async {
                    let Message = "BumpCamera does not have permission to use the camera. Please change in your privacy settings."
                    let Alert = UIAlertController(title: "BumpCamera", message: Message, preferredStyle: .alert)
                    Alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    Alert.addAction(UIAlertAction(title: "Settings", style: .default, handler:
                        {
                            _ in
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                      options: [:],
                                                      completionHandler: nil)
                    }))
                    self.present(Alert, animated: true, completion: nil)
                }
                
            case .ConfigurationFailed(let Reason):
                DispatchQueue.main.async {
                    let Message = Reason
                    print(Message)
                    let Alert = UIAlertController(title: "BumpCamera", message: Message, preferredStyle: .alert)
                    Alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(Alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    var GridLayerIsShowing: Bool = false
    var GridLayer: CAShapeLayer? = nil
    
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
        DataOutputQueue.async
            {
                self.RenderingEnabled = false
        }
        SessionQueue.async
            {
                if self.SetupResult == .Success
                {
                    self.CaptureSession.stopRunning()
                    self.IsSessionRunning = self.CaptureSession.isRunning
                    self.RemoveObservers()
                }
        }
        super.viewWillDisappear(animated)
    }
    
    var InLandscape: Bool = false
    
    var BGTimer: Timer!
    
    var GBackground: BackgroundServer!
    
    @objc func UpdateBackground()
    {
        GBackground.UpdateBackgroundColors()
    }
    
    #if false
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
    #endif
    
    let VideoDataOutput = AVCaptureVideoDataOutput()
    let PhotoOutput = AVCapturePhotoOutput()
    
    let VideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,
                                                                                     .builtInWideAngleCamera],
                                                                       mediaType: .video,
                                                                       position: .unspecified)
    
    
    let SessionQueue = DispatchQueue(label: "SessionQueue", attributes: [], autoreleaseFrequency: .workItem)
    let ProcessingQueue = DispatchQueue(label: "PhotoProcessingQueue", attributes: [], autoreleaseFrequency: .workItem)
    let DataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [],
                                        autoreleaseFrequency: .workItem)
    var VideoOutput = AVCaptureVideoDataOutput()
    var CaptureSession: AVCaptureSession = AVCaptureSession()
    var VideoPreviewLayer: AVCaptureVideoPreviewLayer? = nil
    var CapturePhotoOutput: AVCapturePhotoOutput?
    var OutputSynchronizer: AVCaptureDataOutputSynchronizer? = nil
    var DepthDataOutput = AVCaptureDepthDataOutput()
    var CurrentDepthPixelBuffer: CVPixelBuffer? = nil
    let VideoDepthConverter = DepthToGrayscaleConverter()
    let PhotoDepthConverter = DepthToGrayscaleConverter()
    let PhotoDepthMixer = VideoMixer()
    let VideoDepthMixer = VideoMixer()
    
    //https://stackoverflow.com/questions/39060171/switching-camera-with-a-button-in-swift
    @IBAction func HandleCameraSwitchButtonPressed(_ sender: Any)
    {
        DoSwitchCameras()
    }
    
    @IBOutlet weak var CameraSwitchButton: UIBarButtonItem!
    
    @IBAction func HandleSaveButtonPressed(_ sender: Any)
    {
        if OnSimulator
        {
            ShowMessage("Cannot save - on simulator.")
            return
        }
        SessionQueue.async
            {
                let Settings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
                if self.DepthDataSupported && self.PhotoOutput.isDepthDataDeliverySupported
                {
                    Settings.isDepthDataDeliveryEnabled = true
                    Settings.embedsDepthDataInPhoto = false
                }
                let MetaData = Settings.metadata
                self.PhotoOutput.capturePhoto(with: Settings, delegate: self)
        }
    }
    
    @IBOutlet weak var SaveButton: UIBarButtonItem!
    
    @IBOutlet weak var FilterButton: UIBarButtonItem!
    
    @IBAction func HandleFilterButtonPressed(_ sender: Any)
    {
        if FiltersAreShowing
        {
            HideFilterUI()
        }
        else
        {
            ShowFilterUI()
        }
    }
    
    @IBOutlet weak var LiveView: LiveMetalView!
    
    var PreviewImage: UIImage!
    
    @IBOutlet weak var BackgroundView: UIView!
    @IBOutlet var MainUIView: UIView!
    
    // MARK: Mode selection and UI.
    
    /// Sets the enable state on bottom toolbar buttons. The first button is not changed. This function should be called
    /// when the user opens the mode UI and called again when the mode UI closes.
    ///
    /// - Parameter To: Value to set the enable state to.
    func SetButtonEnableState(To: Bool)
    {
        let ButtonCount = MainBottomToolbar.items!.count
        for Index in 1 ..< ButtonCount
        {
            let Item = MainBottomToolbar.items![Index]
            Item.isEnabled = To
        }
    }
    
    func ModeButtonPressed(ButtonType: CameraModeTypes)
    {
        switch ButtonType
        {
        case .About:
            performSegue(withIdentifier: "ToSettings", sender: self)
            
        case .Editor:
            _Settings.set(3, forKey: "ProgramMode")
            
        case .GIF:
            _Settings.set(2, forKey: "ProgramMode")
            
        case .LiveView:
            _Settings.set(0, forKey: "ProgramMode")
            
        case .OnTheFly:
            _Settings.set(4, forKey: "ProgramMode")
            
        case .Video:
            _Settings.set(1, forKey: "ProgramMode")
        }
    }
    
    func DoHandleModeButtonPressed(Duration: Double? = nil)
    {
        if ModeUIShowing
        {
            //Hide mode UI.
            var FinalDuration = 0.3
            if Duration != nil
            {
                FinalDuration = Duration!
            }
            ModeSelection.Hide(Duration: FinalDuration)
            SetButtonEnableState(To: true)
            ModeUIShowing = false
            ModeSelectorButton.image = UIImage(named: "ModeOpen")
            _Settings.set(false, forKey: "ShowModeUI")
        }
        else
        {
            //Show mode UI.
            var FinalDuration = 0.3
            if Duration != nil
            {
                FinalDuration = Duration!
            }
            ModeSelection.Show(Duration: FinalDuration)
            if FiltersAreShowing
            {
                HideFilterUI()
            }
            SetButtonEnableState(To: false)
            ModeUIShowing = true
            ModeSelectorButton.image = UIImage(named: "ModeClose")
            _Settings.set(true, forKey: "ShowModeUI")
        }
    }
    
    @IBAction func HandleModeButtonPressed(_ sender: Any)
    {
        DoHandleModeButtonPressed()
    }
    
    @IBOutlet weak var ModeSelectorButton: UIBarButtonItem!
    var ModeUIShowing: Bool = true
    var ModeRect: CGRect!
    var HiddenMode: CGRect!
    var ModeList = [UIModes]()
    
    // MARK: Current filter settings button.
    
    @IBAction func HandleCurrentFilterSettingsPressed(_ sender: Any)
    {
        if let RawID = _Settings.string(forKey: "CurrentFilter")
        {
            if let FilterID = UUID(uuidString: RawID)
            {
                let TypeOfFilter = FilterManager.GetFilterTypeFrom(ID: FilterID)
                if TypeOfFilter == nil
                {
                    print("Error getting filter type.")
                    return
                }
                _Settings.set(TypeOfFilter!.rawValue, forKey: "SetupForFilterType")
                if let StoryboardName = FilterManager.StoryboardFor(TypeOfFilter!)
                {
                    print("Filter \((TypeOfFilter)!) storyboard name is \(StoryboardName) at \(CACurrentMediaTime())")
                    let Storyboard = UIStoryboard(name: StoryboardName, bundle: nil)
                    if let Controller = Storyboard.instantiateViewController(withIdentifier: StoryboardName) as? UINavigationController
                    {
                        print("Filter \((TypeOfFilter)!) after instantiation at \(CACurrentMediaTime())")
                        DispatchQueue.main.async
                            {
                                self.present(Controller, animated: true, completion: nil)
                        }
                    }
                    else
                    {
                        print("Error instantiating storyboard \(StoryboardName)")
                    }
                }
                else
                {
                    print("No storyboard name available for \((TypeOfFilter)!)")
                }
            }
            else
            {
                print("Error parsing current filter ID.")
            }
        }
        else
        {
            print("Error getting ID of current filter.")
        }
    }
    
    /// Update the frame count display. The frame count is updated by one every time this function is called. This
    /// is intended as a debug display and should not be used in production code.
    ///
    /// - Note: To prevent the code from being useful when compiled for release, most of this function is surrounded by
    ///         `#if DEBUG` to prevent it from being included. The only code executed here in release versions is code to
    ///         hide the controls.
    func UpdateFrameCount()
    {
        FrameCount = FrameCount + 1
        
        #if DEBUG
        DispatchQueue.main.async
            {
                if self._Settings.bool(forKey: "ShowFramerateOverlay")
                {
                    self.FrameCountLabel.textColor = UIColor.white
                    self.FrameCountLabel.backgroundColor = UIColor.black
                    self.FPSLabel.textColor = UIColor.white
                    self.FPSLabel.backgroundColor = UIColor.black
                    
                    if self.StartedUpdatingFrameCounts
                    {
                        let Now = Date()
                        let SecondsDelta = Now.timeIntervalSince(self.LastUpdateTime)
                        if SecondsDelta >= 1.0
                        {
                            self.LastUpdateTime = Now
                            let FrameDelta = self.FrameCount - self.LastFrameCount
                            self.LastFrameCount = self.FrameCount
                            let FPS = Double(FrameDelta) / SecondsDelta
                            self.FPSLabel.text = "\(FPS.Round(To: 1)) fps"
                        }
                    }
                    else
                    {
                        self.StartedUpdatingFrameCounts = true
                        self.LastUpdateTime = Date()
                        self.FPSLabel.text = ""
                    }
                    let Final = Utility.ReduceBigNum(BigNum: Int64(self.FrameCount), AsBytes: false, ReturnUnchangedThreshold: 1000000)
                    self.FrameCountLabel.text = "\(Final)"
                }
                else
                {
                    //Reset the UI and frame counting to initial, non-visible states.
                    self.FrameCountLabel.textColor = UIColor.clear
                    self.FrameCountLabel.backgroundColor = UIColor.clear
                    self.FPSLabel.textColor = UIColor.clear
                    self.FPSLabel.backgroundColor = UIColor.clear
                    self.StartedUpdatingFrameCounts = false
                    self.FrameCount = 0
                }
        }
        #else
        DispatchQueue.main.async
            {
                self.FrameCountLabel.textColor = UIColor.clear
                self.FrameCountLabel.backgroundColor = UIColor.clear
                self.FPSLabel.textColor = UIColor.clear
                self.FPSLabel.backgroundColor = UIColor.clear
        }
        #endif
    }
    
    var FrameCount: Int = 0
    var LastUpdateTime: Date!
    var LastFrameCount: Int = 0
    var StartedUpdatingFrameCounts = false
    
    @IBOutlet weak var FPSLabel: UILabel!
    @IBOutlet weak var FrameCountLabel: UILabel!
    @IBOutlet weak var StatusLabel: UILabel!
    @IBOutlet weak var FilterLabel: UILabel!
    @IBOutlet weak var MainBottomToolbar: UIToolbar!
    
    /// MARK: Stored properties for filter selection extension.
    var FiltersAreShowing = false
    var GroupCount = 0
    var FilterCount = 0
    var FilterRect: CGRect!
    var HiddenFilter: CGRect!
    var GroupRect: CGRect!
    var GroupHidden: CGRect!
    var GroupWithSelectedFilter = -1
    var LastSelectedGroup: Int = -1
    var LastSelectedItem: Int = -1
    var CurrentGroupFilters = [FilterManager.FilterTypes]()
    var GroupNodes = [FilterSelectorBlock]()
    var FilterNodes = [FilterSelectorBlock]()
    var GroupTitles: [(String, FilterManager.FilterGroups, Int)]? = nil
    var HideTimer: Timer? = nil
    var LastSelectedFilterID: UUID? = nil
    var GroupData: GroupNodeManager!
    
    var PreviousTime: Double = CACurrentMediaTime()
    var SecondStart: Double = CACurrentMediaTime()
    var StartTime: Double = -1
    var HeartBeatLevel: Int = 1
    
    @IBOutlet weak var HeartBeatIndicator: UIImageView!
    @IBOutlet weak var GroupCollectionView: UICollectionView!
    @IBOutlet weak var FilterCollectionView: UICollectionView!
    
    /// MARK: Transient label stored properties.
    var FilterLabelIsVisible: Bool = false
    
    var SetupResult: SetupResults = .Success
    
    var FinalPixelBuffer: CVPixelBuffer!
    
    let UIHeight: CGFloat = 60
    let HMargin: CGFloat = 10
    let HideOffset: CGFloat = 10
    var AvailableBottom: CGFloat = 0
    let ModeIconTable: [CameraModeTypes: [String]] =
        [
            CameraModeTypes.LiveView: ["", "", "", ""],
            CameraModeTypes.GIF: ["", "", "", ""],
            CameraModeTypes.Video: ["", "", "", ""],
            CameraModeTypes.Editor: ["", "", "", ""],
            CameraModeTypes.OnTheFly: ["", "", "", ""],
    ]
    var CurrentCameraMode: CameraModeTypes = .LiveView
}

public enum SetupResults
{
    case Success
    case NotAuthorized
    case ConfigurationFailed(Reason: String)
}

extension SetupResults: Equatable
{
    public static func ==(lhs: SetupResults, rhs: SetupResults) -> Bool
    {
        switch (lhs, rhs)
        {
        case (.Success, .Success):
            return true
            
        case (.NotAuthorized, .NotAuthorized):
            return true
            
        case (.ConfigurationFailed, .ConfigurationFailed):
            return true
            
        default:
            return false
        }
    }
}

extension CALayer
{
    //https://stackoverflow.com/questions/17355280/how-to-add-a-border-just-on-the-top-side-of-a-uiview
    func AddBorder(Edge: UIRectEdge, Color: UIColor, Width: CGFloat)
    {
        let Border = CALayer()
        switch Edge
        {
        case UIRectEdge.top:
            Border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: Width)
            
        case UIRectEdge.bottom:
            Border.frame = CGRect(x: 0, y: self.frame.height - Width, width: self.frame.width, height: Width)
            
        case UIRectEdge.left:
            Border.frame = CGRect(x: 0, y: 0, width: Width, height: self.frame.height)
            
        case UIRectEdge.right:
            Border.frame = CGRect(x: self.frame.width - Width, y: 0, width: Width, height: self.frame.height)
            
        default:
            break
        }
        
        Border.backgroundColor = Color.cgColor
        self.addSublayer(Border)
    }
}
