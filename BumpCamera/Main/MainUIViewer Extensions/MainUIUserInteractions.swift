//
//  MainUIUserInteractions.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/9/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

extension MainUIViewer
{
    /// Handle taps on the main UI.
    /// - If the tap is near the filter label, toggle its visibility.
    /// - If the tap is in the main view, set the focus.
    ///
    /// - Parameter sender: The gesture.
    @objc func HandlePreviewTap(Gesture: UITapGestureRecognizer)
    {
        if Gesture.state == .ended
        {
            if _Settings.bool(forKey: "ShowFilterName")
            {
                let TapLocation = Gesture.location(in: LiveView)
                if TapLocation.y <= FilterLabel.frame.minY + FilterLabel.frame.height
                {
                    if FilterLabelIsVisible
                    {
                        SetFilterLabelVisibility(IsVisible: false)
                    }
                    else
                    {
                        SetFilterLabelVisibility(IsVisible: true)
                    }
                    return
                }
                else
                {
                    let Location = Gesture.location(in: LiveView)
                    let TextureRect = CGRect(origin: Location, size: .zero)
                    let DeviceRect = VideoDataOutput.metadataOutputRectConverted(fromOutputRect: TextureRect)
                    focus(with: .autoFocus, exposureMode: .autoExpose, at: DeviceRect.origin, monitorSubjectAreaChange: true)
                }
            }
            #if false
            if FiltersAreShowing
            {
                UpdateFilterSelectionVisibility()
            }
            #endif
        }
    }
}
