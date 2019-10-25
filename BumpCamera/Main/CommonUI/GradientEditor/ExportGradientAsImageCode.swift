//
//  ExportGradientAsImageCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ExportGradientAsImageCode: UITableViewController, UIActivityItemSource,
    GradientPickerProtocol
{
    weak var ParentDelegate: GradientPickerProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        if !GradientToExport.isEmpty
        {
            ExportButton.isEnabled = true
        }
    }
    
    func EditedGradient(_ Edited: String?, Tag: Any?)
    {
        //Not used in this class.
    }
    
    func GradientToEdit(_ EditMe: String?, Tag: Any?)
    {
        if let TheGradient = EditMe
        {
            GradientToExport = TheGradient
        }
    }
    
    var GradientToExport: String = ""
    
    func SetStop(StopColorIndex: Int)
    {
        //Not used in this class.
    }
    
    @IBOutlet weak var OrientationSegment: UISegmentedControl!
    
    @IBOutlet weak var ExportButton: UIButton!
    
    @IBAction func HandleExportPressed(_ sender: Any)
    {
        let IsVertical = OrientationSegment.selectedSegmentIndex == 0
        let Width = Int(Double(pow(Double(2.0), Double(WidthSegment.selectedSegmentIndex + 8))))
        let Height = Int(Double(pow(Double(2.0), Double(HeightSegment.selectedSegmentIndex + 8))))
        print("Exporting image of size \(Width)x\(Height)")
        let ImageFrame = CGRect(x: 0, y: 0, width: Width, height: Height)
        SaveMe = GradientManager.CreateGradientImage(From: GradientToExport, WithFrame: ImageFrame,
                                                     IsVertical: IsVertical)
        let Items: [Any] = [self]
        let ACV = UIActivityViewController(activityItems: Items, applicationActivities: nil)
        present(ACV, animated: true)
    }
    
    var SaveMe: UIImage? = nil
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return UIImage()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        let Generated: UIImage = SaveMe!
        
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
    
    @IBOutlet weak var WidthSegment: UISegmentedControl!
    
    @IBOutlet weak var HeightSegment: UISegmentedControl!
}
