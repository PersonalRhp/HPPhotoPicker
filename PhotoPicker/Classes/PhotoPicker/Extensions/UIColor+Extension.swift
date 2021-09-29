//
// UIColor+Extension.swift
// StockKing
//
// Created by zhouxiaohong on 2021/3/8.
// Copyright © 2021 KrCell. All rights reserved.
//

import UIKit
import SwifterSwift

extension UIColor {
    static func hexColor(_ colorString: String) -> UIColor {
        return UIColor(hexString: colorString) ?? .black
    }
    
    static func hexColor(_ colorString: String, alpha: CGFloat) -> UIColor {
        return UIColor(hexString: colorString, transparency: alpha) ?? .black
    }
}
