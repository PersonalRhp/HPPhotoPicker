//
// UICollectionViewCell+PhotoPicker.swift
// Ouyu
//
// Created by raohongping on 2021/8/1.
// 
//

import Foundation

extension UICollectionViewCell {
    class func identifier() -> String {
        return NSStringFromClass(self.classForCoder())
    }

    class func register(_ collectionView: UICollectionView) {
        collectionView.register(self.classForCoder(), forCellWithReuseIdentifier: self.identifier())
    }
}
