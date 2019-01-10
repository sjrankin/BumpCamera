//
//  ImagePreviewController.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ImagePreviewController: UIViewController, ImageViewProtocol
{
    var delegate: MainUIViewer? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let TheImage = PreviewImage
        {
            PreviewImageOut.image = TheImage
        }
    }
    
    func ImageToPreview(_ Image: UIImage)
    {
        PreviewImage = Image
    }
    
    @IBOutlet weak var PreviewImageOut: UIImageView!
    
    var PreviewImage: UIImage? = nil
    
    func ClosePreview()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleSaveButton(_ sender: Any)
    {
        delegate?.DoSaveImage()
        ClosePreview()
    }
    
    @IBAction func HandleCancelButton(_ sender: Any)
    {
        print("Save canceled")
        ClosePreview()
    }
}
