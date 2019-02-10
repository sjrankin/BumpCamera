//
//  AVCaptureVideoOrientationExtension.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension AVCaptureVideoOrientation
{
    init?(interfaceOrientation: UIInterfaceOrientation)
    {
        switch interfaceOrientation
        {
        case .portrait:
            self = .portrait
            
        case .portraitUpsideDown:
            self = .portraitUpsideDown
            
        case .landscapeLeft:
            self = .landscapeLeft
            
        case .landscapeRight:
            self = .landscapeRight
            
        default: return nil
        }
    }
}
