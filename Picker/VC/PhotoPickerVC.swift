//
// PhotoPickerVC.swift
// Ouyu
//
// Created by raohongping on 2021/7/27.
// 
//

/**
 * @功能描述：相册VC
 * @创建时间：2021/7/27
 * @创建人：饶鸿平
 */

import UIKit
import Photos
import RSKImageCropper
import SnapKit

protocol PhotoPickerVCDelegate: NSObjectProtocol {
    // 选中照片完成
    func photoPickerDidFinish(selectPhotos: [HPPhotoModel])
    
    // 取消
    func photoPickerCancel()
}

class PhotoPickerVC: UIViewController {
    /// 照片列表的item间距
    static let itemSpacing: CGFloat = 1
    /// 照片列表的行间距
    static let lineSpacing: CGFloat = 1
    
    // 相册Model
    var albumModel: AlbumListModel?
    
    // MARK: Private Property
    private var config = PhotoConfiguration()
    private weak var delegate: PhotoPickerVCDelegate?
    
    // 相册照片数据
    private var selectPhotoModels: [HPPhotoModel] = []
    private var previewPhotoModel: HPPhotoModel?
    
    /// 刷新相册列表
    private var reloadAlbumList = true
    /// 是否执行了ReloadData
    private var isReloadData = false
    private let imageManager = PHCachingImageManager()
    private var thumbnailSize: CGSize!
    private var previousPreheatRect = CGRect.zero
    private var lastCameraPlaceholderType: CameraPlaceholderType?
    
    init(config: PhotoConfiguration, delegate: PhotoPickerVCDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.config = config
        
        if let selectPhotos = config.selectPhotos {
            self.selectPhotoModels = selectPhotos
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("照片选择器释放")
    }

    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCameraRollAlbum()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    // MARK: Lazy
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumLineSpacing = PhotoPickerVC.lineSpacing
        layout.minimumInteritemSpacing = PhotoPickerVC.itemSpacing
        let cellW = (self.view.frame.width - CGFloat(self.config.numberOfItemsInRow) - PhotoPickerVC.lineSpacing) / CGFloat(self.config.numberOfItemsInRow)
        let itemSize = CGSize(width: cellW, height: cellW)
        layout.itemSize = itemSize
        let scale = UIScreen.main.scale
        thumbnailSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)
        let collectionView = UICollectionView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoPickerCell.classForCoder(), forCellWithReuseIdentifier: PhotoPickerCell.className)
        collectionView.register(PhotoPickerCameraCell.classForCoder(), forCellWithReuseIdentifier: PhotoPickerCameraCell.className)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: photoPickerTabBarHeight, right: 0)
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = self.config.customUI.pickerViewBgColor
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .always
        }
        
        return collectionView
    }()
    
    lazy var bottomView: PhotoPickerBottomView = {
        let view = PhotoPickerBottomView.init(frame: .zero, customConfig: self.config.customUI)
        view.delegate = self
        return view
    }()
    
    lazy var navigationView: PhotoPickerNavitionView = {
        let view = PhotoPickerNavitionView(title: self.albumModel?.title ?? "", config: self.config)
        view.delegate = self
        return view
    }()
    
    lazy var listView: AlbumListView = {
        let popViewFrame = CGRect.init(x: 0, y: photoPickerNaviBarHeight, width: photoPickerScreenWidth, height: photoPickerScreenHeight - photoPickerNaviBarHeight - bottomView.height)
        let view = AlbumListView.init(selectedAlbum: self.albumModel, customConfig: self.config.customUI)
        view.isHidden = true
        return view
    }()
}

// MARK: UI
extension PhotoPickerVC {
    func setupUI() {
        view.backgroundColor = self.config.customUI.pickerViewBgColor
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: photoPickerNaviBarHeight, left: 0, bottom: 0, right: 0))
        }
        
        setupAlbumListView()
    }
    
    func setupNavView() {
        self.navigationController?.navigationBar.isHidden = true
        view.addSubview(navigationView)
        
        navigationView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view)
            make.height.equalTo(photoPickerNaviBarHeight)
        }
        
    }
    
    func setupBottomView() {
        // 只能单选图片或者单选视频，不展示bottomView
        if !self.config.allowMixSelect {
            if self.config.mediaType == .imageAndVideo {
                if self.config.image.singlePicture && self.config.video.singleVideo {
                    return
                }
            } else if self.config.mediaType == .image && self.config.image.singlePicture {
                return
            } else if self.config.mediaType == .video && self.config.video.singleVideo {
                return
            }
        }
        
        view.addSubview(bottomView)
        
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view)
            make.height.equalTo(photoPickerTabBarHeight)
        }
    }
    
    func setupAlbumListView() {
        view.addSubview(listView)
        
        listView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: photoPickerNaviBarHeight, left: 0, bottom: 0, right: 0))
        }
        
        listView.config = self.config
        listView.loadAlbumList()
        
        listView.selectAlbumBlock = { [weak self] (album) in
            self?.navigationView.reset()
            
            guard self?.albumModel != album else {
                return
            }
            
            self?.albumModel = album
            
            // 只有为"最近项目"才展示相机占位
            if album.collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                if let type = self?.lastCameraPlaceholderType {
                    self?.config.cameraPlaceholderType = type
                }
            } else {
                
                if self?.lastCameraPlaceholderType == nil {
                    self?.lastCameraPlaceholderType = self?.config.cameraPlaceholderType
                }
                
                self?.config.cameraPlaceholderType = .none
            }
            
            self?.navigationView.title = album.title
            self?.loadAlbumPhoto()
        }
        
        listView.hideBlock = { [weak self] in
            self?.navigationView.reset()
        }
    }
}

// MARK: 数据源
extension PhotoPickerVC {
    // 加载获取"最近项目"的相册照片
    func loadCameraRollAlbum() {
        PhotoManger.getCameraRollAlbum(mediaType: config.mediaType) { albumModel in
            self.albumModel = albumModel
            self.setupNavView()
            self.setupBottomView()
            self.loadAlbumPhoto()
        }
    }
    
    // 加载相册照片
    func loadAlbumPhoto() {
        
        guard let result = self.albumModel?.result else {
            return
        }
        
        DispatchQueue.global().async {
            self.albumModel?.photoModels = PhotoManger.fetchPhoto(in: result, ascending: self.config.ascending, mediaType: self.config.mediaType)
            
            if self.config.cameraPlaceholderType != .none {
                let photoModel = HPPhotoModel(asset: PHAsset())
                photoModel.cameraPlaceholderType = self.config.cameraPlaceholderType
                
                if self.config.ascending {
                    self.albumModel?.photoModels.append(photoModel)
                } else {
                    self.albumModel?.photoModels.insert(photoModel, at: 0)
                }
            }
            
            // 记录已选择的图片
            if let photoModels = self.albumModel?.photoModels {
                for selectModel in self.selectPhotoModels {
                    for photoModel in photoModels {
                        if photoModel.identifier == selectModel.identifier {
                            photoModel.isSelected = true
                            photoModel.editImage = selectModel.editImage
                        }
                    }
                }
            }
            
            // 选中最大数量进入都不可选
            if self.config.image.maxNumberOfItems == 0 || self.config.video.maxNumberOfItems == 0 {
                self.updatePhotosCanSelectedStatus(false)
            }
            
            DispatchQueue.main.async {
                self.reloadListSelectStatus()
            }
        }
    }
}

// MARK: Private Method
extension PhotoPickerVC {
    /// 拍照或录制更新相册列表
    func updateAlbumPhoto(newModel: HPPhotoModel) {
        self.reloadAlbumList = true
        
        guard let photoModels = self.albumModel?.photoModels else {
            return
        }
        
        if config.ascending {
            self.albumModel?.photoModels.insert(newModel, at: photoModels.count - 1)
        } else {
            self.albumModel?.photoModels.insert(newModel, at: 1)
        }
        
        self.collectionView.reloadData()
    }
    
    /// 保存照片
    func save(image: UIImage?, videoUrl: URL?) {
        if let image = image {
            PhotoManger.saveImageToAlbum(image: image) { [weak self] (success, asset) in
                if success, let newAsset = asset {
                    let model = HPPhotoModel(asset: newAsset)
                    self?.updateAlbumPhoto(newModel: model)
                } else {
//                    AlertViewController(content: "保存图片失败")
//                        .show()
//                        .completion { _ in
//
//                        }
                    
                    let alertController = UIAlertController(title: nil, message: "保存图片失败", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                    let okAction = UIAlertAction(title: "确定", style: .default, handler: {
                        action in
                       
                    })
                    alertController.addAction(cancelAction)
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                }
            }
        } else if let videoUrl = videoUrl {
            PhotoManger.saveVideoToAlbum(url: videoUrl) { [weak self] (success, asset) in
                if success, let newAsset = asset {
                    let model = HPPhotoModel(asset: newAsset)
                    self?.updateAlbumPhoto(newModel: model)
                } else {
//                    AlertViewController(content: "保存视频失败")
//                        .show()
//                        .completion { _ in
//
//                        }
                    let alertController = UIAlertController(title: nil, message: "保存视频失败", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                    let okAction = UIAlertAction(title: "确定", style: .default, handler: {
                        action in
                       
                    })
                    alertController.addAction(cancelAction)
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    /// 打开相机
    func showCamera() {
        
        PhotoPickerManger.authorizeCamera { status in
            if status == .authorized {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.allowsEditing = false
                    picker.videoQuality = .typeHigh
                    picker.sourceType = .camera
                    var mediaTypes = [String]()
                    if self.config.mediaType == .image || self.config.mediaType == .imageAndVideo {
                        mediaTypes.append("public.image")
                    }
                    if self.config.mediaType == .video || self.config.mediaType == .imageAndVideo {
                        mediaTypes.append("public.movie")
                    }
                    picker.mediaTypes = mediaTypes
                    picker.videoMaximumDuration = TimeInterval(self.config.video.maximumTimeLimit)
                    self.showDetailViewController(picker, sender: nil)
                } else {
//                    AlertViewController(content: "相机不可用")
//                        .show()
//                        .completion { _ in
//
//                        }
                    
                    let alertController = UIAlertController(title: nil, message: "相机不可用", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                    let okAction = UIAlertAction(title: "确定", style: .default, handler: {
                        action in
                       
                    })
                    alertController.addAction(cancelAction)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    /// 刷新照片选中状态
    func refreshPhotoSelectStatus(photoModel: HPPhotoModel) {
        if self.config.allowMixSelect {
            print("同时选择照片和视频的功能，目前还不支持，敬请期待...")
            return
        }
        
        // 不满足可选的视频时长，直接return
        if !self.checkVideoDutationCanSelect(photoModel: photoModel) {
            return
        }
        
        photoModel.isSelected = !photoModel.isSelected
        
        // 更新选中的照片
        if photoModel.isSelected {
            self.selectPhotoModels.append(photoModel)
        } else {
            self.selectPhotoModels.removeAll { model in
                model.identifier == photoModel.identifier
            }
        }
        
        // 刷新列表选中状态
        reloadListSelectStatus()
    }
    
    /// 选择照片完成
    func selectedPhotosFinishDisMiss() {
        let size = CGSize(width: photoPickerScreenWidth * UIScreen.main.scale, height: photoPickerScreenHeight * UIScreen.main.scale)
        
        let group = DispatchGroup()
        let dispatchQueue = DispatchQueue.global()
        
        for photoModel in self.selectPhotoModels {
            
            if let editImage = photoModel.editImage {
                photoModel.compressOriginalImageData = editImage.compression()
                continue
            }
            
            dispatchQueue.async(group: group, execute: {
                group.enter()
                PhotoManger.fastFetchImage(for: photoModel.asset, size: size, completion: { image, isDegraded in
                    photoModel.compressImage = image
                    photoModel.compressOriginalImageData = image?.compression()
                    group.leave()
                })
            })
        }
        
        // 请求完刷新列表
        group.notify(queue: dispatchQueue) {
            DispatchQueue.main.async {
                self.delegate?.photoPickerDidFinish(selectPhotos: self.selectPhotoModels)
            }
        }
    }
}

// MARK: UICollectionViewDelegate && UICollectionViewDelegateFlowLayout
extension PhotoPickerVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albumModel?.photoModels.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let albumModel = self.albumModel?.photoModels[indexPath.row]
        
        if albumModel?.cameraPlaceholderType == CameraPlaceholderType.none {
            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: PhotoPickerCell.className, for: indexPath) as? PhotoPickerCell)!
            cell.config = self.config
            cell.photoModel = self.albumModel?.photoModels[indexPath.row]
            cell.delegate = self
            return cell
        } else {
            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: PhotoPickerCameraCell.className, for: indexPath) as? PhotoPickerCameraCell)!
            cell.isCapture = albumModel?.cameraPlaceholderType == .realTimePreview
            cell.isCanTakePhoto = albumModel?.isCanSelected ?? true
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // cell离开屏幕，将thumbnailImage从内存中清掉，因为reloadData也会调用didEndDisplaying，所以直接return
        if self.isReloadData {
            return
        }
        
        let albumModel = self.albumModel?.photoModels[indexPath.row]
        albumModel?.thumbnailImage = nil
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photoModel = self.albumModel?.photoModels[indexPath.row] else {
            return
        }
        
        guard photoModel.isCanSelected else {
            return
        }
        
        if photoModel.cameraPlaceholderType == .none { // 为照片
    
            guard var photoModels = self.albumModel?.photoModels else {
                return
            }
            
            var selectPhotoRow = indexPath.row
            if self.config.cameraPlaceholderType != .none { // 预览照片移除相机占位
                if self.config.ascending == true {
                    photoModels.removeLast()
                } else {
                    photoModels.removeFirst()
                    selectPhotoRow = indexPath.row - 1
                }
            }
            
            self.previewPhotoModel = photoModel
            
            if photoModel.type == .image {
                selectImageAssetItem(photoModel: photoModel, photoModels: photoModels, selectPhotoRow: selectPhotoRow)
                
            } else {
                selectVideoAssetItem(photoModel: photoModel, photoModels: photoModels, selectPhotoRow: selectPhotoRow)
            }
            
        } else {
            showCamera()
        }
    }
    
    /// 点击选中图片
    func selectImageAssetItem(photoModel: HPPhotoModel, photoModels: [HPPhotoModel], selectPhotoRow: Int) {
        if config.image.singlePicture { // 图片单选进入编辑页面
            var imageCropMode: RSKImageCropMode!
            
            if self.config.image.cropMode == .circle {
                imageCropMode = .circle
            } else if self.config.image.cropMode == .square {
                imageCropMode = .square
            } else {
                imageCropMode = .custom
            }
            
            if  let editImage = photoModel.editImage {
                let clipVC = RSKImageCropViewController.init(image: editImage, cropMode: imageCropMode)
                clipVC.modalPresentationStyle = .fullScreen
                clipVC.delegate = self
                clipVC.dataSource = self.config.image.customCropDataSource
                clipVC.avoidEmptySpaceAroundImage = true
                self.present(clipVC, animated: true, completion: nil)
            } else {
                PhotoManger.fetchHighQualityOriginImage(for: photoModel.asset) { image, _ in
                    DispatchQueue.main.async {
                        guard let clipImage = image else {
                            let alertController = UIAlertController(title: "下载图片失败",
                                                                    message: nil, preferredStyle: .alert)
                            // 显示提示框
                            self.present(alertController, animated: true, completion: nil)
                            // 两秒钟后自动消失
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                                self.presentedViewController?.dismiss(animated: false, completion: nil)
                            }
                            return
                        }
                        
                        let clipVC = RSKImageCropViewController.init(image: clipImage, cropMode: imageCropMode)
                        clipVC.modalPresentationStyle = .fullScreen
                        clipVC.delegate = self
                        clipVC.dataSource = self.config.image.customCropDataSource
                        clipVC.avoidEmptySpaceAroundImage = true
                        self.present(clipVC, animated: true, completion: nil)
                    }
                }
            }
        } else { // 多选进入预览页面
            let vc = PhotoPreviewController(photos: photoModels, arrSelectedModels: self.selectPhotoModels, index: selectPhotoRow)
            vc.config = self.config
            vc.modalPresentationStyle = .fullScreen
            
            vc.selectPhotoBlock = { [unowned self] selectPhotoModels in
                self.selectPhotoModels = selectPhotoModels
                self.selectedPhotosFinishDisMiss()
            }
            
            vc.backBlock = { [unowned self] selectPhotoModels in
                self.selectPhotoModels = selectPhotoModels
                // 刷新列表选中状态
                reloadListSelectStatus()
            }
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    /// 点击选中视频
    func selectVideoAssetItem(photoModel: HPPhotoModel, photoModels: [HPPhotoModel], selectPhotoRow: Int) {
        // 不满足可选的视频时长，直接return
        if !self.checkVideoDutationCanSelect(photoModel: photoModel) {
            return
        }
        
        var vc: PhotoPreviewController
        
        if config.video.singleVideo { // 视频单选
            vc = PhotoPreviewController(photos: photoModels, arrSelectedModels: [photoModel], index: selectPhotoRow, showBottomViewAndSelectBtn: config.showSelectedPhotoPreview)
        } else { // 视频多选
            vc = PhotoPreviewController(photos: photoModels, arrSelectedModels: self.selectPhotoModels, index: selectPhotoRow, showBottomViewAndSelectBtn: config.showSelectedPhotoPreview)
        }
        
        vc.config = self.config
        vc.modalPresentationStyle = .fullScreen
        
        vc.selectPhotoBlock = { [unowned self] selectPhotoModels in
            self.selectPhotoModels = selectPhotoModels
            self.selectedPhotosFinishDisMiss()
        }
        
        vc.backBlock = { [unowned self] selectPhotoModels in
            self.selectPhotoModels = selectPhotoModels
            // 刷新列表选中状态
            reloadListSelectStatus()
        }
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: 照片选择器cell代理方法
extension PhotoPickerVC: PhotoPickerCellDelegate {
    // 更新选中的照片
    func photoPickerCellUpdatePhoto(cell: PhotoPickerCell) {
        refreshPhotoSelectStatus(photoModel: cell.photoModel)
    }

    /// 检查视频时长是否可选
    /// - Parameter photoModel: 照片模型
    /// - Returns: 是否可选
    func checkVideoDutationCanSelect(photoModel: HPPhotoModel) -> Bool {
        if photoModel.asset.mediaType == .video {
            if photoModel.asset.duration > self.config.video.maximumTimeLimit {
                showAlert(title: "不能选择超过\(Int(self.config.video.maximumTimeLimit))秒的视频", message: "")
                return false
            } else if photoModel.asset.duration < self.config.video.minimumTimeLimit {
                showAlert(title: "不能选择小于\(Int(self.config.video.minimumTimeLimit))秒的视频", message: "")
                return false
            }
        }
        return true
    }
    
    /// 刷新列表选中状态
    func reloadListSelectStatus() {
        
        bottomView.finishCount = self.selectPhotoModels.count
        
        // 没有选中更新为都可选
        if self.selectPhotoModels.isEmpty {
            updatePhotosCanSelectedStatus(true)
            self.isReloadData = true
            collectionView.reloadData()
            self.isReloadData = false
            return
        }

        if self.selectPhotoModels[0].asset.mediaType == .image {
            // 图片数量选中为最大数量列表都不可选
            if self.selectPhotoModels.count == self.config.image.maxNumberOfItems {
                updatePhotosCanSelectedStatus(false)
            } else {
                // 选中视频后, 图片都不可选, 视频可选
                updateCanSelectedStatus(imageCanSelected: true, videoCanSelected: false)
            }
        }
        
        if self.selectPhotoModels[0].asset.mediaType == .video {
            // 视频选中数量为最大数量需要将列表的照片都设置为不可选
            if self.selectPhotoModels.count == self.config.video.maxNumberOfItems {
                updatePhotosCanSelectedStatus(false)
            } else {
                // 选中视频后, 图片都不可选, 视频可选
                updateCanSelectedStatus(imageCanSelected: false, videoCanSelected: true)
            }
        }
        
        self.isReloadData = true
        collectionView.reloadData()
        self.isReloadData = false
    }
    
    // 更新照片列表是否可以选中
    func updatePhotosCanSelectedStatus(_ isCanSelected: Bool) {
        
        guard let photoModels = self.albumModel?.photoModels else {
            return
        }
        
        // 更新没有选中的照片的可选状态
        for photoModel in photoModels where !photoModel.isSelected {
            photoModel.isCanSelected = isCanSelected
        }
    }
    
    // 更新图片是否可以选中
    func updateCanSelectedStatus(imageCanSelected: Bool, videoCanSelected: Bool) {
        guard let photoModels = self.albumModel?.photoModels else {
            return
        }
        
        for photoModel in photoModels {
            if photoModel.asset.mediaType == .image {
                photoModel.isCanSelected = imageCanSelected
            } else if photoModel.asset.mediaType == .video {
                photoModel.isCanSelected = videoCanSelected
            } else {
                guard self.selectPhotoModels.count > 0 else { return }
                
                if self.selectPhotoModels.first?.type == .video {
                    photoModel.isCanSelected = self.selectPhotoModels.count < self.config.video.maxNumberOfItems
                } else {
                    photoModel.isCanSelected = self.selectPhotoModels.count < self.config.image.maxNumberOfItems
                }
            }
        }
    }
}

// MARK: 照片选择器导航栏代理实现
extension PhotoPickerVC: PhotoPickerNavitionViewDelegate {
    // 选择相册
    func photoPickerNavitionViewSelectAlbum(view: PhotoPickerNavitionView) {
        if self.listView.isHidden == true {
            self.listView.show(reloadAlbumList: self.reloadAlbumList)
            self.reloadAlbumList = false
        } else {
            self.listView.hide()
        }
    }
    
    // 取消
    func photoPickerNavitionViewCancel(view: PhotoPickerNavitionView) {
        if self.config.animateStyle == .push {
            self.navigationController?.popViewController()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
        self.delegate?.photoPickerCancel()
    }
}

// MARK: 照片选择器底部视图代理实现
extension PhotoPickerVC: PhotoPickerBottomViewDelegate {
    // 预览
    func photoPickerBottomViewPreview(view: PhotoPickerBottomView) {
        if self.selectPhotoModels.isEmpty {
            return
        }
        
        let vc = PhotoPreviewController(photos: self.selectPhotoModels, arrSelectedModels: self.selectPhotoModels, index: 0)
        
        vc.selectPhotoBlock = { [unowned self] selectPhotoModels in
            self.selectPhotoModels = selectPhotoModels
            self.selectedPhotosFinishDisMiss()
        }
        
        vc.backBlock = { [unowned self] selectPhotoModels in
            self.selectPhotoModels = selectPhotoModels
            // 刷新列表选中状态
            reloadListSelectStatus()
        }
        
        vc.config = self.config
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // 完成
    func photoPickerBottomViewFinish(view: PhotoPickerBottomView) {
        self.selectedPhotosFinishDisMiss()
        
        if self.config.animateStyle == .push {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: 拍照或录视频代理实现
extension PhotoPickerVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            let image = info[.originalImage] as? UIImage
            let url = info[.mediaURL] as? URL
            self.save(image: image, videoUrl: url)
        }
    }
}

// MARK: 图片裁剪回调
extension PhotoPickerVC: RSKImageCropViewControllerDelegate {
    public func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated: true, completion: nil)
    }

    public func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        
        self.previewPhotoModel?.editImage = croppedImage
        
        if let previewPhotoModel = self.previewPhotoModel {
            self.selectPhotoModels.append(previewPhotoModel)
        }
       
        self.selectedPhotosFinishDisMiss()
        
        if self.config.animateStyle == .push {
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: false)
        } else {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: 照片列表缓存策略
// extension PhotoPickerVC {
//    // MARK: UIScrollView
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//         updateCachedAssets()
//    }
//
//    // MARK: Asset Caching
//
//    fileprivate func resetCachedAssets() {
//        imageManager.stopCachingImagesForAllAssets()
//        previousPreheatRect = .zero
//    }
//
//    fileprivate func updateCachedAssets() {
//        // Update only if the view is visible.
//        guard isViewLoaded && view.window != nil else { return }
//
//        // The preheat window is twice the height of the visible rect.
//        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
//        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
//
//        // Update only if the visible area is significantly different from the last preheated area.
//        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
//        guard delta > view.bounds.height / 3 else { return }
//
//        guard let result = self.albumModel?.result else {
//            return
//        }
//
//        // Compute the assets to start caching and to stop caching.
//        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
//
//        let addedAssets = addedRects
//            .flatMap { rect in self.collectionView.indexPathsForElements(in: rect) }
//            .map { indexPath in
//                result.object(at: self.config.cameraPlaceholderType == .none ? indexPath.item : indexPath.item > 0 ? indexPath.item - 1 : 0) }
//        let removedAssets = removedRects
//            .flatMap { rect in self.collectionView.indexPathsForElements(in: rect) }
//            .map { indexPath in
//                result.object(at: self.config.cameraPlaceholderType == .none ? indexPath.item : indexPath.item > 0 ? indexPath.item - 1 : 0)
//            }
//
//        // Update the assets the PHCachingImageManager is caching.
//        imageManager.startCachingImages(for: addedAssets,
//            targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
//        imageManager.stopCachingImages(for: removedAssets,
//            targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
//
//        // Store the preheat rect to compare against in the future.
//        previousPreheatRect = preheatRect
//    }
//
//    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
//        if old.intersects(new) {
//            var added = [CGRect]()
//            if new.maxY > old.maxY {
//                added += [CGRect(x: new.origin.x, y: old.maxY,
//                                    width: new.width, height: new.maxY - old.maxY)]
//            }
//            if old.minY > new.minY {
//                added += [CGRect(x: new.origin.x, y: new.minY,
//                                    width: new.width, height: old.minY - new.minY)]
//            }
//            var removed = [CGRect]()
//            if new.maxY < old.maxY {
//                removed += [CGRect(x: new.origin.x, y: new.maxY,
//                                      width: new.width, height: old.maxY - new.maxY)]
//            }
//            if old.minY < new.minY {
//                removed += [CGRect(x: new.origin.x, y: old.minY,
//                                      width: new.width, height: new.minY - old.minY)]
//            }
//            return (added, removed)
//        } else {
//            return ([new], [old])
//        }
//    }
// }
