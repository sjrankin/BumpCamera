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

/// Code to run the main UI for the Bumpy Camera. Large sections of the code for the UI are in extensions to the MainUIView class.
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
class MainUIViewer: UIViewController,
    AVCapturePhotoCaptureDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureDepthDataOutputDelegate,
    AVCaptureDataOutputSynchronizerDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource
{
    let _Settings = UserDefaults.standard
    
    var MaskLineSize: Double = 5.0
    var BlockSize: Double = 20.0
    var OnSimulator = false
    var Filters: FilterManager? = nil
    var VideoIsAuthorized = false
    var DepthDataSupported = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        VideoIsAuthorized = CheckAuthorization()
        //Filters must be created before checking for settings.
        Filters = FilterManager(FilterManager.FilterTypes.PassThrough)
        if !_Settings.bool(forKey: "SettingsInstalled")
        {
            InitializeSettings()
        }
        InitializeFilterUIData()
        ParameterManager.Initialize(Filters: Filters!, Preload: true)
        DepthDataSupported = PhotoOutput.isDepthDataDeliverySupported
        print("DepthDataSupported = \(DepthDataSupported)")
        
        InitializeFilterSelector()
        #if targetEnvironment(simulator)
        OnSimulator = true
        #endif
        AddGridOverlayLayer()
        setNeedsStatusBarAppearanceUpdate()
        let Tap = UITapGestureRecognizer(target: self, action: #selector(HandlePreviewTap))
        Tap.numberOfTapsRequired = 1
        self.LiveView.addGestureRecognizer(Tap)
        
        InitializeLabels()
        
        //Make sure the file structure is OK...
        if FileHandler.DirectoryExists(DirectoryName: FileHandler.SampleDirectory)
        {
            print("\(FileHandler.SampleDirectory) already exists.")
        }
        else
        {
            let SampleURL = FileHandler.CreateDirectory(DirectoryName: FileHandler.SampleDirectory)
            if SampleURL == nil
            {
                print("Error creating \(FileHandler.SampleDirectory)")
            }
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
                self.ConfigureLiveView()
        }
        StartSettingsMonitor()
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
                let Rotation = LiveMetalView.Rotation(with: InterfaceOrientation, videoOrientation: VideoOrientation,
                                                      cameraPosition: VideoDevicePosition)
                print("Video position is front: \(VideoDevicePosition == .front)")
                self.LiveView.mirroring = (VideoDevicePosition == .front)
                if let Rotation = Rotation
                {
                    self.LiveView.rotation = Rotation
                }
                self.RenderingEnabled = true
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
                
            case .ConfigurationFailed:
                DispatchQueue.main.async {
                    let Message = "Unable to capture media."
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
                self.PhotoOutput.capturePhoto(with: Settings, delegate: self)
        }
    }
    
    @IBOutlet weak var SaveButton: UIBarButtonItem!
    
    @IBOutlet weak var FilterButton: UIBarButtonItem!
    
    @IBAction func HandleFilterButtonPressed(_ sender: Any)
    {
        UpdateFilterSelectionVisibility()
    }
    
    @IBOutlet weak var LiveView: LiveMetalView!
    
    var PreviewImage: UIImage!
    
    @IBOutlet weak var BackgroundView: UIView!
    @IBOutlet var MainUIView: UIView!
    
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
    
    @IBAction func HandleSettingsButtonPressed(_ sender: Any)
    {
        performSegue(withIdentifier: "ToSettings", sender: self)
    }
    
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
    
    @IBOutlet weak var GroupCollectionView: UICollectionView!
    @IBOutlet weak var FilterCollectionView: UICollectionView!
    
    /// MARK: Transient label stored properties.
    var FilterLabelIsVisible: Bool = false
    
    var SetupResult: SetupResults = .Success
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

