//
// HPPhotoModel.swift
// Ouyu
//
// Created by raohongping on 2021/7/26.
// 
//

/*
 * @功能描述：照片Model
 * @创建时间：2021/7/26
 * @创建人：饶鸿平
 */

import UIKit
import Photos

extension HPPhotoModel {
    // 这个不需要注释
    public enum MediaType: Int {
        case unknown = 0
        case image
        case video
    }
}

public class HPPhotoModel: NSObject {
    
    /// 标识符
    public var identifier: String
    public let asset: PHAsset
    /// 媒体类型
    public var type: HPPhotoModel.MediaType = .unknown
    /// 视频时长
    public var duration = ""
    /// 是否选中
    public var isSelected = false
    /// 是否可选
    public var isCanSelected = true
    /// 缩略图
    public var thumbnailImage: UIImage?
    /// 压缩的图片
    public var compressImage: UIImage?
    /// 原图压缩后的Data
    public var compressOriginalImageData: Data?
    /// 相册占位类型
    public var cameraPlaceholderType = CameraPlaceholderType.none
    /** 照片在指定相册中的索引（同一张照片在不同相册中索引不同） */
    public var index: Int = 0
    /** 下载进度 */
    public var downLoadProgress: CGFloat = 100
    /// 编辑的图片
    public var editImage: UIImage?
    
    public init(asset: PHAsset) {
        self.identifier = asset.localIdentifier
        self.asset = asset
        super.init()
        self.type = self.transformAssetType(for: asset)
        if self.type == .video {
            self.duration = self.transformDuration(for: asset)
        }
    }
    
    public func transformAssetType(for asset: PHAsset) -> HPPhotoModel.MediaType {
        switch asset.mediaType {
        case .video:
            return .video
        case .image:
//            if (asset.value(forKey: "filename") as? String)?.hasSuffix("GIF") == true {
//                return .gif
//            }
//            if #available(iOS 9.1, *) {
//                if asset.mediaSubtypes == .photoLive || asset.mediaSubtypes.rawValue == 10 {
//                    return .livePhoto
//                }
//            }
            return .image
        default:
            return .unknown
        }
    }
    
    public func transformDuration(for asset: PHAsset) -> String {
        let dur = Int(round(asset.duration))
        
        switch dur {
        case 0..<60:
            return String(format: "00:%02d", dur)
        case 60..<3600:
            let minute = dur / 60
            let second = dur % 60
            return String(format: "%02d:%02d", minute, second)
        case 3600...:
            let hour = dur / 3600
            let minute = (dur % 3600) / 60
            let second = dur % 60
            return String(format: "%02d:%02d:%02d", hour, minute, second)
        default:
            return ""
        }
    }
}
