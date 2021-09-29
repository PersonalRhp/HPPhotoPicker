//
// GeneralDefine.swift
// Ouyu
//
// Created by raohongping on 2021/7/26.
//
//

/*
 * @功能描述：共用常量配置
 * @创建时间：2021/7/26
 * @创建人：饶鸿平
 */

import UIKit

let photoPickerStatusBarHeight: CGFloat = {
    if #available(iOS 13.0, *) {
        // swiftlint:disable:next force_cast
        return UIApplication.shared.delegate?.window??.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    } else {
        return UIApplication.shared.statusBarFrame.height
    }
}()

let photoPickerNaviBarHeight = photoPickerStatusBarHeight + 44
let photoPickerScreenWidth = UIScreen.main.bounds.size.width
let photoPickerScreenHeight = UIScreen.main.bounds.size.height
let photoPickerTabBarHeight: CGFloat = photoPickerBottomSafeHeight + 56
let photoPickerBottomSafeHeight: CGFloat = (photoPickerStatusBarHeight > 20.0 ? 34 : 0)

let bottomToolViewH: CGFloat = 55
let bottomToolBtnH: CGFloat = 34
let bottomToolBtnY: CGFloat = 10
let bottomToolBtnCornerRadius: CGFloat = 5
let thumbCollectionViewItemSpacing: CGFloat = 2
let thumbCollectionViewLineSpacing: CGFloat = 2

func deviceSafeAreaInsets() -> UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    
    if #available(iOS 11, *) {
        insets = UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }
    
    return insets
}




