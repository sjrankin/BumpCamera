//
//  NoParametersSettingsUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/1/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class NoParametersSettingsUICode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        var WorkingType: FilterManager.FilterTypes!
        let TypeVal = _Settings.integer(forKey: "SetupForFilterType")
        if let VariableType: FilterManager.FilterTypes = FilterManager.FilterTypes(rawValue: TypeVal)
        {
            WorkingType = VariableType
        }
        else
        {
            WorkingType = FilterManager.FilterTypes.PassThrough
        }
        NotificationCenter.default.addObserver(self, selector: #selector(DefaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
        SampleView = UIImageView(image: UIImage(named: "Norio"))
        SampleView.contentMode = .scaleAspectFit
        Initialize(FilterType: WorkingType)
        let FilterTitle = FilterManager.GetFilterTitle(WorkingType)
        title = FilterTitle!
        TextLabel.text = "The filter \((FilterTitle)!) has no parameters to set."
        
        ShowSampleView()
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
    
    @IBOutlet weak var TextLabel: UILabel!
    
    @IBAction func HandleCameraHomePressed(_ sender: Any)
    {
    }
    
    @IBAction func HandleBackPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
}
