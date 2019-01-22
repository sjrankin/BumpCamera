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
class MainUIViewer: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureDepthDataOutputDelegate, AVCaptureDataOutputSynchronizerDelegate,
    UICollectionViewDelegate, UICollectionViewDataSource
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
        Filters = FilterManager(FilterManager.FilterTypes.Noir)
        if !_Settings.bool(forKey: "SettingsInstalled")
        {
            InitializeSettings()
        }
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
        
        //https://stackoverflow.com/questions/34883594/cant-make-uitoolbar-black-color-with-white-button-item-tint-ios-9-swift/34885377
        MainBottomToolbar.barTintColor = UIColor.black
        MainBottomToolbar.tintColor = UIColor.white
        MainBottomToolbar.sizeToFit()
        MainBottomToolbar.isTranslucent = false
        
        PrepareForLiveView()
        SessionQueue.async
            {
                self.ConfigureLiveView()
        }
        StartSettingsMonitor()
    }
    
    let BufferCount: Int = 3
    
    var WasGranted: Bool = false
    
    var StatusBarOrientation: UIInterfaceOrientation!
    
    var CaptureSessionContext = 0
    
    var RenderingEnabled = false
    
    var IsSessionRunning = false
    
    var VideoDeviceInput: AVCaptureDeviceInput!
    
    @objc func HandlePreviewTap(sender: UITapGestureRecognizer)
    {
        if sender.state == .ended
        {
            if _Settings.bool(forKey: "ShowFilterName")
            {
                let TapLocation = sender.location(in: LiveView)
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
        
        let InterfaceOrientation = UIApplication.shared.statusBarOrientation
        StatusBarOrientation = InterfaceOrientation
        let InitialThermalState = ProcessInfo.processInfo.thermalState
        if InitialThermalState == .serious || InitialThermalState == .critical
        {
            ThermalStateUserNotification(InitialThermalState)
        }
        
        SessionQueue.async {
            self.AddObservers()
            if let PhotoOrientation = AVCaptureVideoOrientation(interfaceOrientation: InterfaceOrientation)
            {
                self.PhotoOutput.connection(with: .video)!.videoOrientation = PhotoOrientation
            }
            let VideoOrientation = self.VideoDataOutput.connection(with: .video)!.videoOrientation
            let VideoDevicePosition = self.VideoDeviceInput.device.position
            let Rotation = PreviewMetalView.Rotation(with: InterfaceOrientation, videoOrientation: VideoOrientation,
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
                self.CaptureSession.stopRunning()
                self.IsSessionRunning = self.CaptureSession.isRunning
                self.RemoveObservers()
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
    
    @IBOutlet weak var LiveView: PreviewMetalView!
    
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
    
    @IBOutlet weak var GroupCollectionView: UICollectionView!
    @IBOutlet weak var FilterCollectionView: UICollectionView!
    
    /// MARK: Transient label stored properties.
    var FilterLabelIsVisible: Bool = false
}

