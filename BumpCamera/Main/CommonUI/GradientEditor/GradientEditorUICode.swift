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
        GradientStopList = GradientManager.ParseGradient(CurrentGradient)
        GradientView.backgroundColor = UIColor.black
        GradientView.layer.borderColor = UIColor.black.cgColor
        GradientView.layer.borderWidth = 0.5
        GradientView.layer.cornerRadius = 5.0
        GradientStopTable.delegate = self
        GradientStopTable.dataSource = self
        GradientStopTable.layer.borderColor = UIColor.black.cgColor
        GradientStopTable.layer.borderWidth = 0.5
        GradientStopTable.layer.cornerRadius = 5.0
        GradientStopTable.reloadData()
        let TapGesture = UITapGestureRecognizer(target: self, action: #selector(HandleSampleTap))
        GradientView.addGestureRecognizer(TapGesture)
        ShowSample(WithGradient: CurrentGradient)
    }
    
    @objc func HandleSampleTap(TapGesture: UITapGestureRecognizer)
    {
        if TapGesture.state == .ended
        {
            IsVertical = !IsVertical
            ShowSample(WithGradient: CurrentGradient)
        }
    }
    
    var IsVertical = true
    
    var GradientStopList = [(UIColor, CGFloat)]()
    
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
            let SampleGradient = GradientManager.CreateGradientImage(From: WithGradient, WithFrame: GradientView.bounds,
                                                                    IsVertical: IsVertical, ReverseColors: false)
            GradientView.image = SampleGradient
            GradientStopList = GradientManager.ParseGradient(WithGradient)
        }
        GradientStopTable.reloadData()
    }
    
    func SetStop(StopColorIndex StopIndex: Int)
    {
        //Not used in this class.
    }
    
    func EditedGradient(_ Edited: String?, Tag: Any?)
    {
        //From the color stop editor.
        if let NewGradient = Edited
        {
            if let CallerTag = Tag as? String
            {
                if CallerTag == "FromColorStopEditor"
                {
                    CurrentGradient = NewGradient
                    ShowSample(WithGradient: CurrentGradient)
                }
            }
        }
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
        CurrentGradient = GradientManager.ReverseColorLocations(CurrentGradient)
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
        GradientStopTable.setEditing(!GradientStopTable.isEditing, animated: true)
        if GradientStopTable.isEditing
        {
            EditButton.title = "Done"
        }
        else
        {
            EditButton.title = "Edit"
        }
        AddGradientStopButton.isEnabled = !GradientStopTable.isEditing
        ResetButton.isEnabled = !GradientStopTable.isEditing
        ReverseColorButton.isEnabled = !GradientStopTable.isEditing
        ClearButton.isEnabled = !GradientStopTable.isEditing
    }
    
    @IBAction func HandleAddButton(_ sender: Any)
    {
        CurrentGradient = GradientManager.AddGradientStop(CurrentGradient, Color: UIColor.red, Location: 1.0)
        ShowSample(WithGradient: CurrentGradient)
        GradientStopTable.reloadData()
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
        Cell.SetData(StopColor: Color, StopLocation: Double(Location))
        return Cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return GradientStopCell.CellHeight
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        if let NewGradient = GradientManager.SwapGradientStops(CurrentGradient, Index1: sourceIndexPath.row,
                                                              Index2: destinationIndexPath.row)
        {
            CurrentGradient = NewGradient
            ShowSample(WithGradient: CurrentGradient)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            CurrentGradient = GradientManager.RemoveGradientStop(CurrentGradient, AtIndex: indexPath.row)!
            GradientStopTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let Cell = GradientStopTable.cellForRow(at: indexPath) as? GradientStopCell
        {
            let (Color, Location) = Cell.CellData()
            SelectedIndex = indexPath.row
            ColorToEdit = Color
            LocationToEdit = Location
            performSegue(withIdentifier: "ToGradientStopEditor", sender: self)
        }
    }
    
    var ColorToEdit: UIColor = UIColor.black
    var LocationToEdit: Double = 0.0
    var SelectedIndex: Int = -1
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "ToGradientStopEditor":
            if let Dest = segue.destination as? ColorStopEditorCode
            {
                Dest.ParentDelegate = self
                Dest.GradientToEdit(CurrentGradient, Tag: "FromColorStopEditor")
                Dest.SetStop(StopColorIndex: SelectedIndex)
            }
            
        default:
            break
        }
        super.prepare(for: segue, sender: self)
    }
    
    @IBOutlet weak var ClearButton: UIBarButtonItem!
    @IBOutlet weak var ResetButton: UIBarButtonItem!
    @IBOutlet weak var ReverseColorButton: UIBarButtonItem!
    @IBOutlet weak var AddGradientStopButton: UIBarButtonItem!
    @IBOutlet weak var EditButton: UIBarButtonItem!
    @IBOutlet weak var GradientStopTable: UITableView!
    @IBOutlet weak var GradientView: UIImageView!
}
