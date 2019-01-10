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
            OriginalImageToSave = Image
            SetupSegue(ForImage: ApplyFilter(To: Image))
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
            if let Final = ImageFilterer.TVLines(To, Center: Center, Width: 10.0)
            {
                return Final
            }
            fatalError("Nil image returned by TVLines")
            
        case 5:
            //Merged TV lines
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.TVLines(To, Center: Center, Width: 5.0, Merged: true)
            {
                return Final
            }
            fatalError("Nil image returned by TVLines")
            
        case 2:
            //Circle lines
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.RoundLines(To, Center: Center, Width: 10.0)
            {
                return Final
            }
            fatalError("Nil image returned by RoundLines")
            
        case 6:
            //Merged Circle lines
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.RoundLines(To, Center: Center, Width: 5.0, Merged: true)
            {
                return Final
            }
            fatalError("Nil image returned by RoundLines")
            
        case 3:
            //Color blocks
            if let Final = ImageFilterer.ColorBlocks(To, NodeWidth: 50.0)
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
            if let Final = ImageFilterer.DotScreen(To, Width: 10.0)
            {
                return Final
            }
            fatalError("Nil image returned by DotScreen")
            
        case 9:
            //TV and Round lines merged
            let Center = CGPoint(x: To.size.width / 2.0, y: To.size.height / 2.0)
            if let Final = ImageFilterer.TVRound(To, Center: Center, Width: 10.0)
            {
                return Final
            }
            fatalError("Nil image returned by TVRound")
            
        case 10:
            //Merged dot screen
            //Dot screen
            if let Final = ImageFilterer.DotScreen(To, Width: 5.0, Merged: true)
            {
                return Final
            }
            fatalError("Nil image returned by DotScreen")
            
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
            let Alert = UIAlertController(title: "Saved", message: "Your image was saved to the photo album.", preferredStyle: UIAlertController.Style.alert)
            let AlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            Alert.addAction(AlertAction)
            present(Alert, animated: true)
        }
    }
    
    @IBOutlet weak var SaveButton: UIBarButtonItem!
    
    func FinalizeImage(_ Source: UIImage) -> UIImage
    {
        #if true
        let cimg = Source.ciImage
        #else
        var cimg = Source.ciImage
        cimg = cimg?.oriented(CGImagePropertyOrientation.right)
        #endif
        let Context = CIContext()
        let cgimg = Context.createCGImage(cimg!, from: cimg!.extent)
        let final = UIImage(cgImage: cgimg!)
        return final
    }
    
    //https://stackoverflow.com/questions/44864432/saving-to-user-photo-library-silently-fails
    func DoSaveImage()
    {
        print("At DoSaveImage")
        let SaveMe = FinalizeImage(PreviewImage)
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
        let Filter3 = UIAlertAction(title: TitleFor(3), style: .default, handler: FilterSelection)
        Filters.addAction(Filter3)
        let Filter4 = UIAlertAction(title: TitleFor(4), style: .default, handler: FilterSelection)
        Filters.addAction(Filter4)
        let Filter5 = UIAlertAction(title: TitleFor(7), style: .default, handler: FilterSelection)
        Filters.addAction(Filter5)
        let Cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        Filters.addAction(Cancel)
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
            ]
    
    var CurrentFilter: Int = 0
    
    @objc func FilterSelection(Action: UIAlertAction)
    {
        if let FilterID = FilterMap[Action.title!]
        {
            CurrentFilter = FilterID
            print("Current filter now \(TitleFor(CurrentFilter))")
        }
        else
        {
            print("Unknown filter \"\((Action.title)!)\" encountered.")
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return .default
    }
    
    @IBOutlet weak var OutputView: UIImageView!
    
    func SetupSegue(ForImage: UIImage)
    {
        PreviewImage = ForImage
        performSegue(withIdentifier: "ToFilteredView", sender: self)
    }
    
    var PreviewImage: UIImage!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToFilteredView":
            let Dest = segue.destination as? ImagePreviewController
            Dest?.delegate = self
            Dest?.ImageToPreview(PreviewImage)
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
}

