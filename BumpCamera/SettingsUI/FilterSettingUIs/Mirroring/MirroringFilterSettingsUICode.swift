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
        let MDirection = ParameterManager.GetInt(From: FilterID, Field: .MirroringDirection, Default: 0)
        DirectionSegment.selectedSegmentIndex = MDirection
        let HSide = ParameterManager.GetInt(From: FilterID, Field: .HorizontalSide, Default: 0)
        HorizontalSourceSegment.selectedSegmentIndex = HSide
        let VSide = ParameterManager.GetInt(From: FilterID, Field: .VerticalSide, Default: 0)
        VerticalSourceSegment.selectedSegmentIndex = VSide
        let IsHorizontal = DirectionSegment.selectedSegmentIndex == 0
        VerticalSourceSegment.isEnabled = !IsHorizontal
        VerticalSourceLabel.isEnabled = !IsHorizontal
        HorizontalSourceSegment.isEnabled = IsHorizontal
        HorizontalSourceLabel.isEnabled = IsHorizontal
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
        let IsHorizontal = DirectionSegment.selectedSegmentIndex == 0
        VerticalSourceSegment.isEnabled = !IsHorizontal
        VerticalSourceLabel.isEnabled = !IsHorizontal
        HorizontalSourceSegment.isEnabled = IsHorizontal
        HorizontalSourceLabel.isEnabled = IsHorizontal
    }
    
    @IBOutlet weak var VerticalSourceLabel: UILabel!
    @IBOutlet weak var HorizontalSourceLabel: UILabel!
    @IBOutlet weak var VerticalSourceSegment: UISegmentedControl!
    @IBOutlet weak var HorizontalSourceSegment: UISegmentedControl!
    @IBOutlet weak var DirectionSegment: UISegmentedControl!
    
    @IBAction func HandleBackButtonPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
    }
}
