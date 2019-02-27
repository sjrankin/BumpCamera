//
//  ModeSelectorButton.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Button used in the mode selection UI. The buttons here are nothing more than dressed-up
/// UIViews and a tap gestures attached.
class ModeSelectorButton: UIView, ButtonActionProtocol
{
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
    
    /// Program-level initialization.
    func Initialize()
    {
        UpdateVisuals()
        let Tap = UITapGestureRecognizer(target: self, action: #selector(HandleTap))
        addGestureRecognizer(Tap)
    }
    
    /// Handles tap gestures by notifying the appropriate delegate that a button press
    /// occurred.
    ///
    /// - Parameter TapGesture: Gesture recognizer.
    @objc func HandleTap(TapGesture: UITapGestureRecognizer)
    {
        if TapGesture.state == .ended
        {
            ParentDelegate?.ButtonPressed(ButtonMode)
        }
    }
    
    /// Update button visuals depending on whether it is toggle-able.
    func UpdateVisuals()
    {
        if IsTogglable
        {
            layer.borderColor = UIColor.white.cgColor
            layer.borderWidth = 0.5
            layer.cornerRadius = 8.0
            backgroundColor = UIColor.darkGray
        }
        else
        {
            layer.borderColor = UIColor.blue.cgColor
            layer.borderWidth = 0.5
            layer.cornerRadius = 8.0
            backgroundColor = UIColor.white
        }
    }
    
    /// Stores the name of the button.
    private var _Name: String = ""
    /// Get or set the name of the button.
    @IBInspectable var Name: String
    {
        get
        {
            return _Name
        }
        set
        {
            _Name = newValue
            UpdateVisuals()
        }
    }
    
    /// Stores the toggle-able state.
    private var _IsTogglable: Bool = true
    /// Get or set the toggle-able state. If false, the button cannot be toggled into
    /// various states/colors and functions as a more-or-less normal button.
    @IBInspectable var IsTogglable: Bool
    {
        get
        {
            return _IsTogglable
        }
        set
        {
            _IsTogglable = newValue
        }
    }
    
    /// Stores the button type.
    private var _ButtonMode: ModeButtonTypes = .About
    /// Get or set the button mode type.
    public var ButtonMode: ModeButtonTypes
    {
        get
        {
            return _ButtonMode
        }
    }
    
    @available(*, unavailable, message: "Only available in Interface Builder.")
    /// Set the type of button this is. Available only in the Interface Builder.
    @IBInspectable var ButtonType: String?
    {
        willSet
        {
            if let Value = ModeButtonTypes(rawValue: newValue?.lowercased() ?? "")
            {
                _ButtonMode = Value
            }
        }
    }
    
    /// The delegate to the button's parent - this should be the mode selection UI itself.
    weak var ParentDelegate: ButtonActionProtocol? = nil
    
    /// Not executed in this class.
    func ButtonPressed(_ ButtonType: ModeButtonTypes)
    {
        //Not intended to be executed in this class.
    }
    
    /// Set the selection state of the button.
    ///
    /// - Parameter ToState: Describes the state to put the button in.
    func SetSelectedState(ToState: ButtonSelectionStates)
    {
        switch ToState
        {
        case .NotSelected:
            if !IsTogglable
            {
                return
            }
            backgroundColor = UIColor.darkGray
            
        case .Selected:
            if !IsTogglable
            {
                return
            }
            backgroundColor = UIColor(named: "Daffodil")
            
        case .Disabled:
            backgroundColor = UIColor.black
            
        case .Normal:
            UpdateVisuals()
        }
    }
}
