//
//  ModeSelectorUI.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Runs the mode selector UI.
class ModeSelectorUI: UIView, ButtonActionProtocol
{
    /// Delegate to the main UI. Used to let it know which button was pressed.
    weak var MainDelegate: MainUIProtocol? = nil
    
    /// Initializer.
    ///
    /// - Parameter frame: See iOS documentation.
    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    /// Initializer.
    ///
    /// - Parameter aDecoder: See iOS documentation.
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    /// Initializes the mode selection UI.
    ///
    /// - Note: Perhaps move this to a "normal" initializer...
    ///
    /// - Parameter SelectedButton: The button to select on start up.
    /// - Parameter InitialFrame: The frame of the UI before it's hidden.
    func Initialize(SelectedButton: Int, InitialFrame: CGRect)
    {
        VisibleFrame = InitialFrame
        print("Mode selection UI VisibleFrame=\((VisibleFrame)!)")
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 5.0
        layer.zPosition = 600
        backgroundColor = UIColor.black
        var SelectMe = ModeSelectorUI.ModeMap[SelectedButton]
        if SelectMe == nil
        {
            SelectMe = .LiveView
        }
        for SomeView in subviews
        {
            if let Button = SomeView as? ModeSelectorButton
            {
                Button.Initialize()
                Button.ParentDelegate = self
                if Button.ButtonMode == SelectMe
                {
                    Button.SetSelectedState(ToState: .Selected)
                }
            }
        }
    }
    
    var VisibleFrame: CGRect!
    
    /// Handle button press events from the UI's set of buttons (which are really
    /// nothing more than UIViews with pictures).
    ///
    /// - Parameter ButtonType: Determines which button was pressed.
    func ButtonPressed(_ ButtonType: ModeButtonTypes)
    {
        print("Button \(ButtonType.rawValue) pressed.")
        MainDelegate?.ModeButtonPressed(ButtonType: ButtonType)
        for SomeView in subviews
        {
            if let Button = SomeView as? ModeSelectorButton
            {
                if Button.ButtonMode == ButtonType
                {
                    Button.SetSelectedState(ToState: .Selected)
                }
                else
                {
                    Button.SetSelectedState(ToState: .NotSelected)
                }
            }
        }
    }
    
    /// Not used in this class.
    func SetSelectedState(ToState: ButtonSelectionStates)
    {
        //Not intended to be executed in this class.
    }
    
    /// Showing mode selector UI field.
    var IsShowing = true
    
    /// Show the mode selection UI.
    ///
    /// - Parameter Duration: Duration of the animation used to show the UI.
    func Show(Duration: Double = 0.15)
    {
        IsShowing = true
        self.isHidden = false
        UIView.animate(withDuration: Duration, delay: 0.0,
                       options: [UIView.AnimationOptions.curveEaseIn],
                       animations: {
                        self.frame = CGRect(x: -10, y: 233, width: 110, height: 450)
                        }, completion:
            {
                _ in
                self.isHidden = false
        })
    }
    
    /// Hide the mode selection UI.
    ///
    /// - Parameter Duration: Duration of the animation used to hide the UI.
    func Hide()
    {
        IsShowing = false
        UIView.animate(withDuration: 0.3, delay: 0.0,
                       options: [UIView.AnimationOptions.curveEaseIn],
                       animations: {
                        self.frame = CGRect(x: -120, y: 233, width: 110, height: 450)
        }, completion:
            {
                _ in
                self.isHidden = true
        })
    }
    
    /// Map from integer mode values to enum mode values.
    public static let ModeMap =
    [
        0: ModeButtonTypes.LiveView,
        1: ModeButtonTypes.Video,
        2: ModeButtonTypes.GIF,
        3: ModeButtonTypes.Editor,
        4: ModeButtonTypes.OnTheFly
    ]
}

/// Describes the various mode buttons and modes.
///
/// - About: The about/settings mode button.
/// - LiveView: Live view mode button.
/// - Video: Video mode button.
/// - GIF: Animated GIF mode button.
/// - Editor: Editor mode button.
/// - OnTheFly: On-the-fly mode button.
enum ModeButtonTypes: String
{
    case About = "about"
    case LiveView = "liveview"
    case Video = "video"
    case GIF = "gif"
    case Editor = "edit"
    case OnTheFly = "onthefly"
}

/// Protocol to communicate button presses and state changes.
protocol ButtonActionProtocol: class
{
    /// Called when a button is pressed.
    ///
    /// - Parameter ButtonType: Describes the pressed button.
    func ButtonPressed(_ ButtonType: ModeButtonTypes)
    
    /// Change the state of a button.
    ///
    /// - Parameter ToState: New state for the button.
    func SetSelectedState(ToState: ButtonSelectionStates)
}

/// Button selection states.
///
/// - NotSelected: Not selected.
/// - Selected: Selected.
/// - Disabled: Disabled.
/// - Normal: Normal. (How is this different from NotSelected?)
enum ButtonSelectionStates
{
    case NotSelected
    case Selected
    case Disabled
    case Normal
}


