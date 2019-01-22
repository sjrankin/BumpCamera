//
//  MainUILabelManagement.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Extensions for transient labels for the main UI.
extension MainUIViewer
{
    /// Initialize the label controls.
    func InitializeLabels()
    {
        StatusLabel.layer.cornerRadius = 5.0
        StatusLabel.layer.borderColor = UIColor.black.cgColor
        StatusLabel.layer.borderWidth = 0.5
        StatusLabel.textColor = UIColor.black
        StatusLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        StatusLabel.alpha = 0.0
        
        FilterLabel.textColor = UIColor.white
        FilterLabel.layer.cornerRadius = 15.0
        ShowFilter("No Filter")
        SetFilterLabelVisibility(IsVisible: true)
    }
    
    /// Sets the visibility of the filter label.
    ///
    /// - Parameter IsVisible: Set to true to show the filter label, false to hide it. The user setting
    ///                        HideFilterName overrides this parameter.
    /// - Parameter AnimationDuration: The length of the duration of the animation.
    func SetFilterLabelVisibility(IsVisible: Bool, AnimationDuration: Double = 0.5)
    {
        FilterLabelIsVisible = IsVisible
        if _Settings.bool(forKey: "HideFilterName")
        {
            self.FilterLabel.alpha = 0.0
            return
        }
        if !FilterLabelIsVisible
        {
            UIView.animate(withDuration: AnimationDuration)
            {
                self.FilterLabel.alpha = 0.0
            }
        }
        else
        {
            UIView.animate(withDuration: AnimationDuration)
            {
                self.FilterLabel.alpha = 0.5
                self.FilterLabel.textColor = UIColor.black
                self.FilterLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
            }
        }
    }
    
    /// Show a transient message - used mostly for "image saved" purposes.
    ///
    /// - Parameter Message: The message to display. Long messages will be truncated.
    /// - Parameter AnimationDuration: How long the fade-out will animate.
    /// - Parameter AnimationDelay: How long to wait before starting the fade out animation.
    func ShowTransientSaveMessage(_ Message: String, AnimationDuration: Double = 0.5,
                                  AnimationDelay: Double = 1.5)
    {
        StatusLabel.text = Message
        StatusLabel.alpha = 1.0
        StatusLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        UIView.animate(withDuration: AnimationDuration, delay: AnimationDelay, options: [],
                       animations: {
                        self.StatusLabel.alpha = 0.0
        }, completion: nil)
    }
    
    /// Show a transient message on the screen.
    ///
    /// - Attention: Figure out if we need this function as well as ShowTransientSaveMessage.
    ///
    /// - Parameters:
    ///   - Message: The message to display - long messages will be truncated.
    ///   - AnimationDuration: How long the fade-out animation will take.
    ///   - AnimationDelay: How long to wait until starting the fade-out animation.
    func ShowMessage(_ Message: String, AnimationDuration: Double = 0.5,
                     AnimationDelay: Double = 5.0)
    {
        StatusLabel.text = Message
        StatusLabel.alpha = 1.0
        StatusLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.65)
        UIView.animate(withDuration: AnimationDuration, delay: AnimationDelay, options: [], animations:
            {
                self.StatusLabel.alpha = 0.0
        }, completion: nil)
    }
    
    /// Update the filter name on the UI.
    ///
    /// - Parameters:
    ///   - Message: The name of the filter to display.
    ///   - AnimationDuration: How long the fade to lower visibility animation should take.
    ///   - AnimationDelay: How long to wait until starting the fade out animation.
    func ShowFilter(_ Message: String, AnimationDuration: Double = 2.5,
                    AnimationDelay: Double = 5.0)
    {
        #if false
        FilterLabel.text = "   " + Message
        #else
        FilterLabel.text = Message
        #endif
        if !FilterLabelIsVisible
        {
            return
        }
        FilterLabel.alpha = 1.0
        FilterLabel.textColor = UIColor.white
        FilterLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        UIView.animate(withDuration: AnimationDuration, delay: AnimationDelay, options: [], animations:
            {
                self.FilterLabel.alpha = 0.5
                self.FilterLabel.textColor = UIColor.black
        }
            , completion: nil)
    }
}
