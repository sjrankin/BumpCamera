//
//  GradientEditorUICode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GradientEditorUICode: UIViewController, GradientPickerProtocol,
    UITableViewDelegate, UITableViewDataSource
{
    let _Settings = UserDefaults.standard
    var OriginalGradient: String = ""
    var CurrentGradient: String = ""
    var CallerTag: Any? = nil
    weak var ParentDelegate: GradientPickerProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        OriginalGradient = CurrentGradient
        GradientView.backgroundColor = UIColor.black
        GradientView.layer.borderColor = UIColor.black.cgColor
        GradientView.layer.borderWidth = 0.5
        GradientView.layer.cornerRadius = 5.0
        GradientStopTable.delegate = self
        GradientStopTable.dataSource = self
        ShowSample(WithGradient: CurrentGradient)
    }
    
    var GradientStopList = [(UIColor, Double)]()
    
    func ShowSample(WithGradient: String)
    {
        if WithGradient.isEmpty
        {
            GradientView.image = nil
            GradientView.backgroundColor = UIColor.black
            GradientStopList.removeAll()
        }
        else
        {
            let IsVertical = GradientOrientation.selectedSegmentIndex == 0
            let SampleGradient = GradientParser.CreateGradientImage(From: WithGradient, WithFrame: GradientView.frame, IsVertical: IsVertical, ReverseColors: false)
            GradientView.image = SampleGradient
        }
        GradientStopTable.reloadData()
    }
    
    func SetStop(StopColor: UIColor?, StopLocation: Double?)
    {
        //Not used in this class.
    }
    
    func EditedGradient(_ Edited: String?, Tag: Any?)
    {
        //Not used in this class.
    }
    
    func GradientToEdit(_ EditMe: String?, Tag: Any?)
    {
        if let HasGradient = EditMe
        {
            CurrentGradient = HasGradient
        }
        else
        {
            CurrentGradient = ""
        }
        CallerTag = Tag
    }
    
    @IBAction func HandleReverseGradientButton(_ sender: Any)
    {
        ShowSample(WithGradient: CurrentGradient)
    }
    
    @IBAction func HandleClearButton(_ sender: Any)
    {
        CurrentGradient = ""
        ShowSample(WithGradient: CurrentGradient)
    }
    
    @IBAction func HandleResetButton(_ sender: Any)
    {
        CurrentGradient = OriginalGradient
        ShowSample(WithGradient: CurrentGradient)
    }
    
    @IBAction func HandleEditButton(_ sender: Any)
    {
    }
    
    @IBAction func HandleAddButton(_ sender: Any)
    {
    }
    
    @IBAction func HandleOrientationChange(_ sender: Any)
    {
        ShowSample(WithGradient: CurrentGradient)
    }
    
    @IBAction func HandleCancelButton(_ sender: Any)
    {
        ParentDelegate?.EditedGradient(nil, Tag: CallerTag)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        ParentDelegate?.EditedGradient(CurrentGradient, Tag: CallerTag)
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return GradientStopList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let (Color, Location) = GradientStopList[indexPath.row]
        let Cell = GradientStopCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "GradientCell")
        Cell.SetData(StopColor: Color, StopLocation: Location)
        return Cell
    }
    
    @IBOutlet weak var GradientStopTable: UITableView!
    @IBOutlet weak var GradientView: UIImageView!
    @IBOutlet weak var GradientOrientation: UISegmentedControl!
    @IBOutlet weak var ReverseGradientButton: UIButton!
}
