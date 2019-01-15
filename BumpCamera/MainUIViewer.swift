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

class MainUIViewer: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate
{
    let _Settings = UserDefaults.standard
    
    var MaskLineSize: Double = 5.0
    var BlockSize: Double = 20.0
    var SaveOriginalImage: Bool = true
    var OnSimulator = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        #if targetEnvironment(simulator)
        OnSimulator = true
        #endif
        AddGridOverlayLayer()
        CommonInitialization()
        
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
        ShowFilter("Not filtered")
        
        //https://stackoverflow.com/questions/34883594/cant-make-uitoolbar-black-color-with-white-button-item-tint-ios-9-swift/34885377
        MainBottomToolbar.barTintColor = UIColor.black
        MainBottomToolbar.tintColor = UIColor.white
        MainBottomToolbar.sizeToFit()
        MainBottomToolbar.isTranslucent = false
        //OutputView.addSubview(TestLabel)
        //OutputView.bringSubviewToFront(TestLabel)
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
            OutputView.layer.addSublayer(GridLayer!)
        }
        else
        {
            if !GridLayerIsShowing
            {
                return
            }
            GridLayerIsShowing = false
            OutputView.layer.sublayers!.forEach{if $0.name == "Grid Layer"
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
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        CommonInitialization()
        StartLiveView()
        if !UsingRearCamera
        {
            print("Switching to front camera.")
            SwitchToFrontCamera()
        }
        //StartLiveView()
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
        VideoPreviewLayer!.frame = OutputView.bounds
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
    
    func StartLiveView()
    {
        if OnSimulator
        {
            return
        }
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
        let OldSession = CaptureSession?.inputs[0]
        CaptureSession?.removeInput(OldSession!)
        var NewCamera: AVCaptureDevice!
        NewCamera = AVCaptureDevice.default(for: AVMediaType.video)!
        
        if (OldSession as! AVCaptureDeviceInput).device.position == .back
        {
            UIView.transition(with: self.OutputView, duration: 0.35, options: .transitionCrossDissolve, animations:
                {
                    NewCamera = self.CameraWithPosition(.front)!
            }, completion: nil)
            UsingRearCamera = false
        }
        else
        {
            UIView.transition(with: self.OutputView, duration: 0.35, options: .transitionCrossDissolve, animations:
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
            #if true
            PreviewImage = ApplyFilter(To: Image)
            DoSaveImage()
            #else
            SetupSegue(ForImage: ApplyFilter(To: Image))
            #endif
        }
        else
        {
            print("Error converting image data to image.")
        }
    }
    
    var OriginalImageToSave: UIImage? = nil
    
    func ApplyFilter(To: UIImage) -> UIImage
    {
        switch CurrentFilter
        {
        case 0:
            //No filter.
            return To
            
        case 1:
            //TV lines
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.TVLines(To, Center: Center, Width: MaskLineSize)
            {
                return Final
            }
            fatalError("Nil image returned by TVLines")
            
        case 5:
            //Merged TV lines
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.TVLines(To, Center: Center, Width: MaskLineSize, Merged: true)
            {
                return Final
            }
            fatalError("Nil image returned by TVLines")
            
        case 2:
            //Circle lines
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.RoundLines(To, Center: Center, Width: MaskLineSize)
            {
                return Final
            }
            fatalError("Nil image returned by RoundLines")
            
        case 6:
            //Merged Circle lines
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.RoundLines(To, Center: Center, Width: MaskLineSize, Merged: true)
            {
                return Final
            }
            fatalError("Nil image returned by RoundLines")
            
        case 3:
            //Color blocks
            if let Final = ImageFilterer.ColorBlocks(To, NodeWidth: BlockSize)
            {
                return Final
            }
            fatalError("Nil image returned by ColorBlocks.")
            
        case 4:
            //Noir
            if let Final = ImageFilterer.Noir(To)
            {
                return Final
            }
            fatalError("Nil image returned by Noir.")
            
        case 7:
            //CMYK Mask
            if let Final = ImageFilterer.CMYKMask(To)
            {
                return Final
            }
            fatalError("Nil image returned by CMKY")
            
        case 8:
            //Dot screen
            if let Final = ImageFilterer.DotScreen(To, Width: MaskLineSize)
            {
                return Final
            }
            fatalError("Nil image returned by DotScreen")
            
        case 9:
            //TV and Round lines merged
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.TVRound(To, Center: Center, Width: MaskLineSize)
            {
                return Final
            }
            fatalError("Nil image returned by TVRound")
            
        case 10:
            //Merged dot screen
            if let Final = ImageFilterer.DotScreen(To, Width: MaskLineSize, Merged: true)
            {
                return Final
            }
            fatalError("Nil image returned by DotScreen")
            
        case 11:
            //Hatched screen
            if let Final = ImageFilterer.HatchedScreen(To, Width: MaskLineSize)
            {
                return Final
            }
            fatalError("Nil image returned by HatchedScreen")
            
        case 12:
            //Merge hatched screen
            if let Final = ImageFilterer.HatchedScreen(To, Width: MaskLineSize, Merged: true)
            {
                return Final
            }
            fatalError("Nil image returned by HatchedScreen")
            
        default:
            return To
        }
    }
    
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
            if ShowNormalSaveAlert
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
        FilterLabel.alpha = 1.0
        FilterLabel.textColor = UIColor.white
        FilterLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        UIView.animate(withDuration: 2.5, delay: 5.0, options: [], animations:
            {
                self.FilterLabel.alpha = 0.5
                self.FilterLabel.textColor = UIColor.lightGray
        }
            , completion: nil)
    }
    
    var ShowNormalSaveAlert: Bool = false
    
    @IBOutlet weak var SaveButton: UIBarButtonItem!
    
    func FinalizeImage(_ Source: UIImage) -> UIImage
    {
        #if true
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
    
    //https://stackoverflow.com/questions/44864432/saving-to-user-photo-library-silently-fails
    func DoSaveImage()
    {
        let SaveMe = FinalizeImage(PreviewImage)
        if SaveOriginalImage
        {
            UIImageWriteToSavedPhotosAlbum(OriginalImageToSave!, nil, nil, nil)
        }
        UIImageWriteToSavedPhotosAlbum(SaveMe, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBOutlet weak var ModeButton: UIBarButtonItem!
    
    @IBAction func HandleModeButtonPressed(_ sender: Any)
    {
        let Filters = UIAlertController(title: "Filters", message: "Select image filter.", preferredStyle: UIAlertController.Style.actionSheet)
        let Filter0 = UIAlertAction(title: TitleFor(0), style: .default, handler: FilterSelection)
        Filters.addAction(Filter0)
        let Filter1 = UIAlertAction(title: TitleFor(1), style: .default, handler: FilterSelection)
        Filters.addAction(Filter1)
        let Filter1A = UIAlertAction(title: TitleFor(5), style: .default, handler: FilterSelection)
        Filters.addAction(Filter1A)
        let Filter2 = UIAlertAction(title: TitleFor(2), style: .default, handler: FilterSelection)
        Filters.addAction(Filter2)
        let Filter7 = UIAlertAction(title: TitleFor(9), style: .default, handler: FilterSelection)
        Filters.addAction(Filter7)
        let Filter2A = UIAlertAction(title: TitleFor(6), style: .default, handler: FilterSelection)
        Filters.addAction(Filter2A)
        let Filter6 = UIAlertAction(title: TitleFor(8), style: .default, handler: FilterSelection)
        Filters.addAction(Filter6)
        let Filter6A = UIAlertAction(title: TitleFor(10), style: .default, handler: FilterSelection)
        Filters.addAction(Filter6A)
        let Filter11 = UIAlertAction(title: TitleFor(11), style: .default, handler: FilterSelection)
        Filters.addAction(Filter11)
        let Filter12 = UIAlertAction(title: TitleFor(12), style: .default, handler: FilterSelection)
        Filters.addAction(Filter12)
        let Filter3 = UIAlertAction(title: TitleFor(3), style: .default, handler: FilterSelection)
        Filters.addAction(Filter3)
        let Filter4 = UIAlertAction(title: TitleFor(4), style: .default, handler: FilterSelection)
        Filters.addAction(Filter4)
        let Filter5 = UIAlertAction(title: TitleFor(7), style: .default, handler: FilterSelection)
        Filters.addAction(Filter5)
        let Cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        Filters.addAction(Cancel)
        if let PopOver = Filters.popoverPresentationController
        {
            PopOver.barButtonItem = ModeButton
        }
        present(Filters, animated: true)
    }
    
    func TitleFor(_ Index: Int) -> String
    {
        for (Title, FilterIndex) in FilterMap
        {
            if FilterIndex == Index
            {
                return Title
            }
        }
        return "UNKNOWN"
    }
    
    var FilterMap: [String: Int] =
        [
            "No Filter": 0,
            "TV Lines": 1,
            "Round Lines": 2,
            "Color Blocks": 3,
            "Noir": 4,
            "Merged TV Lines": 5,
            "Merged Round Lines": 6,
            "CMYK Mask": 7,
            "Dot Screen": 8,
            "TV and Round Lines": 9,
            "Merged Dot Screen": 10,
            "Hatched Screen": 11,
            "Merged Hatched Screen": 12,
            ]
    
    var CurrentFilter: Int = 0
    
    @objc func FilterSelection(Action: UIAlertAction)
    {
        if let FilterID = FilterMap[Action.title!]
        {
            CurrentFilter = FilterID
            print("Current filter now \(TitleFor(CurrentFilter))")
            ShowFilter(TitleFor(CurrentFilter))
        }
        else
        {
            print("Unknown filter \"\((Action.title)!)\" encountered.")
        }
    }
    
    @IBOutlet weak var OutputView: UIImageView!
    @IBOutlet weak var OutputView2: PreviewMetalView!
    
    var PreviewImage: UIImage!
    
    @IBOutlet weak var BackgroundView: UIView!
    @IBOutlet var MainUIView: UIView!
    
    
    @IBAction func HandlePhotoAlbumButtonPressed(_ sender: Any)
    {
    }
    
    @IBOutlet weak var PhotoAlbumButton: UIBarButtonItem!
    
    @IBOutlet weak var StatusLabel: UILabel!
    
    @IBOutlet weak var FilterLabel: UILabel!
    
    @IBOutlet weak var MainBottomToolbar: UIToolbar!
}

