//
// AlbumListModel.swift
// Ouyu
//
// Created by raohongping on 2021/7/26.
// 
//

/*
 * @功能描述：专辑列表Model
 * @创建时间：2021/7/26
 * @创建人：饶鸿平
 */

import UIKit
import Photos

class AlbumListModel: NSObject {

    /// 相册标题
    let title: String
    
    /// 相册照片数量
    var count: Int {
        return result.count
    }
    
    /// 相册查询结果
    var result: PHFetchResult<PHAsset>
    /// 相册
    let collection: PHAssetCollection
    /// 相册设置
    let option: PHFetchOptions
    /// 是否是相机胶卷
    let isCameraRoll: Bool
    
    /// 最后的照片
    var headImageAsset: PHAsset? {
        return result.lastObject
    }
    
    // 相册照片数据和占位图
    var photoModels: [HPPhotoModel] = []
    
    init(title: String, result: PHFetchResult<PHAsset>, collection: PHAssetCollection, option: PHFetchOptions, isCameraRoll: Bool) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
        self.isCameraRoll = isCameraRoll
    }
}
