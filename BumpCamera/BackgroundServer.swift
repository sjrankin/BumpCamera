//
//  BackgroundServer.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/12/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Serves backgrounds to whomever wants one. This class reads setup and display information from user settings so
/// all instances will appear the same.
class BackgroundServer
{
    /// Initialize the background.
    ///
    /// - Parameter Surface: The surface of where the background will be drawn.
    init(_ Surface: UIView)
    {
        BackgroundView = Surface
        InitializeGradientLayer(BackgroundView: Surface)
//        GetBackgroundColors()
        UpdateBackgroundColors()
    }
    
    private var BackgroundView: UIView? = nil
    
    private var _BGColor1: UIColor = UIColor(hue: 0.0, saturation: 0.8, brightness: 0.7, alpha: 1.0)
    public var BGColor1: UIColor
    {
        get
        {
            return _BGColor1
        }
        set
        {
            _BGColor1 = newValue
        }
    }
    
    private var _Position1: CGFloat = 0.0
    public var Position1: CGFloat
    {
        get
        {
            return _Position1
        }
        set
        {
            _Position1 = newValue
        }
    }
    
    private var _BGColor2: UIColor = UIColor(hue: 0.5, saturation: 0.8, brightness: 0.6, alpha: 1.0)
    public var BGColor2: UIColor
    {
        get
        {
            return _BGColor2
        }
        set
        {
            _BGColor2 = newValue
        }
    }
    
    private var _Position2: CGFloat = 1.0
    public var Position2: CGFloat
    {
        get
        {
            return _Position2
        }
        set
        {
            _Position2 = newValue
        }
    }
    
    #if false
    private let _Settings = UserDefaults.standard
    
    private var _BGColor1: BackgroundColors? = nil
    /// Get or set the first background color. This color should always be present - if no other colors are present, this
    /// color fills the background. If other colors are present, this color is the top-most color of the gradient.
    public var BGColor1: BackgroundColors?
    {
        get
        {
            return _BGColor1
        }
        set
        {
            _BGColor1 = newValue
        }
    }
    
    private var _BGColor2: BackgroundColors? = nil
    /// Get or set the second background color - this is the middle gradient color.
    public var BGColor2: BackgroundColors?
    {
        get
        {
            return _BGColor2
        }
        set
        {
            _BGColor2 = newValue
        }
    }
    
    private var _BGColor3: BackgroundColors? = nil
    /// Get or set the third background color - this is the bottom gradient color.
    public var BGColor3: BackgroundColors?
    {
        get
        {
            return _BGColor3
        }
        set
        {
            _BGColor3 = newValue
        }
    }
    
    /// Get the background colors from settings and set the gradients as appropriate.
    public func GetBackgroundColors()
    {
        BGColor1 = Setting.GetBackgroundColor(For: 1)
        BGColor2 = Setting.GetBackgroundColor(For: 2)
        BGColor3 = Setting.GetBackgroundColor(For: 3)
        SetGradientColors()
    }
    
    /// The Setting class notified us that a BG color has been saved (and was potentially changed). Reload
    /// the background color.
    ///
    /// - Parameter Index: Index of the background color that changed.
    public func UpdateBGColor(_ Index: Int)
    {
        switch Index
        {
        case 1:
            BGColor1 = Setting.GetBackgroundColor(For: 1)
            
        case 2:
            BGColor2 = Setting.GetBackgroundColor(For: 2)
            
        case 3:
            BGColor3 = Setting.GetBackgroundColor(For: 3)
            
        default:
            print("Found unexpected color (\(Index)) in UpdateBGColor.")
        }
    }
    #endif
    
    private var _GradientLayerInitialized: Bool = false
    /// Get or set the gradient layer is initialized flag.
    public var GradientLayerInitialized: Bool
    {
        get
        {
            return _GradientLayerInitialized
        }
        set
        {
            _GradientLayerInitialized = newValue
        }
    }
    
    private var _Gradient: CAGradientLayer!
    /// Get or set the gradient layer.
    public var Gradient: CAGradientLayer!
    {
        get
        {
            return _Gradient
        }
        set
        {
            _Gradient = newValue
        }
    }
    
    /// Make and return a copy of the specified gradient layer.
    ///
    /// - Parameter Source: The gradient layer to copy.
    /// - Returns: Copy of the passed gradient layer.
    public func CopyLayer(_ Source: CAGradientLayer) -> CAGradientLayer
    {
        let Copied = CAGradientLayer()
        Copied.frame = Source.frame
        Copied.bounds = Source.bounds
        Copied.locations = Source.locations
        Copied.colors = Source.colors
        
        return Copied
    }
    
    /// Return a copy the main gradient layer with the specified frame and bounds.
    ///
    /// - Parameters:
    ///   - WithFrame: New frame.
    ///   - WithBounds: New bounds.
    ///   - WithID: If specified the ID of the returned gradient layer. If not specified, not ID is set.
    /// - Returns: Copy of the current gradient layer with the passed frame and bounds. Nil if
    ///            the background server hasn't been initialized.
    public func CopyGradient(WithFrame: CGRect, WithBounds: CGRect, WithID: UUID? = nil) -> CAGradientLayer?
    {
        if !GradientLayerInitialized
        {
            print("Gradient not initialized.")
            return nil
        }
        let Final = CopyLayer(Gradient)
        if let WithID = WithID
        {
            Final.setValue(WithID, forKey: "ID")
        }
        Final.frame = WithFrame
        Final.bounds = WithBounds
        return Final
    }
    
    /// Apply a copy of the current gradient to the passed view.
    ///
    /// - Parameter ToView: The view to apply a copy of the current gradient to.
    /// - Returns: True on success, false on failure.
    public func ApplyGradient(ToView: UIView) -> Bool
    {
        if !GradientLayerInitialized
        {
            return false
        }
        let GradientLayer = CopyGradient(WithFrame: ToView.frame, WithBounds: ToView.bounds)
        ToView.layer.insertSublayer(GradientLayer!, at: 0)
        ToView.layer.masksToBounds = true
        ToView.backgroundColor = UIColor.clear
        return true
    }
    
    /// Initialize the gradient layer used as the color background.
    ///
    /// - Parameter BackgroundView: The surface UI view where the gradient will be drawn.
    public func InitializeGradientLayer(BackgroundView: UIView)
    {
        if GradientLayerInitialized
        {
            return
        }
        GradientLayerInitialized = true
        Gradient = CAGradientLayer()
        Gradient.setValue(UUID(), forKey: "ID")
        Gradient.frame = BackgroundView.bounds
        Gradient.bounds = BackgroundView.bounds
        BackgroundView.layer.insertSublayer(Gradient, at: 0)
        BackgroundView.layer.masksToBounds = true
        BackgroundView.backgroundColor = UIColor.clear
    }
    
    /// Set the gradient colors as appropriate to the gradient layer.
    public func SetGradientColors()
    {
        #if true
        Gradient.colors?.removeAll()
        Gradient.colors = [BGColor1.cgColor as Any, BGColor2.cgColor as Any]
        let Locations: [NSNumber] = [NSNumber(value: Double(Position1)), NSNumber(value: Double(Position2))]
        Gradient.locations = Locations
        #else
        let GradientColorCount = _Settings.integer(forKey: Setting.Key.BackgroundColors.BackgroundColorCount)
        Gradient.colors?.removeAll()
        switch GradientColorCount
        {
        case 0:
            Gradient.colors = [BGColor1?.Color().cgColor as Any, BGColor1?.Color().cgColor as Any]
            Gradient.locations = nil
            
        case 1:
            Gradient.colors = [BGColor1?.Color().cgColor as Any, BGColor2?.Color().cgColor as Any]
            Gradient.locations = nil
            
        case 2:
            Gradient.colors = [BGColor1?.Color().cgColor as Any, BGColor2?.Color().cgColor as Any, BGColor3?.Color().cgColor as Any]
            let Middle = _Settings.double(forKey: Setting.Key.BackgroundColors.BGColor2Location)
            let Locations: [NSNumber] = [0.0, NSNumber(value: Middle), 1.0]
            Gradient.locations = Locations
            
        default:
            print("Unexpected number (\(GradientColorCount)) of gradients found.")
        }
        #endif
    }
    
    /// Update the background color. If gradients are enabled, all gradient colors/positions are updated.
    ///
    /// - Parameter GLayer: The gradient to animate.
    public func UpdateBackgroundColors(_ GLayer: CAGradientLayer)
    {
        #if true
        let Now = Date()
        let Color1 = MoveColor(BGColor1, ToTime: Now)
        let Color2 = MoveColor(BGColor2, ToTime: Now)
        let NewColors: [CGColor] = [Color1.cgColor, Color2.cgColor]
        if PreviousColors.isEmpty
        {
            PreviousColors = [UIColor.white.cgColor, UIColor.black.cgColor]
        }
        #else
        let BGColorCount = _Settings.integer(forKey: Setting.Key.BackgroundColors.BackgroundColorCount)
        let Now = Date()
        
        let Color1 = BGColor1?.Move(ToTime: Now)
        let Color2 = BGColor2?.Move(ToTime: Now)
        let Color3 = BGColor3?.Move(ToTime: Now)
        var NewColors = [CGColor]()
        
        switch BGColorCount
        {
        case 0:
            NewColors = [Color1!.cgColor, Color1!.cgColor]
            if PreviousColors.isEmpty || PreviousColors.count != 2
            {
                PreviousColors = [UIColor.white.cgColor, UIColor.black.cgColor]
            }
            
        case 1:
            NewColors = [Color1!.cgColor, Color2!.cgColor]
            if PreviousColors.isEmpty || PreviousColors.count != 2
            {
                PreviousColors = [UIColor.white.cgColor, UIColor.black.cgColor]
            }
            
        case 2:
            NewColors = [Color1!.cgColor, Color2!.cgColor, Color3!.cgColor]
            if PreviousColors.isEmpty || PreviousColors.count != 3
            {
                PreviousColors = [UIColor.white.cgColor, UIColor.gray.cgColor, UIColor.black.cgColor]
            }
            
        default:
            print("Unexpected number of background colors: \(BGColorCount))")
            return
        }
        #endif
        
        let BGAnimation = CABasicAnimation(keyPath: "colors")
        BGAnimation.duration = 1
        BGAnimation.fillMode = CAMediaTimingFillMode.forwards
        BGAnimation.isRemovedOnCompletion = false
        BGAnimation.fromValue = PreviousColors
        BGAnimation.toValue = NewColors
        GLayer.add(BGAnimation, forKey: "colorChange")
        PreviousColors = NewColors
    }
    
    /// Used to store previous gradient colors.
    var PreviousColors = [CGColor]()
    
    /// Update the background color. If gradients are enabled, all gradient colors/positions are updated.
    public func UpdateBackgroundColors()
    {
        UpdateBackgroundColors(Gradient)
    }
    
    /// Return the gradient layer in the passed UIView whose ID is also passed.
    ///
    /// - Parameters:
    ///   - InView: The UIView where the gradient layer lives.
    ///   - WithID: The ID of the gradient layer to return.
    /// - Returns: The specified gradient layer on success, nil if not found.
    public func FindGradient(_ InView: UIView, _ WithID: UUID) -> CAGradientLayer?
    {
        var Final: CAGradientLayer? = nil
        InView.layer.sublayers?.forEach{if $0.value(forKey: "ID") as! UUID == WithID
        {
            Final = $0 as? CAGradientLayer
            }
        }
        return Final
    }
    
    private var GradientCache = [UUID: CAGradientLayer]()
    
    private func GetCachedGradient(_ InView: UIView, _ WithID: UUID) -> CAGradientLayer?
    {
        if let CachedGradient = GradientCache[WithID]
        {
            return CachedGradient
        }
        let NewGradient = FindGradient(InView, WithID)
        if NewGradient == nil
        {
            return nil
        }
        GradientCache[WithID] = NewGradient
        return NewGradient
    }
    
    public func ClearCacheOf(_ WithID: UUID)
    {
        GradientCache.removeValue(forKey: WithID)
    }
    
    /// Given a UIView, update the gradient layer in the layer array. The gradient layer must have an ID with the value passed
    /// by the caller.
    ///
    /// - Parameters:
    ///   - InView: The view with the gradient layer to update.
    ///   - WithID: The ID of the gradient layer to update.
    public func UpdateBackgroundColors(InView: UIView, WithID: UUID)
    {
        let GLayer = FindGradient(InView, WithID)
        if GLayer == nil
        {
            print("Could not find gradient layer with specified ID.")
            return
        }
        UpdateBackgroundColors(GLayer!)
    }
    
    private var _TimePeriod: Int = 0
    public var TimePeriod: Int
    {
        get
        {
            return _TimePeriod
        }
        set
        {
            _TimePeriod = newValue
        }
    }
    
    private func MoveColor(_ SourceColor: UIColor, ToTime: Date) -> UIColor
    {
        var Hue: CGFloat = 0.0
        var Saturation: CGFloat = 0.0
        var Brightness: CGFloat = 0.0
        var Alpha: CGFloat = 0.0
         SourceColor.getHue(&Hue, saturation: &Saturation, brightness: &Brightness, alpha: &Alpha)
        let PeriodPercent = Times.Percent(Period: TimePeriod, Now: ToTime)
        var WorkingHue = (Hue * 360.0) + CGFloat(PeriodPercent * 360.0)
        WorkingHue = fmod(WorkingHue, 360.0)
        WorkingHue = WorkingHue / 360.0
        let Final = UIColor(hue: WorkingHue, saturation: Saturation, brightness: Brightness, alpha: Alpha)
        return Final
    }
}
