//
//  ExifViewerCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/25/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import Photos

class ExifViewerCode: UIViewController, UITableViewDelegate, UITableViewDataSource,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UIActivityItemSource
{
    let _Settings = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        ExifTable.layer.borderColor = UIColor.black.cgColor
        ExifTable.layer.borderWidth = 0.5
        ExifTable.layer.cornerRadius = 5.0
        ExifTable.delegate = self
        ExifTable.dataSource = self
        
        SendButton.isEnabled = false
        
        LoadedImageView.layer.borderWidth = 0.5
        LoadedImageView.layer.borderColor = UIColor.black.cgColor
        LoadedImageView.layer.cornerRadius = 5.0
        LoadedImageView.image = nil
        
        ImageNameLabel.text = ""
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if MetadataReader == nil
        {
            return nil
        }
        if var GroupName = MetadataReader?.Metadata?.Groups[section].0
        {
            if GroupName == ImageMetadata.TopLevelName
            {
                GroupName = "Top Level"
            }
            return GroupName
        }
        return "Unknown"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        if MetadataReader == nil
        {
            return 0
        }
        return (MetadataReader?.Metadata?.Groups.count)!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return ExifDataCell.CellHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if MetadataReader == nil
        {
            return 0
        }
        return (MetadataReader?.Metadata?.TagCountInGroup(section))!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let Cell = ExifDataCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "ExifDataCell")
        let Tag = MetadataReader?.Metadata?.TagInGroup(GroupIndex: indexPath.section, TagIndex: indexPath.row)
        Cell.SetData(KeyData: (Tag?.Key)!, ValueData: (Tag?.Value)!)
        return Cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let Cell = tableView.cellForRow(at: indexPath) as? ExifDataCell
        if (Cell?.TooMuchText)!
        {
            SelectedGroup = indexPath.section
            SelectedTag = indexPath.row
            print("Selected cell needs more room.")
            performSegue(withIdentifier: "ToOverflowViewer", sender: self)
        }
    }
    
    var SelectedGroup: Int = -1
    var SelectedTag: Int = -1
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "ToOverflowViewer"
        {
            if let Dest = segue.destination as? OverflowExifViewerCode
            {
                var GroupName = MetadataReader?.Metadata?.Groups[SelectedGroup].0
                if GroupName == ImageMetadata.TopLevelName
                {
                    GroupName = "Top Level"
                }
                let TheTag = MetadataReader?.Metadata?.TagInGroup(GroupIndex: SelectedGroup, TagIndex: SelectedTag)
                Dest.LoadOverflowData(Group: GroupName!, Tag: (TheTag?.Key)!, Overflow: (TheTag?.Value)!)
            }
        }
        super.prepare(for: segue, sender: self)
    }
    
    @IBAction func HandleLoadImageButton(_ sender: Any)
    {
        let ImagePicker = UIImagePickerController()
        ImagePicker.delegate = self
        ImagePicker.allowsEditing = false
        ImagePicker.sourceType = .photoLibrary
        present(ImagePicker, animated: true, completion: nil)
    }
    
    /// Implementation of the UIImagePickerController picked image delegate. The metadata is read here as well as causing a
    /// table reload (which forces a refresh). The image name (the real one, not the UUID-based one) is retrieved as well.
    ///
    /// - Note:
    ///   [Get file name from PHAsset](https://stackoverflow.com/questions/27854937/ios8-photos-framework-how-to-get-the-nameor-filename-of-a-phasset)
    ///
    /// - Parameters:
    ///   - picker: The picker control. **Must be dismissed before exiting the function.**
    ///   - info: Information about the picked image.
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        SendButton.isEnabled = false
        if let ImageURL = info[UIImagePickerController.InfoKey.imageURL] as? URL
        {
            MetadataReader = ImageMetadataReader(FileURL: ImageURL)
            if MetadataReader == nil
            {
                print("Error reading metadata.")
                picker.dismiss(animated: true, completion: nil)
            }
            if let PickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            {
                LoadedImageView.image = PickedImage
            }
            else
            {
                LoadedImageView.image = nil
            }
            ImageNameLabel.text = "Loaded Image"
            //https://stackoverflow.com/questions/27854937/ios8-photos-framework-how-to-get-the-nameor-filename-of-a-phasset
            if let Asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset
            {
                PHImageManager.default().requestImageData(for: Asset, options: PHImageRequestOptions(),
                                                          resultHandler:
                    {
                        (ImageData, DataUTI, Orientation, info) in
                        if let Info = info
                        {
                            if Info.keys.contains(NSString(string: "PHImageFileURLKey"))
                            {
                                if let Path = Info[NSString(string: "PHImageFileURLKey")] as? NSURL
                                {
                                    let OriginalFileName = Path.lastPathComponent!
                                    self.ImageNameLabel.text = OriginalFileName
                                }
                            }
                        }
                }
                )
            }
            ExifTable.reloadData()
            SendButton.isEnabled = true
        }
        else
        {
            print("Error getting image url.")
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    var MetadataReader: ImageMetadataReader? = nil
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleSendButtonPressed(_ sender: Any)
    {
        let Items: [Any] = [self]
        let ACV = UIActivityViewController(activityItems: Items, applicationActivities: nil)
        present(ACV, animated: true)
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return "Metadata for Image"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        switch activityType!
        {
        case .postToTwitter:
            return "Tweeted"
            
        case .airDrop:
            return "Hiya"
            
        case .copyToPasteboard:
            return "test text"
            
        case .mail:
            return "test"
            
        case .postToTencentWeibo:
            return "test"
            
        case .postToWeibo:
            return "test"
            
        case .print:
            return "test"
            
        case .markupAsPDF:
            return "test"
            
        case .message:
            return "test"
            
        default:
            return "Test text"
        }
    }
    
    @IBOutlet weak var SendButton: UIBarButtonItem!
    @IBOutlet weak var LoadedImageView: UIImageView!
    @IBOutlet weak var ImageNameLabel: UILabel!
    @IBOutlet weak var ExifTable: UITableView!
}
