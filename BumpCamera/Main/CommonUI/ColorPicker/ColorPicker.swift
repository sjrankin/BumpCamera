//
//  ColorPicker.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorPicker: UITableViewController, UINavigationControllerDelegate, ColorPickerProtocol
{
    let _Settings = UserDefaults.standard
    var CurrentColor: UIColor = UIColor.black
    var SampleView: UIView? = nil
    let HeaderHeight: CGFloat = 150.0
    var PickerLayer: ColorSpaceGradient = ColorSpaceGradient()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        print("Start ColorPicker of viewDidLoad.")
        SampleView = UIView()
        SampleView?.contentMode = .center
        SampleView?.layer.borderColor = UIColor.black.cgColor
        SampleView?.backgroundColor = UIColor(named: "Sandstorm")!
        SampleView?.layer.borderWidth = 1.0
        
        var SatNotUsed: CGFloat = 0.0
        var BriNotUsed: CGFloat = 0.0
        var Hue: CGFloat = 0.0
        var AlphaNotUsed: CGFloat = 0.0
        CurrentColor.getHue(&Hue, saturation: &SatNotUsed, brightness: &BriNotUsed, alpha: &AlphaNotUsed)
        let DenormalizedHue: Int = Int(Hue * 360.0)
        AxisSlider.value = Float(Hue * 10.0)
        AxisValue.text = "\(DenormalizedHue)"
        PickerLayer.bounds = CGRect(x: 0, y: 0,
                                    width: ColorSelector.frame.width,
                                    height: ColorSelector.frame.height + ColorSelector.frame.minY)
        PickerLayer.frame = PickerLayer.bounds
        PickerLayer.zPosition = 1000
        PickerLayer.HostDelegate = self
        ColorSelector.layer.addSublayer(PickerLayer)
        PickerLayer.Initialize(WithHue: Hue)
        let Tap = UITapGestureRecognizer(target: self, action: #selector(HandleColorPickerTap))
        ColorSelector.addGestureRecognizer(Tap)
        PickerLayer.SelectColor(CurrentColor, InView: ColorSelector)
        
        ShowCurrentColor(CurrentColor)
    }
    
    func AdjustSliderFor(NewHue: Double)
    {
        AxisSlider.value = Float(NewHue * 10.0)
    }
    
    func ColorFromPicker(NewColor: UIColor)
    {
        print("New color from picker: \(NewColor)")
        CurrentColor = NewColor
        ShowCurrentColor(NewColor)
        AdjustSliderFor(NewHue: Double(NewColor.Hue))
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return HeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView
    {
        if let Sample = SampleView
        {
            //SampleView?.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
            //SampleView?.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
            SampleView?.frame = CGRect(x: 10, y: 10,
                                       width: UIScreen.main.bounds.width - 20,
                                       height: HeaderHeight - 20)
            return Sample
        }
        return UIView()
    }
    
    var delegate: ColorPickerProtocol? = nil
    
    var PassedTag: Any? = nil
    
    func ShowCurrentColor(_ Color: UIColor)
    {
        SampleView?.backgroundColor = Color
        ShowColorValues(Color)
    }
    
    func ShowColorValues(_ Color: UIColor)
    {
        var Red: CGFloat = 0.0
        var Green: CGFloat = 0.0
        var Blue: CGFloat = 0.0
        var NotUsed: CGFloat = 0.0
        Color.getRed(&Red, green: &Green, blue: &Blue, alpha: &NotUsed)
        let IRed = Int(Red * 255.0)
        let IGreen = Int(Green * 255.0)
        let IBlue = Int(Blue * 255.0)
        let RGBString = "\(IRed),\(IGreen),\(IBlue)"
        RGBOut.text = RGBString
        let RedX = String(format: "%02x", IRed)
        let GreenX = String(format: "%02x", IGreen)
        let BlueX = String(format: "%02x", IBlue)
        let HexString = "0x\(RedX)\(GreenX)\(BlueX)"
        HexOut.text = HexString
    }
    
    func ColorToEdit(_ Color: UIColor, Tag: Any?)
    {
        CurrentColor = Color
        PassedTag = Tag
    }
    
    /// Get a color from a sub-dialog, such as the color chip dialog.
    ///
    /// - Parameters:
    ///   - Edited: Edited color if changed, nil if no change.
    ///   - Tag: Tag that describes which sub-dialog was called.
    func EditedColor(_ Edited: UIColor?, Tag: Any?)
    {
        if let NewColor = Edited
        {
            CurrentColor = NewColor
            ShowCurrentColor(NewColor)
        }
    }
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        delegate?.EditedColor(CurrentColor, Tag: PassedTag)
        navigationController?.popViewController(animated: true)
        //        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCancelButton(_ sender: Any)
    {
        delegate?.EditedColor(nil, Tag: PassedTag)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleColorChipButton(_ sender: Any)
    {
    }
    
    @IBAction func HandleColorListButton(_ sender: Any)
    {
        performSegue(withIdentifier: "ToColorListPicker", sender: self)
    }
    
    @IBAction func HandleAxisSliderChanged(_ sender: Any)
    {
        let SliderValue = CGFloat(AxisSlider.value / 10.0)
        AxisValue.text = "\(Int(SliderValue))"
        PickerLayer.Hue = SliderValue / 360.0
        let NewColor = PickerLayer.GetColorAt(Location: PickerLayer.TappedPoint!, InView: ColorSelector)
        CurrentColor = NewColor
        ShowCurrentColor(NewColor)
    }
    
    @IBOutlet weak var AxisSlider: UISlider!
    @IBOutlet weak var AxisLabel: UILabel!
    @IBOutlet weak var AxisValue: UILabel!
    @IBOutlet weak var ColorSelector: UIView!
    @IBOutlet weak var RGBOut: UILabel!
    @IBOutlet weak var HexOut: UILabel!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToColorChipPicker":
            break
            
        case "ToColorListPicker":
            if let Dest = segue.destination as? ColorListPickerCode
            {
                Dest.ParentDelegate = self
                Dest.ColorToEdit(CurrentColor, Tag: "ListPickerColor")
            }
            
        default:
            break
        }
        
        super.prepare(for: segue, sender: self)
    }
    
    // MARK: Gesture recognizers for the color picker view.
    
    @objc func HandleColorPickerTap(Gesture: UITapGestureRecognizer)
    {
        if Gesture.state == .ended
        {
            let Location = Gesture.location(in: ColorSelector)
            PickerLayer.IndicateColorAt(Location: Location, InView: ColorSelector)
        }
    }
}
