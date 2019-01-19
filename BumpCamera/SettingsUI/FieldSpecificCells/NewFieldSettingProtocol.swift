//
//  NewFieldSettingProtocol.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

protocol NewFieldSettingProtocol: class
{
    func NewFieldSetting(InputField: RenderPacket.InputFields, NewValue: Any?)
}
