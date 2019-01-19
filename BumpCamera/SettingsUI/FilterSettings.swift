//
//  FilterSettings.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class FilterSettings: UIViewController, UITableViewDelegate, UITableViewDataSource, NewFieldSettingProtocol
{
    let _Settings = UserDefaults.standard
    var FilterID: UUID? = nil
    var FilterType: FilterNames? = nil
    let Filters = FilterManager()
    var ParameterBlock: RenderPacket? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let FilterIDS = _Settings.string(forKey: "CurrentFilter")
        FilterID = UUID(uuidString: FilterIDS!)
        FilterType = Filters.GetFilterFrom(ID: FilterID!)
        FilterTitle.text = Filters.GetFilterTitle(FilterType!)
        ParameterBlock = Filters.GetParameterBlock(For: FilterType!)
        if ParameterBlock == nil
        {
            fatalError("Nil parameter block returned in FilterSettings.viewDidLoad.")
        }
        CellCount = (ParameterBlock?.SupportedFields.count)!
        FilterParameterTable.layer.borderColor = UIColor.black.cgColor
        FilterParameterTable.layer.borderWidth = 0.5
        FilterParameterTable.layer.cornerRadius = 5.0
        
        FilterParameterTable.delegate = self
        FilterParameterTable.dataSource = self
    }
    
    var CellCount = 0
    
    func CreateUI()
    {
        let FilterIDString = _Settings.string(forKey: "CurrentFilter")
        FilterID = UUID(uuidString: FilterIDString!)
    }
    
    func NewFieldSetting(InputField: RenderPacket.InputFields, NewValue: Any?)
    {
        
    }
    
    @IBOutlet weak var FilterTitle: UILabel!
    
    @IBOutlet weak var SampleView: UIImageView!
    
    @IBOutlet weak var FilterParameterTable: UITableView!
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return FilterCell.CellHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return CellCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let Cell = FilterCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "ParameterCell")
        return Cell as UITableViewCell
    }
    
    public func NewRawValue(_ Raw: String, Field: RenderPacket.InputFields)
    {
        
    }
}
