//
//  Numeric.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

extension Double
{
    func Round(To: Int) -> Double
    {
        let Div = pow(10.0, Double(To))
        return (self * Div).rounded() / Div
    }
    
    func Clamp(_ From: Double, _ To: Double) -> Double
    {
        if self < From
        {
            return From
        }
        if self > To
        {
            return To
        }
        return self
    }
    
    func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: self)
    }
    
    static func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: Double(0.0))
    }
}

extension Float
{
    func Round(To: Int) -> Float
    {
        let Div = pow(10.0, Float(To))
        return (self * Div).rounded() / Div
    }
    
    func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: self)
    }
    
    static func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: Float(0.0))
    }
}

extension CGFloat
{
    func Round(To: Int) -> CGFloat
    {
        let Div = pow(10.0, CGFloat(To))
        return (self * Div).rounded() / Div
    }
    
    func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: self)
    }
    
    static func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: CGFloat(0.0))
    }
}

extension Int
{
    func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: self)
    }
    
    static func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: Int(0))
    }
}

extension UInt8
{
    func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: self)
    }
    
    static func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: UInt8(0))
    }
}

extension UInt
{
    func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: self)
    }
    
    static func SizeOf() -> Int
    {
        return MemoryLayout.size(ofValue: UInt(0))
    }
}
