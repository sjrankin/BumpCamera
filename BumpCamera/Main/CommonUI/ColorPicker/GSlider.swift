//
//  GSlider.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// This class is the first version implementation of a gradient-backed slider control that allows
/// vertical as well as horizontal orientations.
@IBDesignable class GSlider: UIControl
{
    /// Initializer.
    ///
    /// - Parameter frame: See iOS documentation.
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        LocalInit()
    }
    
    /// Initializer.
    ///
    /// - Parameter aDecoder: See iOS documentation.
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        LocalInit()
    }
    
    /// Delegate to the control owner to notify the owner of value changes.
    weak var ParentDelegate: GSliderProtocol? = nil
    
    /// Local initialization.
    func LocalInit()
    {
        clipsToBounds = true
        UpdateGradient()
        DrawIndicator()
        UpdateBorder()
        let Tap = UITapGestureRecognizer(target: self, action: #selector(HandleTapped))
        addGestureRecognizer(Tap)
    }
    
    /// Handle taps on the slider. The value is recalculated and the indicator is moved as
    /// appropriate. The parent of the control is notified.
    ///
    /// - Parameter TapGesture: The tap gesture that describes the tap.
    @objc func HandleTapped(TapGesture: UITapGestureRecognizer)
    {
        let Where = TapGesture.location(in: self)
        let Percent = PercentFromLocation(Location: Where)
        let Range = MaxValue - MinValue
        Value = (Range * Percent) + MinValue
        DrawIndicator()
        if TapGesture.state == .ended
        {
            ParentDelegate?.NewSliderValue(Name: Name, NewValue: Value)
        }
    }
    
    /// Calculates the percent location (depending on the orientation) of the tap in the control.
    ///
    /// - Parameter Location: Location to calculate the percentage from.
    /// - Returns: Percent along the long axis of the control where the tap was. (The long axis is
    ///            defined by the IsHorizontal property regardless of the actual geometry of the
    ///            control.)
    func PercentFromLocation(Location: CGPoint) -> Double
    {
        if IsHorizontal
        {
            let Width = self.frame.width
            let Adjusted = Width - Location.x
            let WPercent = Adjusted / Width
            return Double(1.0 - WPercent)
        }
        else
        {
            let Height = self.frame.height
            let Adjusted = Height - Location.y
            let HPercent = Adjusted / Height
            return Double(1.0 - HPercent)
        }
    }
    
    /// Refresh the layout of the control. This function must be called by the parent's viewDidLayoutSubviews
    /// code in order for gradients to properly fill the control. This is because UIView events are not as
    /// extensive as a UIViewController and the event that fires to tell the UIView to draw may come before it
    /// is fully laid out, meaning things don't fit the final geometry.
    ///
    /// - Parameters:
    ///   - SliderName: Name of the slider to refresh. Debug use only.
    ///   - WithRect: The rectangle to use to draw the control.
    func Refresh(SliderName: String, WithRect: CGRect)
    {
        NewFrame = WithRect
        UpdateGradient()
        DrawIndicator()
    }
    
    /// Used to store the refrehed geometry.
    var NewFrame = CGRect.zero
    
    /// Update the border of the control. Called when a public attribute changes.
    func UpdateBorder()
    {
        if DrawBorder
        {
            self.layer.borderColor = _BorderColor.cgColor
            self.layer.borderWidth = 0.5
            if RoundCorneredBorders
            {
                self.layer.cornerRadius = 5.0
            }
            else
            {
                self.layer.cornerRadius = 0.0
            }
        }
        else
        {
            self.layer.borderWidth = 0.0
        }
    }
    
    /// Holds the value that determines if the border of the control is rounded. Updates the border
    /// when set.
    private var _RoundCorneredBorders: Bool = true
    {
        didSet
        {
            UpdateBorder()
        }
    }
    /// Get or set the value that determines whether the border of the control has rounded
    /// corners. Setting this value causes an immediate visual update (if DrawBorder is true).
    @IBInspectable var RoundCorneredBorders: Bool
        {
        get
        {
            return _RoundCorneredBorders
        }
        set
        {
            _RoundCorneredBorders = newValue
        }
    }
    
    /// Holds the value that determines whether borders are drawn around the control or not. Updates
    /// the border when set.
    private var _DrawBorder: Bool = true
    {
        didSet
        {
            UpdateBorder()
        }
    }
    /// Get or set the border is visible flag. Setting this value causes an immediate visual upate.
    @IBInspectable var DrawBorder: Bool
        {
        get
        {
            return _DrawBorder
        }
        set
        {
            _DrawBorder = newValue
        }
    }
    
    /// Holds the color of the border. Updates the border when set.
    private var _BorderColor: UIColor = UIColor.black
    {
        didSet
        {
            UpdateBorder()
        }
    }
    /// Get or set the color used to paint the border. Setting this value causes an immediate visual
    /// update (if DrawBorder is true).
    @IBInspectable var BorderColor: UIColor
        {
        get
        {
            return _BorderColor
        }
        set
        {
            _BorderColor = newValue
        }
    }
    
    /// Holds the value that determines which axis is the varying axis. Updates the gradient and indicator
    /// when set.
    private var _IsHorizontal: Bool = true
    {
        didSet
        {
            UpdateGradient()
            DrawIndicator()
        }
    }
    /// Get or set the value that indicates if the long axis is the horizontal axis. If false, the vertical axis
    /// is used instead. The visual geometry of the control has no bearing on this value or how Value is calculated
    /// or reported. Setting this value causes an immediate visual update.
    @IBInspectable var IsHorizontal: Bool
        {
        get
        {
            return _IsHorizontal
        }
        set
        {
            _IsHorizontal = newValue
        }
    }
    
    /// Holds the initial gradient color. Updates the control gradient when set.
    private var _GradientStart: UIColor = UIColor.white
    {
        didSet
        {
            UpdateGradient()
        }
    }
    /// Get or set the initial gradient color. Setting this value causes an immediate visual update.
    @IBInspectable var GradientStart: UIColor
        {
        get
        {
            return _GradientStart
        }
        set
        {
            _GradientStart = newValue
        }
    }
    
    /// Holds the final gradient color. Updates the control gradient when set.
    private var _GradientEnd: UIColor = UIColor.black
    {
        didSet
        {
            UpdateGradient()
        }
    }
    /// Get or set the final gradient color. Setting this value causes an immediate visual update.
    @IBInspectable var GradientEnd: UIColor
        {
        get
        {
            return _GradientEnd
        }
        set
        {
            _GradientEnd = newValue
        }
    }
    
    /// Holds the current value of the control. Updates the indicator when set.
    private var _Value: Double = 0.0
    {
        didSet
        {
            DrawIndicator()
        }
    }
    /// Get or set the value of th control. Setting this property causes an immediate visual update.
    @IBInspectable var Value: Double
        {
        get
        {
            return _Value
        }
        set
        {
            if InRange(newValue)
            {
                _Value = newValue
            }
        }
    }
    
    /// Determines if the passed value is within the current property range (MinValue and MaxValue).
    ///
    /// - Parameter SomeValue: The value to test against MinValue and MaxValue.
    /// - Returns: True if SomeValue is in the MinValue:MaxValue range, false if not.
    func InRange(_ SomeValue: Double) -> Bool
    {
        if SomeValue < _MinValue || SomeValue > _MaxValue
        {
            return false
        }
        return true
    }
    
    /// Holds the minimum valid value. Setting this value will update the indicator.
    var _MinValue: Double = 0.0
    {
        didSet
        {
            DrawIndicator()
        }
    }
    /// Get or set the minimum valid value for the control. Setting this property will cause an
    /// immediate visual update.
    @IBInspectable var MinValue: Double
        {
        get
        {
            return _MinValue
        }
        set
        {
            if newValue > _MaxValue
            {
                return
            }
            if _Value < newValue
            {
                _Value = newValue
            }
            _MinValue = newValue
        }
    }
    
    /// Holds the maximum valid value. Setting this value will update the indicator.
    var _MaxValue: Double = 1.0
    {
        didSet
        {
            DrawIndicator()
        }
    }
    /// Get or set the maximum valid value for the control. Setting this property will cause an
    /// immediate visual update.
    @IBInspectable var MaxValue: Double
        {
        get
        {
            return _MaxValue
        }
        set
        {
            if newValue < _MinValue
            {
                return
            }
            if _Value > _MaxValue
            {
                _Value = newValue
            }
            _MaxValue = newValue
        }
    }
    
    /// Holds the name of the control.
    var _Name: String = ""
    /// Get or set the name of the control. No functional action taken by setting this property.
    @IBInspectable var Name: String
        {
        get
        {
            return _Name
        }
        set
        {
            _Name = newValue
        }
    }
    
    /// Draw the indicator showing the value in the control using previously set properties.
    func DrawIndicator()
    {
        if IndicatorLevel == nil
        {
            IndicatorLevel = CAShapeLayer()
            IndicatorLevel?.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            IndicatorLevel?.bounds = self.bounds
            IndicatorLevel?.name = "indicator"
            IndicatorLevel?.zPosition = 501
            self.layer.addSublayer(IndicatorLevel!)
        }
        else
        {
            IndicatorLevel?.frame = CGRect(x: 0, y: 0, width: NewFrame.width, height: NewFrame.height)
        }
        IndicatorLevel?.strokeColor = UIColor.yellow.cgColor
        IndicatorLevel?.fillColor = UIColor.black.cgColor
        IndicatorLevel?.lineWidth = 2.0
        let Indicator = UIBezierPath()
        if IsHorizontal
        {
            let Range = MaxValue - MinValue
            let Percent = (Value + MinValue) / Range
            let XPoint = self.frame.width * CGFloat(Percent)
            Indicator.move(to: CGPoint(x: XPoint, y: self.frame.height / 2.0))
            Indicator.addLine(to: CGPoint(x: XPoint - 8, y: self.frame.height - 2))
            Indicator.addLine(to: CGPoint(x: XPoint + 8, y: self.frame.height - 2))
            Indicator.addLine(to: CGPoint(x: XPoint, y: self.frame.height / 2.0))
        }
        else
        {
            let Range = MaxValue - MinValue
            let Percent = (Value + MinValue) / Range
            let YPoint = self.frame.height * CGFloat(Percent)
            Indicator.move(to: CGPoint(x: self.frame.width / 2.0, y: YPoint))
            Indicator.addLine(to: CGPoint(x: 2, y: YPoint - 8))
            Indicator.addLine(to: CGPoint(x: 2, y: YPoint + 8))
            Indicator.addLine(to: CGPoint(x: self.frame.width / 2.0, y: YPoint))
        }
        IndicatorLevel?.path = Indicator.cgPath
    }
    
    /// The indicator shape layer.
    var IndicatorLevel: CAShapeLayer? = nil
    
    /// Draw and update the gradient backgroun of the control using previously set properties.
    func UpdateGradient()
    {
        if GradientLayer == nil
        {
            GradientLayer = CAGradientLayer()
            //print("\(_Name): Bounds: \(self.bounds), Frame: \(self.frame)")
            GradientLayer?.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            GradientLayer?.bounds = self.bounds
            GradientLayer?.name = "gradient"
            GradientLayer?.zPosition = 500
            self.layer.addSublayer(GradientLayer!)
        }
        else
        {
            GradientLayer?.frame = CGRect(x: 0, y: 0, width: NewFrame.width, height: NewFrame.height)
        }
        GradientLayer?.colors = [GradientStart.cgColor as Any, GradientEnd.cgColor as Any]
        if _IsHorizontal
        {
            GradientLayer?.startPoint = CGPoint(x: 0.0, y: 0.0)
            GradientLayer?.endPoint = CGPoint(x: 1.0, y: 0.0)
        }
        else
        {
            GradientLayer?.startPoint = CGPoint(x: 0.0, y: 0.0)
            GradientLayer?.endPoint = CGPoint(x: 0.0, y: 1.0)
        }
    }
    
    /// The gradient layer.
    var GradientLayer: CAGradientLayer? = nil
    
}
