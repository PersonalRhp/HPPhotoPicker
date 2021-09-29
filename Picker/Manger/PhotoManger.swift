//
// PhotoManger.swift
// Ouyu
//
// Created by raohongping on 2021/7/26.
// 
//

/*
 * @功能描述：相册管理类
 * @创建时间：2021/7/26
 * @创建人：饶鸿平
 */

import UIKit
import Photos

class PhotoManger: NSObject {
    
    /// 获取相册列表
    /// - Parameters:
    ///   - ascending: 时间正序
    ///   - mediaType: 选择的媒体类型
    ///   - completion: 完成回调
    class func getPhotoAlbumList(ascending: Bool, mediaType: MediaType, completion: ( ([AlbumListModel]) -> Void )) {
        let option = PHFetchOptions()
        
        if mediaType == .video {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        
        if mediaType == .image {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil) as? PHFetchResult<PHCollection>
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil) as? PHFetchResult<PHCollection>
        let streamAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil) as? PHFetchResult<PHCollection>
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil) as? PHFetchResult<PHCollection>
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil) as? PHFetchResult<PHCollection>
        let arr = [smartAlbums, albums, streamAlbums, syncedAlbums, sharedAlbums]
        
        var albumList: [AlbumListModel] = []
        arr.forEach { (album) in
            album?.enumerateObjects { (collection, _, _) in
                guard let collection = collection as? PHAssetCollection else { return }
                if collection.assetCollectionSubtype == .smartAlbumAllHidden {
                    return
                }
                if #available(iOS 11.0, *), collection.assetCollectionSubtype.rawValue > PHAssetCollectionSubtype.smartAlbumLongExposures.rawValue {
                    return
                }
                let result = PHAsset.fetchAssets(in: collection, options: option)
                
                // swiftlint:disable:next empty_count
                if result.count == 0 {
                    return
                }
                
                let title = self.getCollectionTitle(collection)
                
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    // Album of all photos.
                    let model = AlbumListModel(title: title, result: result, collection: collection, option: option, isCameraRoll: true)
                    albumList.insert(model, at: 0)
                } else {
                    let model = AlbumListModel(title: title, result: result, collection: collection, option: option, isCameraRoll: false)
                    albumList.append(model)
                }
            }
        }
        
        completion(albumList)
    }

    /// 获取"最近项目" (smartAlbumUserLibrary) 的相册数据
    /// - Parameters:
    /// - mediaType: 选择的媒体类型
    /// - completion: 相册Model完成回调
    class func getCameraRollAlbum(mediaType: MediaType, completion: @escaping ( (AlbumListModel) -> Void )) {
        let option = PHFetchOptions()
        
        if mediaType == .video {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        
        if mediaType == .image {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        smartAlbums.enumerateObjects { (collection, _, stop) in
            if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                let result = PHAsset.fetchAssets(in: collection, options: option)
                let albumModel = AlbumListModel(title: self.getCollectionTitle(collection), result: result, collection: collection, option: option, isCameraRoll: true)
                completion(albumModel)
                stop.pointee = true
            }
        }
    }
    
    /// 从结果中获取照片
    class func fetchPhoto(in result: PHFetchResult<PHAsset>, ascending: Bool, mediaType: MediaType, limitCount: Int = .max) -> [HPPhotoModel] {
        var models: [HPPhotoModel] = []
        let option: NSEnumerationOptions = ascending ? .init(rawValue: 0) : .reverse
        var count = 1
        
        result.enumerateObjects(options: option) { (asset, _, stop) in
            let photoModel = HPPhotoModel(asset: asset)
            
            if photoModel.type == .image, mediaType == .video {
                return
            }
            
            if photoModel.type == .video, mediaType == .image {
                return
            }
            
            if count == limitCount {
                stop.pointee = true
            }
            
            models.append(photoModel)
            count += 1
        }
        
        return models
    }
    
    /// 快速请求缩略图
    @discardableResult
    class func fastFetchThumbnailImage(for asset: PHAsset, size: CGSize, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (UIImage?, Bool) -> Void )) -> PHImageRequestID {
        return self.fetchImage(for: asset, size: size, resizeMode: .fast, deliveryMode: .opportunistic, progress: progress, completion: completion)
    }
    
    /// 快速请求高清图片
    @discardableResult
    class func fastFetchImage(for asset: PHAsset, size: CGSize, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (UIImage?, Bool) -> Void )) -> PHImageRequestID {
        return self.fetchImage(for: asset, size: size, resizeMode: .fast, deliveryMode: .highQualityFormat, progress: progress, completion: completion)
    }
    
    /// 请求高清原图
    @discardableResult
    class func fetchHighQualityOriginImage(for asset: PHAsset, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        
        let option = PHImageRequestOptions()
        option.deliveryMode = .highQualityFormat
        option.isNetworkAccessAllowed = true
        
        return PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: option, resultHandler: resultHandler)
    }
    
    /// 快速请求视频
    class func fetchVideo(for asset: PHAsset, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (AVPlayerItem?, [AnyHashable: Any]?, Bool) -> Void )) -> PHImageRequestID {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { (pro, error, stop, info) in
            DispatchQueue.main.async {
                progress?(CGFloat(pro), error, stop, info)
            }
        }

        if asset.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: option, exportPreset: AVAssetExportPresetHighestQuality, resultHandler: { (session, info) in
                // iOS11 and earlier, callback is not on the main thread.
                DispatchQueue.main.async {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    if let avAsset = session?.asset {
                        let item = AVPlayerItem(asset: avAsset)
                        completion(item, info, isDegraded)
                    }
                }
            })
        } else {
            return PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { (item, info) in
                // iOS11 and earlier, callback is not on the main thread.
                DispatchQueue.main.async {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    completion(item, info, isDegraded)
                }
            }
        }
    }
    
    /// 保存图片到相册
    class func saveImageToAlbum(image: UIImage, completion: ( (Bool, PHAsset?) -> Void )? ) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
    
        PHPhotoLibrary.shared().performChanges {
            let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            placeholderAsset = newAssetRequest.placeholderForCreatedAsset
        } completionHandler: { success, _ in
            DispatchQueue.main.async {
                if success {
                    let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                    completion?(success, asset)
                } else {
                    completion?(false, nil)
                }
            }
        }
    }
    
    /// 保存视频到相册
    class func saveVideoToAlbum(url: URL, completion: ( (Bool, PHAsset?) -> Void )? ) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared().performChanges {
            let newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            placeholderAsset = newAssetRequest?.placeholderForCreatedAsset
        } completionHandler: { success, _ in
            DispatchQueue.main.async {
                if success {
                    let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                    completion?(success, asset)
                } else {
                    completion?(false, nil)
                }
            }
        }

    }
    
    class func isFetchImageError(_ error: Error?) -> Bool {
        guard let error = error as NSError? else {
            return false
        }
        if error.domain == "CKErrorDomain" || error.domain == "CloudPhotoLibraryErrorDomain" {
            return true
        }
        return false
    }
    
    // MARK: Private
    /// 相册标题
    private class func getCollectionTitle(_ collection: PHAssetCollection) -> String {
        return collection.localizedTitle ?? ""
    }
    
    // 获取图片
    private class func fetchImage(for asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, deliveryMode: PHImageRequestOptionsDeliveryMode, progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void )? = nil, completion: @escaping ( (UIImage?, Bool) -> Void )) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.resizeMode = resizeMode
        option.isNetworkAccessAllowed = true
        option.deliveryMode = deliveryMode
        option.progressHandler = { (pro, error, stop, info) in
            DispatchQueue.main.async {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        return PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: option) { (image, info) in
            var downloadFinished = false
            if let info = info {
                downloadFinished = !(info[PHImageCancelledKey] as? Bool ?? false) && (info[PHImageErrorKey] == nil)
            }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if downloadFinished {
                completion(image, isDegraded)
            }
        }
    }
    
    // 本地标识符找到PHAsset
    private class func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let id = localIdentifier else {
            return nil
        }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        // swiftlint:disable:next empty_count
        if result.count > 0 {
            return result[0]
        }
        return nil
    }
}
