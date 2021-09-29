//
// CollectionView+PhotoPicker.swift
// Ouyu
//
// Created by raohongping on 2021/7/30.
// 
//

import Foundation

extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}
