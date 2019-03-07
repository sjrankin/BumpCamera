//
//  GradientTestCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class GradientTestCode: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews()
    {
        let GLayer = MakeGradient(WithFrame: TestView.bounds)
        GLayer.zPosition = 1000
        TestView.layer.addSublayer(GLayer)
    }
    
    func MakeGradient(WithFrame: CGRect) -> CAGradientLayer
    {
        let Layer = CAGradientLayer()
        Layer.frame = WithFrame
        Layer.startPoint = CGPoint(x: 0.0, y: 0.0)
        Layer.endPoint = CGPoint(x: 0.0, y: 1.0)
        let C1 = UIColor(hue: 0.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C2 = UIColor(hue: 0.1, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C3 = UIColor(hue: 0.2, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C4 = UIColor(hue: 0.3, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C5 = UIColor(hue: 0.4, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C6 = UIColor(hue: 0.5, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C7 = UIColor(hue: 0.6, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C8 = UIColor(hue: 0.7, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C9 = UIColor(hue: 0.8, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C10 = UIColor(hue: 0.9, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let C11 = UIColor(hue: 1.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let Stops: [Any] = [C1.cgColor as Any, C2.cgColor as Any, C3.cgColor as Any,
                            C4.cgColor as Any, C5.cgColor as Any, C6.cgColor as Any,
                            C7.cgColor as Any, C8.cgColor as Any, C9.cgColor as Any,
                            C10.cgColor as Any, C11.cgColor as Any]
        Layer.colors = Stops
        Layer.locations = [NSNumber(value: 0.0), NSNumber(value: 0.1), NSNumber(value: 0.2),
                           NSNumber(value: 0.3), NSNumber(value: 0.4), NSNumber(value: 0.5),
                           NSNumber(value: 0.6), NSNumber(value: 0.7), NSNumber(value: 0.8),
                           NSNumber(value: 0.9), NSNumber(value: 1.0)]
        return Layer
    }
    
    @IBOutlet weak var TestView: UIView!
}
