//
//  GSlider.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GSlider: UIView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        LocalInit()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        LocalInit()
    }
    
    weak var ParentDelegate: GSliderProtocol? = nil
    
    func LocalInit()
    {
        clipsToBounds = true
        UpdateGradient()
        DrawIndicator()
        UpdateBorder()
        let Tap = UITapGestureRecognizer(target: self, action: #selector(HandleTapped))
        addGestureRecognizer(Tap)
    }
    
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
    
    func PercentFromLocation(Location: CGPoint) -> Double
    {
        if IsHorizontal
        {
            let Width = self.frame.width
            let WPercent = Double(Location.x / Width)
            return WPercent
        }
        else
        {
            let Height = self.frame.height
            let HPercent = Double(Location.y / Height)
            return HPercent
        }
    }
    
    func Refresh(SliderName: String, WithRect: CGRect)
    {
        NewFrame = WithRect
        UpdateGradient()
        DrawIndicator()
    }
    
    var NewFrame = CGRect.zero
    
    func UpdateBorder()
    {
        if DrawBorder
        {
            self.layer.borderColor = _BorderColor.cgColor
            self.layer.borderWidth = 0.5
            if RoundCorneredBordes
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
    
    private var _RoundCorneredBorders: Bool = true
    {
        didSet
        {
            UpdateBorder()
        }
    }
    @IBInspectable var RoundCorneredBordes: Bool
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
    
    private var _DrawBorder: Bool = true
    {
        didSet
        {
            UpdateBorder()
        }
    }
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
    
    private var _BorderColor: UIColor = UIColor.black
    {
        didSet
        {
            UpdateBorder()
        }
    }
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
    
    private var _IsHorizontal: Bool = true
    {
        didSet
        {
            UpdateGradient()
            DrawIndicator()
        }
    }
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
    
    private var _GradientStart: UIColor = UIColor.white
    {
        didSet
        {
            UpdateGradient()
        }
    }
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
    
    private var _GradientEnd: UIColor = UIColor.black
    {
        didSet
        {
            UpdateGradient()
        }
    }
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
    
    private var _Value: Double = 0.0
    {
        didSet
        {
            DrawIndicator()
        }
    }
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
    
    func InRange(_ SomeValue: Double) -> Bool
    {
        if SomeValue < _MinValue || SomeValue > _MaxValue
        {
            return false
        }
        return true
    }
    
    var _MinValue: Double = 0.0
    {
        didSet
        {
            DrawIndicator()
        }
    }
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
    
    var _MaxValue: Double = 1.0
    {
        didSet
        {
            DrawIndicator()
        }
    }
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
    
    var _Name: String = ""
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
    
    func DrawIndicator()
    {
        
    }
    
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
    
    var GradientLayer: CAGradientLayer? = nil
    
}
