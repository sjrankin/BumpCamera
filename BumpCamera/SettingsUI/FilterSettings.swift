//
//  FilterSettings.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class FilterSettings: UIViewController, NewFieldSettingProtocol
{
    let _Settings = UserDefaults.standard
    var FilterID: UUID? = nil
    var FilterType: FilterManager.FilterTypes? = nil
    let Filters = FilterManager()
    var SampleFilter: Renderer? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let FilterIDS = _Settings.string(forKey: "CurrentFilter")
        FilterID = UUID(uuidString: FilterIDS!)
        FilterType = Filters.GetFilterTypeFrom(ID: FilterID!)
        FilterTitle.text = Filters.GetFilterTitle(FilterType!)
        title = FilterTitle.text! + " Settings"

        ParameterHost.layer.borderColor = UIColor.black.cgColor
        ParameterHost.layer.borderWidth = 0.25
        ParameterHost.layer.cornerRadius = 5.0
        ParameterHost.backgroundColor = UIColor.clear
        
        SampleFilter = Filters.CreateFilter(For: FilterType!)
        SampleFilter?.InitializeForImage()
        ShowSampleView()
        CreateUI()
    }
    
    func ShowSampleView()
    {
        //SampleFilter = Filters.CreateFilter(For: FilterType!)
        var SampleImage = UIImage(named: "Norio")
        SampleImage = SampleFilter?.Render(Image: SampleImage!)
        SampleView.image = SampleImage
    }
    
    func CreateUI()
    {
        if let TableName = SampleFilter?.SettingsStoryboard()
        {
            let Storyboard = UIStoryboard(name: TableName, bundle: nil)
            Controller = Storyboard.instantiateViewController(withIdentifier: TableName) as? FilterTableBase
            let HostFrame = ParameterHost.frame
            ParameterHost.removeFromSuperview()
            Controller.view.frame = HostFrame
            self.view.addSubview(Controller.view)
            Controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            Controller.didMove(toParent: self)
            Controller.view.layer.borderColor = UIColor.black.cgColor
            Controller.view.layer.borderWidth = 0.5
            Controller.view.layer.cornerRadius = 5.0
            Controller.ParentDelegate = self
        }
    }
    
    var Controller: FilterTableBase!
    
    func NewFieldSetting(InputField: FilterManager.InputFields, NewValue: Any?)
    {
        
    }
    
    @IBOutlet weak var FilterTitle: UILabel!
    
    @IBOutlet weak var SampleView: UIImageView!
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return FilterCell.CellHeight
    }
    
    public func NewRawValue()
    {
        ShowSampleView()
    }
    
    func NewRawValue(For: FilterManager.InputFields)
    {
        ShowSampleView()
    }
    
    @IBAction func HandleReturnToMainPressed(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
        //navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var ParameterHost: UIView!
    
    @IBOutlet weak var BottomBar: UIToolbar!
}
