//
// File.swift
// Ouyu
//
// Created by raohongping on 2021/7/27.
// 
//

import Foundation

extension NSObject {
    /// 类名
    public static var className: String {
        return String(describing: self)
    }
}
