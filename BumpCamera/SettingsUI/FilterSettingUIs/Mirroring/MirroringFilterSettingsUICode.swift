//
//  MirroringFilterSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MirroringFilterSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        SampleView = UIImageView(image: UIImage(named: "Norio"))
        SampleView.contentMode = .scaleAspectFit
        
        NotificationCenter.default.addObserver(self, selector: #selector(DefaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
        Initialize(FilterType: FilterManager.FilterTypes.Mirroring)
        ShowSampleView()

        Q1Button.layer.borderColor = UIColor.black.cgColor
        Q1Button.layer.borderWidth = 0.5
        Q1Button.backgroundColor = UIColor.white
        Q2Button.layer.borderColor = UIColor.black.cgColor
        Q2Button.layer.borderWidth = 0.5
        Q2Button.backgroundColor = UIColor.white
        Q3Button.layer.borderColor = UIColor.black.cgColor
        Q3Button.layer.borderWidth = 0.5
        Q3Button.backgroundColor = UIColor.white
        Q4Button.layer.borderColor = UIColor.black.cgColor
        Q4Button.layer.borderWidth = 0.5
        Q4Button.backgroundColor = UIColor.white
        
        let MDirection = ParameterManager.GetInt(From: FilterID, Field: .MirroringDirection, Default: 0)
        DirectionSegment.selectedSegmentIndex = MDirection
        let HSide = ParameterManager.GetInt(From: FilterID, Field: .HorizontalSide, Default: 0)
        HorizontalSourceSegment.selectedSegmentIndex = HSide
        let VSide = ParameterManager.GetInt(From: FilterID, Field: .VerticalSide, Default: 0)
        VerticalSourceSegment.selectedSegmentIndex = VSide
        SetUI()
        let Q = ParameterManager.GetInt(From: FilterID, Field: .Quadrant, Default: 1)
        switch Q
        {
        case 1:
            Q1Button.backgroundColor = UIColor(named: "Saffron")
            
        case 2:
            Q2Button.backgroundColor = UIColor(named: "Saffron")
            
        case 3:
            Q3Button.backgroundColor = UIColor(named: "Saffron")
            
        case 4:
            Q4Button.backgroundColor = UIColor(named: "Saffron")
            
        default:
            fatalError("Invalid quadrant \(Q) encountered.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
        super.viewWillDisappear(animated)
    }
    
    @objc func DefaultsChanged(notification: NSNotification)
    {
        if let Defaults = notification.object as? UserDefaults
        {
            let NewName = Defaults.value(forKey: "SampleImage") as? String
            if NewName != PreviousImage
            {
                PreviousImage = NewName!
                ShowSampleView()
            }
        }
    }
    
    var PreviousImage = ""
    
    let ViewLock = NSObject()
    
    func ShowSampleView()
    {
        objc_sync_enter(ViewLock)
        defer{objc_sync_exit(ViewLock)}
        
        let ImageName = _Settings.string(forKey: "SampleImage")
        SampleView.image = nil
        var SampleImage = UIImage(named: ImageName!)
        SampleImage = SampleFilter?.Render(Image: SampleImage!)
        SampleView.image = SampleImage
    }
    
    func SetUI()
    {
        switch DirectionSegment.selectedSegmentIndex
        {
        case 0:
            HorizontalSourceSegment.isEnabled = true
            HorizontalSourceLabel.isEnabled = true
            VerticalSourceSegment.isEnabled = false
            VerticalSourceLabel.isEnabled = false
            QuadrantLabel.isEnabled = false
            Q1Button.isEnabled = false
            Q2Button.isEnabled = false
            Q3Button.isEnabled = false
            Q4Button.isEnabled = false
            
        case 1:
            HorizontalSourceSegment.isEnabled = false
            HorizontalSourceLabel.isEnabled = false
            VerticalSourceSegment.isEnabled = true
            VerticalSourceLabel.isEnabled = true
            QuadrantLabel.isEnabled = false
            Q1Button.isEnabled = false
            Q2Button.isEnabled = false
            Q3Button.isEnabled = false
            Q4Button.isEnabled = false
            
        case 2:
            HorizontalSourceSegment.isEnabled = false
            HorizontalSourceLabel.isEnabled = false
            VerticalSourceSegment.isEnabled = false
            VerticalSourceLabel.isEnabled = false
            QuadrantLabel.isEnabled = true
            Q1Button.isEnabled = true
            Q2Button.isEnabled = true
            Q3Button.isEnabled = true
            Q4Button.isEnabled = true
            
        default:
            break
        }
    }
    
    func UpdateParameters()
    {
        UpdateValue(WithValue: DirectionSegment.selectedSegmentIndex, ToField: .MirroringDirection)
        UpdateValue(WithValue: HorizontalSourceSegment.selectedSegmentIndex, ToField: .HorizontalSide)
        UpdateValue(WithValue: VerticalSourceSegment.selectedSegmentIndex, ToField: .VerticalSide)
        ShowSampleView()
    }
    
    @IBAction func HandleVerticalSourceChanged(_ sender: Any)
    {
        UpdateParameters()
    }
    
    @IBAction func HandleHorizontalSourceChanged(_ sender: Any)
    {
        UpdateParameters()
    }
    
    @IBAction func HandleDirectionChanged(_ sender: Any)
    {
        UpdateParameters()
        SetUI()
    }
    
    func SetSelectedQuadrant(Quadrant: Int)
    {
        Q1Button.backgroundColor = UIColor.white
        Q2Button.backgroundColor = UIColor.white
        Q3Button.backgroundColor = UIColor.white
        Q4Button.backgroundColor = UIColor.white
        
        switch Quadrant
        {
        case 1:
            Q1Button.backgroundColor = UIColor(named: "Saffron")
            
        case 2:
            Q2Button.backgroundColor = UIColor(named: "Saffron")
            
        case 3:
            Q3Button.backgroundColor = UIColor(named: "Saffron")
            
        case 4:
            Q4Button.backgroundColor = UIColor(named: "Saffron")
            
        default:
            fatalError("Invalid quadrant \(Quadrant) encountered")
        }
        
        UpdateValue(WithValue: Int(Quadrant), ToField: .Quadrant)
        ShowSampleView()
    }
    
    @IBAction func HandleQuadrant1Selected(_ sender: Any)
    {
        SetSelectedQuadrant(Quadrant: 1)
    }
    
    @IBAction func HandleQuadrant2Selected(_ sender: Any)
    {
        SetSelectedQuadrant(Quadrant: 2)
    }
    
    @IBAction func HandleQuadrant3Selected(_ sender: Any)
    {
        SetSelectedQuadrant(Quadrant: 3)
    }
    
    @IBAction func HandleQuadrant4Selected(_ sender: Any)
    {
        SetSelectedQuadrant(Quadrant: 4)
    }
    
    @IBOutlet weak var Q1Button: UIButton!
    @IBOutlet weak var Q2Button: UIButton!
    @IBOutlet weak var Q3Button: UIButton!
    @IBOutlet weak var Q4Button: UIButton!
    @IBOutlet weak var VerticalSourceLabel: UILabel!
    @IBOutlet weak var HorizontalSourceLabel: UILabel!
    @IBOutlet weak var VerticalSourceSegment: UISegmentedControl!
    @IBOutlet weak var HorizontalSourceSegment: UISegmentedControl!
    @IBOutlet weak var DirectionSegment: UISegmentedControl!
    @IBOutlet weak var QuadrantLabel: UILabel!
    @IBOutlet weak var QuadrantContainer: UIView!
    
    @IBAction func HandleBackButtonPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
    }
}
