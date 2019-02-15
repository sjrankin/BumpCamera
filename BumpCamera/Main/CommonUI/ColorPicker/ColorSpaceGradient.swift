//
//  ColorSpaceGradient.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class ColorSpaceGradient: CAGradientLayer
{
    var HostDelegate: ColorPicker? = nil
    
    func Initialize(WithHue: CGFloat)
    {
        Hue = WithHue
    }
    
    func DrawGradient()
    {
        let Sat = UIColor(hue: Hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let Bri = UIColor(hue: Hue, saturation: 0.0, brightness: 0.0, alpha: 1.0)
        self.colors = [Sat.cgColor, Bri.cgColor]
        self.locations = [NSNumber(value: 0.0), NSNumber(value: 1.0)]
        self.startPoint = CGPoint(x: 0.0, y: 0.0)
        self.endPoint = CGPoint(x: 1.0, y: 1.0)
    }
    
    private var _Hue: CGFloat = 0.0
    private var PreviousHue: CGFloat = -1.0
    public var Hue: CGFloat
    {
        get
        {
            return _Hue
        }
        set
        {
            _Hue = newValue
            if _Hue != PreviousHue
            {
                DrawGradient()
                PreviousHue = _Hue
                if let Point = _TappedPoint
                {
                    if let Host = HostView
                    {
                        let NewColor = GetColorAt(Location: Point, InView: Host)
                        HostDelegate?.ColorFromPicker(NewColor: NewColor)
                    }
                }
            }
        }
    }
    
    private var _TappedPoint: CGPoint? = nil
    public var TappedPoint: CGPoint?
    {
        get
        {
            return _TappedPoint
        }
    }
    
    func GetColorAt(Location: CGPoint, InView: UIView) -> UIColor
    {
        _TappedPoint = Location
        let SatPercent = 1.0 - CGFloat(Location.x / InView.frame.size.width)
        let BriPercent = 1.0 - CGFloat(Location.y / InView.frame.size.height)
        let HuePercent = Hue
        return UIColor(hue: HuePercent, saturation: SatPercent, brightness: BriPercent, alpha: 1.0)
    }
    
    func GetHue(From: UIColor) -> CGFloat
    {
        var NotUsedSat: CGFloat = 0.0
        var NotUsedBri: CGFloat = 0.0
        var TheHue: CGFloat = 0.0
        var NotUsedAlpha: CGFloat = 0.0
        From.getHue(&TheHue, saturation: &NotUsedSat, brightness: &NotUsedBri, alpha: &NotUsedAlpha)
        return TheHue
    }
    
    func SelectColor(_ Color: UIColor, InView: UIView)
    {
        Hue = GetHue(From: Color)
        _TappedPoint = IndicateLocation(ForColor: Color, In: InView)
        HostView = InView
    }
    
    var HostView: UIView!
    
    func ColorAtPoint(In: UIView, At: CGPoint) -> UIColor?
    {
        _TappedPoint = At
        IndicateColorAt(Location: At, InView: In)
        let SatPercent = 1.0 - CGFloat(At.x / In.frame.size.width)
        let BriPercent = 1.0 - CGFloat(At.y / In.frame.size.height)
        let HuePercent = Hue
        let TheColor = UIColor(hue: HuePercent, saturation: SatPercent, brightness: BriPercent, alpha: 1.0)
        return TheColor
    }
    
    @discardableResult func IndicateLocation(ForColor: UIColor, In: UIView) -> CGPoint
    {
        var IHue: CGFloat = 0.0
        var ISat: CGFloat = 0.0
        var IBri: CGFloat = 0.0
        var NotUsed: CGFloat = 0.0
        ForColor.getHue(&IHue, saturation: &ISat, brightness: &IBri, alpha: &NotUsed)
        let X = In.frame.width * ISat
        let Y = In.frame.height * IBri
        let ColorPoint = CGPoint(x: X, y: Y)
        IndicateColorAt(Location: ColorPoint, InView: In)
        return ColorPoint
    }
    
    func IndicateColorAt(Location: CGPoint, InView: UIView)
    {
        let TheColor = GetColorAt(Location: Location, InView: InView)
        HostDelegate?.ColorFromPicker(NewColor: TheColor)
        if self.sublayers != nil
        {
            if (self.sublayers?.count)! > 0
            {
                self.sublayers!.forEach{$0.removeFromSuperlayer()}
            }
        }
        let Height = InView.frame.height
        let Width = InView.frame.width
        let LineLayer = CAShapeLayer()
        LineLayer.zPosition = 2000
        LineLayer.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7).cgColor
        LineLayer.lineWidth = 1
        LineLayer.frame = frame
        let Lines = UIBezierPath()
        Lines.move(to: CGPoint(x: Location.x, y: 0))
        Lines.addLine(to: CGPoint(x: Location.x, y: Location.y - 4))
        Lines.move(to: CGPoint(x: Location.x, y: Location.y + 4))
        Lines.addLine(to: CGPoint(x: Location.x, y: Height))
        Lines.move(to: CGPoint(x: 0, y: Location.y))
        Lines.addLine(to: CGPoint(x: Location.x - 4, y: Location.y))
        Lines.move(to: CGPoint(x: Location.x + 4, y: Location.y))
        Lines.addLine(to: CGPoint(x: Width, y: Location.y))
        LineLayer.path = Lines.cgPath
        let CircleLayer = CAShapeLayer()
        CircleLayer.zPosition = 2001
        CircleLayer.strokeColor = UIColor.white.cgColor
        CircleLayer.fillColor = UIColor.clear.cgColor
        CircleLayer.lineWidth = LineLayer.lineWidth
        CircleLayer.frame = frame
        let CRect = CGRect(x: Location.x - 4, y: Location.y - 4, width: 8, height: 8)
        let Circle = UIBezierPath(ovalIn: CRect)
        CircleLayer.path = Circle.cgPath
        self.addSublayer(LineLayer)
        self.addSublayer(CircleLayer)
    }
}
