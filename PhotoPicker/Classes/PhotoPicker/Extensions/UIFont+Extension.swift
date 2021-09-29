//
// UIFont+Extension.swift 1
// StockKing
//
// Copyright © 2020 KrCell. All rights reserved.
//

import UIKit

extension UIFont {
    static func pingFangSCUltralight(size: CGFloat) -> UIFont {
        return font(name: "PingFang-SC-UltraLight", size: size, weight: .ultraLight)
    }
    
    static func pingFangSCLight(size: CGFloat) -> UIFont {
        return font(name: "PingFang-SC-Light", size: size, weight: .light)
    }
    
    static func pingFangSCRegular(size: CGFloat) -> UIFont {
        return font(name: "PingFang-SC-Regular", size: size, weight: .regular)
    }
    
    static func pingFangSCThin(size: CGFloat) -> UIFont {
        return font(name: "PingFang-SC-Thin", size: size, weight: .thin)
    }
    
    static func pingFangSCMedium(size: CGFloat) -> UIFont {
        return font(name: "PingFang-SC-Medium", size: size, weight: .medium)
    }
    
    static func pingFangSCSemibold(size: CGFloat) -> UIFont {
        return font(name: "PingFang-SC-Semibold", size: size, weight: .semibold)
    }
    
    private static func font(name: String, size: CGFloat, weight: Weight) -> UIFont {
        if let pingFangFont = UIFont(name: name, size: size) {
            return pingFangFont
        }
        return systemFont(ofSize: size, weight: weight)
    }
}
