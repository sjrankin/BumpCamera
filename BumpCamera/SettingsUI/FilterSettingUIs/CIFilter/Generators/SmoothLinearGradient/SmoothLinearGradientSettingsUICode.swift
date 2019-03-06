//
//  SmoothLinearGradientSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class SmoothLinearGradientSettingsUICode: FilterSettingUIBase, ColorPickerProtocol
{
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.SmoothLinearGradient)
        Color1XSlider.addTarget(self,
                                action: #selector(HandleColor1XStoppedSliding),
                                for: [.touchUpInside, .touchUpOutside])
        Color1YSlider.addTarget(self,
                                action: #selector(HandleColor1YStoppedSliding),
                                for: [.touchUpInside, .touchUpOutside])
        Color2XSlider.addTarget(self,
                                action: #selector(HandleColor2XStoppedSliding),
                                for: [.touchUpInside, .touchUpOutside])
        Color2YSlider.addTarget(self,
                                action: #selector(HandleColor2YStoppedSliding),
                                for: [.touchUpInside, .touchUpOutside])
        
        let Color0 = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.black)
        let Color1 = ParameterManager.GetColor(From: FilterID, Field: .Color1, Default: UIColor.white)
        Color0Sample.layer.borderColor = UIColor.black.cgColor
        Color0Sample.layer.borderWidth = 0.5
        Color0Sample.layer.cornerRadius = 5.0
        Color0Sample.backgroundColor = Color0
        Color1Sample.layer.borderColor = UIColor.black.cgColor
        Color1Sample.layer.borderWidth = 0.5
        Color1Sample.layer.cornerRadius = 5.0
        Color1Sample.backgroundColor = Color1
        let V0 = ParameterManager.GetVector(From: FilterID, Field: .Point0, Default: CIVector(x: 0, y: 0))
        Color1XSlider.value = Float(V0.x * 1000.0)
        Color1YSlider.value = Float(V0.y * 1000.0)
        Color1XValue.text = "\((V0.x * 100.0).Round(To: 2))%"
        Color1YValue.text = "\((V0.y * 100.0).Round(To: 2))%"
        let V1 = ParameterManager.GetVector(From: FilterID, Field: .Point1, Default: CIVector(x: 0, y: 0))
        Color2XSlider.value = Float(V1.x * 1000.0)
        Color2YSlider.value = Float(V1.y * 1000.0)
        Color2XValue.text = "\((V1.x * 100.0).Round(To: 2))%"
        Color2YValue.text = "\((V1.y * 100.0).Round(To: 2))%"
        let ImageWidth = ParameterManager.GetInt(From: FilterID, Field: .IWidth, Default: 1024)
        let ImageHeight = ParameterManager.GetInt(From: FilterID, Field: .IHeight, Default: 1024)
        let WidthSegment = IndexOfClosestTo(ImageWidth, [256, 512, 1024, 2048, 4096])
        //print("Closest segment to \(ImageWidth) is \(WidthSegment)")
        let HeightSegment = IndexOfClosestTo(ImageHeight, [256, 512, 1024, 2048, 4096])
        //print("Closest segment to \(ImageHeight) is \(HeightSegment)")
        WidthSegments.selectedSegmentIndex = WidthSegment
        HeightSegments.selectedSegmentIndex = HeightSegment
        
        //Because the base class doesn't have a standard image to display with a generator filter,
        //we need to force it to display the output of the current generator immediately or the user
        //will see only a black rectangle until he changes a setting.
        ShowSampleView()
    }
    
    func IndexOfClosestTo(_ Find: Int, _ List: [Int]) -> Int
    {
        var Delta = Int.max
        var ClosestIndex = 0
        
        var Index = 0
        for Value in List
        {
            let LoopDelta = abs(Value - Find)
            if LoopDelta < Delta
            {
                Delta = LoopDelta
                ClosestIndex = Index
            }
            Index = Index + 1
        }
        return ClosestIndex
    }
    
    /// Not implemented or used in this class.
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
    }
    
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            if let TagString = Tag as? String
            {
                switch TagString
                {
                case "Color1":
                    Color0Sample.backgroundColor = NewColor
                    UpdateValue(WithValue: NewColor, ToField: .Color0)
                    ShowSampleView()
                    
                case "Color2":
                    Color1Sample.backgroundColor = NewColor
                    UpdateValue(WithValue: NewColor, ToField: .Color1)
                    ShowSampleView()
                    
                default:
                    break
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColor1ColorPicker":
            let EditMe = ParameterManager.GetColor(From: FilterID, Field: .Color0, Default: UIColor.red)
            if let Dest = segue.destination as? ColorPicker
            {
                Dest.delegate = self
                Dest.ColorToEdit(EditMe, Tag: "Color1")
            }
            else
            {
                print("Error getting destination for color picker from segue.")
                return
            }
            
        case "ToColor2ColorPicker":
            let EditMe = ParameterManager.GetColor(From: FilterID, Field: .Color1, Default: UIColor.red)
            if let Dest = segue.destination as? ColorPicker
            {
                Dest.delegate = self
                Dest.ColorToEdit(EditMe, Tag: "Color2")
            }
            else
            {
                print("Error getting destination for color picker from segue.")
                return
            }
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
    
    @objc func HandleColor1XStoppedSliding()
    {
        let SliderValue = Double(Color1XSlider.value / 1000.0)
        Color1XValue.text = "\((SliderValue * 100.0).Round(To: 2))%"
        let Y1SliderValue = CGFloat(Color1YSlider.value / 1000.0)
        UpdateValue(WithValue: CIVector(x: CGFloat(SliderValue), y: Y1SliderValue), ToField: .Point0)
        ShowSampleView()
    }
    
    @IBAction func HandleColor1XChanged(_ sender: Any)
    {
        let SliderValue = Double(Color1XSlider.value / 1000.0)
        Color1XValue.text = "\((SliderValue * 100.0).Round(To: 2))%"
    }
    
    @objc func HandleColor1YStoppedSliding()
    {
        let SliderValue = Double(Color1YSlider.value / 1000.0)
        Color1YValue.text = "\((SliderValue * 100.0).Round(To: 2))%"
        let X1SliderValue = CGFloat(Color1XSlider.value / 1000.0)
        UpdateValue(WithValue: CIVector(x: X1SliderValue, y: CGFloat(SliderValue)), ToField: .Point0)
        ShowSampleView()
    }
    
    @IBAction func HandleColor1YChanged(_ sender: Any)
    {
        let SliderValue = Double(Color1YSlider.value / 1000.0)
        Color1YValue.text = "\((SliderValue * 100.0).Round(To: 2))%"
    }
    
    @objc func HandleColor2XStoppedSliding()
    {
        let SliderValue = Double(Color2XSlider.value / 1000.0)
        Color2XValue.text = "\((SliderValue * 100.0).Round(To: 2))%"
        let Y2SliderValue = CGFloat(Color2YSlider.value / 1000.0)
        UpdateValue(WithValue: CIVector(x: CGFloat(SliderValue), y: Y2SliderValue), ToField: .Point0)
        ShowSampleView()
    }
    
    @IBAction func HandleColor2XChanged(_ sender: Any)
    {
        let SliderValue = Double(Color2XSlider.value / 1000.0)
        Color2XValue.text = "\((SliderValue * 100.0).Round(To: 2))%"
    }
    
    @objc func HandleColor2YStoppedSliding()
    {
        let SliderValue = Double(Color2YSlider.value / 1000.0)
        Color2YValue.text = "\((SliderValue * 100.0).Round(To: 2))%"
        let X2SliderValue = CGFloat(Color2XSlider.value / 1000.0)
        UpdateValue(WithValue: CIVector(x: X2SliderValue, y: CGFloat(SliderValue)), ToField: .Point1)
        ShowSampleView()
    }
    
    @IBAction func HandleColor2YChanged(_ sender: Any)
    {
        let SliderValue = Double(Color2YSlider.value / 1000.0)
        Color2YValue.text = "\((SliderValue * 100.0).Round(To: 2))%"
    }
    
    @IBAction func HandleHeightChanged(_ sender: Any)
    {
        let HeightIndex = HeightSegments.selectedSegmentIndex
        let ImageHeight: Int = Int((pow(Double(2), Double(8 + HeightIndex))))
        UpdateValue(WithValue: ImageHeight, ToField: .IHeight)
        ShowSampleView()
    }
    
    @IBAction func HandleWidthChanged(_ sender: Any)
    {
        let WidthIndex = WidthSegments.selectedSegmentIndex
        let ImageWidth: Int = Int((pow(Double(2), Double(8 + WidthIndex))))
        UpdateValue(WithValue: ImageWidth, ToField: .IWidth)
        ShowSampleView()
    }
    
    #if false
    @IBAction func HandleSaveImageButton(_ sender: Any)
    {
        //Need to convert the generated image from a CIImage to a UIImage first...
        let Context = CIContext()
        let cgimg = Context.createCGImage(LastGeneratedImage, from: LastGeneratedImage.extent)
        let SaveMe = UIImage(cgImage: cgimg!)
        UIImageWriteToSavedPhotosAlbum(SaveMe, self, #selector(image), nil)
    }
    
    @objc override func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer)
    {
        if let SaveError = error
        {
            let Alert = UIAlertController(title: "Image Save Error", message: SaveError.localizedDescription, preferredStyle: .alert)
            Alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(Alert, animated: true)
        }
        else
        {
            let Alert = UIAlertController(title: "Generated Image Saved", message: "The generated image with current effect parameters has been saved to the photo album.", preferredStyle: .alert)
            Alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(Alert, animated: true)
        }
    }
    #endif
    
    //@IBAction func HandleBackButton(_ sender: Any)
    //{
    //    dismiss(animated: true, completion: nil)
    //}
    
    @IBAction func HandleCameraButton(_ sender: Any)
    {
    }
    
    #if false
    @IBAction func HandleActionButton(_ sender: Any)
    {
        let Items: [Any] = [self]
        let ACV = UIActivityViewController(activityItems: Items, applicationActivities: nil)
        present(ACV, animated: true)
    }
    
    @objc func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return UIImage()
    }
    
    @objc func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return "Smooth Linear Gradient Generator Output"
    }
    
    @objc func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        let Generated: UIImage = GetLastGeneratedImage()!
        
        switch activityType!
        {
        case .postToTwitter:
            return Generated
            
        case .airDrop:
            return Generated
            
        case .copyToPasteboard:
            return Generated
            
        case .mail:
            return Generated
            
        case .postToTencentWeibo:
            return Generated
            
        case .postToWeibo:
            return Generated
            
        case .print:
            return Generated
            
        case .markupAsPDF:
            return Generated
            
        case .message:
            return Generated
            
        default:
            return Generated
        }
    }
    #endif
    
    @IBOutlet weak var HeightSegments: UISegmentedControl!
    @IBOutlet weak var WidthSegments: UISegmentedControl!
    @IBOutlet weak var Color0Sample: UIView!
    @IBOutlet weak var Color1Sample: UIView!
    @IBOutlet weak var Color1XSlider: UISlider!
    @IBOutlet weak var Color1YSlider: UISlider!
    @IBOutlet weak var Color2XSlider: UISlider!
    @IBOutlet weak var Color2YSlider: UISlider!
    @IBOutlet weak var Color1XValue: UILabel!
    @IBOutlet weak var Color1YValue: UILabel!
    @IBOutlet weak var Color2XValue: UILabel!
    @IBOutlet weak var Color2YValue: UILabel!
    
    
}
