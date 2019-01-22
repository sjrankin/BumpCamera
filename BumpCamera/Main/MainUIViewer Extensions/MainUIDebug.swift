//
//  MainUIDebug.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Code for MainUIViewer related to debugging and debug views.
extension MainUIViewer
{
    func AddGridOverlayLayer()
    {
        SetGridVisibility(IsVisible: true)
    }
    
    func SetGridVisibility(IsVisible: Bool)
    {
        if IsVisible
        {
            if GridLayerIsShowing
            {
                return
            }
            GridLayerIsShowing = true
            GridLayer = MakeGrid()
            LiveView.layer.addSublayer(GridLayer!)
        }
        else
        {
            if !GridLayerIsShowing
            {
                return
            }
            GridLayerIsShowing = false
            LiveView.layer.sublayers!.forEach{if $0.name == "Grid Layer"
            {
                $0.removeFromSuperlayer()
                }
            }
        }
    }
    
    func MakeGrid() -> CAShapeLayer
    {
        #if true
        return CAShapeLayer()
        #else
        let Layer = CAShapeLayer()
        Layer.name = "Grid Layer"
        Layer.zPosition = 2000
        Layer.backgroundColor = UIColor.clear.cgColor
        Layer.frame = MainOutputRect
        let FinalSize = Layer.frame.size
        Layer.lineWidth = 1.0
        Layer.strokeColor = UIColor.yellow.cgColor
        let Lines = UIBezierPath()
        Lines.move(to: CGPoint(x: FinalSize.width / 2.0, y: 0))
        Lines.addLine(to: CGPoint(x: FinalSize.width / 2.0, y: FinalSize.height))
        Lines.move(to: CGPoint(x: 0, y: FinalSize.height / 2.0))
        Lines.addLine(to: CGPoint(x: FinalSize.width, y: FinalSize.height / 2.0))
        Layer.path = Lines.cgPath
        return Layer
        #endif
    }
}
