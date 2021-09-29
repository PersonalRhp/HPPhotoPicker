//
// PhotoPreviewCell.swift
// Ouyu
//
// Created by raohongping on 2021/8/27.
//
//

/*
 * @功能描述：图片预览
 * @创建时间：2021/8/27
 * @创建人：饶鸿平
 */

import UIKit
import Photos
import RSKImageCropper

class PhotoPreviewController: UIViewController {
    // 照片item的间距
    static let colItemSpacing: CGFloat = 40
    // 预览选中图片的视图高度
    static let selPhotoPreviewH: CGFloat = 100
    
    // 第一次进入界面时，布局后frame，裁剪dimiss动画使用
    var originalFrame: CGRect = .zero
    
    static let previewVCScrollNotification = Notification.Name("previewVCScrollNotification")
    
    // 展示的图片数组
    var arrDataSources: [HPPhotoModel]
    
    // 选中的图片数组
    var arrSelectedModels: [HPPhotoModel]
    
    let showBottomViewAndSelectBtn: Bool
    
    var currentIndex = 0
    
    var indexBeforOrientationChanged = 0
    
    var collectionView: UICollectionView!
    
    var navView: UIView!
    
    var navBlurView: UIVisualEffectView?
    
    var backBtn: UIButton!
    
    var selectBtn: UIButton!
    
    var bottomView: UIView!
    
    var bottomBlurView: UIVisualEffectView?
    
    var editBtn: UIButton!

    var doneBtn: UIButton!
    
    var selPhotoPreview: ZLPhotoPreviewSelectedView?
    
    var isFirstAppear = true
    
    var hideNavView = false
    
    var popInteractiveTransition: PhotoPreviewPopInteractiveTransition?
    
    var config = PhotoConfiguration()
    
    /// 是否在点击确定时候，当未选择任何照片时候，自动选择当前index的照片
    var autoSelectCurrentIfNotSelectAnyone = true
    
    /// 界面消失时，通知上个界面刷新（针对预览视图）
    var backBlock: ((_ arrSelectedModels: [HPPhotoModel]) -> Void)?
    
    /// 完成图片选择回调
    var selectPhotoBlock: ((_ arrSelectedModels: [HPPhotoModel]) -> Void)?
    
    var orientation: UIInterfaceOrientation = .unknown
    
    override var prefersStatusBarHidden: Bool {
        return !self.config.showStatusBarInPreviewInterface
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.config.statusBarStyle
    }

    init(photos: [HPPhotoModel], arrSelectedModels: [HPPhotoModel], index: Int, showBottomViewAndSelectBtn: Bool = true) {
        self.arrDataSources = photos
        self.arrSelectedModels = arrSelectedModels
        self.showBottomViewAndSelectBtn = showBottomViewAndSelectBtn
        self.currentIndex = index
        self.indexBeforOrientationChanged = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.addPopInteractiveTransition()
        self.resetSubViewStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.delegate = self
        guard self.isFirstAppear else { return }
        self.isFirstAppear = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            insets = self.view.safeAreaInsets
        }
        insets.top = max(20, insets.top)
        
        self.collectionView.frame = CGRect(x: -PhotoPreviewController.colItemSpacing / 2, y: 0, width: self.view.frame.width + PhotoPreviewController.colItemSpacing, height: self.view.frame.height)
        self.originalFrame = self.collectionView.frame
        
        let navH = insets.top + 44
        self.navView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: navH)
        self.navBlurView?.frame = self.navView.bounds
        
        self.backBtn.frame = CGRect(x: insets.left, y: insets.top, width: 60, height: 44)
        self.selectBtn.frame = CGRect(x: self.view.frame.width - 40 - insets.right, y: insets.top + (44 - 25) / 2, width: 25, height: 25)
        
        self.refreshBottomViewFrame()
        
        let ori = UIApplication.shared.statusBarOrientation
        if ori != self.orientation {
            self.orientation = ori
            self.collectionView.setContentOffset(CGPoint(x: (self.view.frame.width + PhotoPreviewController.colItemSpacing) * CGFloat(self.indexBeforOrientationChanged), y: 0), animated: false)
             self.collectionView.performBatchUpdates({
                self.collectionView.setContentOffset(CGPoint(x: (self.view.frame.width + PhotoPreviewController.colItemSpacing) * CGFloat(self.indexBeforOrientationChanged), y: 0), animated: false)
             })
        }
    }
}

// MARK: UI
extension PhotoPreviewController {
    func setupUI() {
        
        let config = self.config
        self.view.backgroundColor = config.customUI.previewBgColor
        // nav view
        self.navView = UIView()
        self.navView.backgroundColor = config.customUI.previewBgColor
        self.view.addSubview(self.navView)
        
        self.backBtn = UIButton(type: .custom)
        self.backBtn.setImage(config.customUI.navBarBackIcon, for: .normal)
        self.backBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        self.backBtn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        self.navView.addSubview(self.backBtn)
        
        self.selectBtn = UIButton(type: .custom)
        self.selectBtn.setImage(config.customUI.previewNormalIcon, for: .normal)
        self.selectBtn.setImage(config.customUI.selectedIcon, for: .selected)
        self.selectBtn.enlargeValidTouchArea(inset: 10)
        self.selectBtn.addTarget(self, action: #selector(selectBtnClick), for: .touchUpInside)
        self.navView.addSubview(self.selectBtn)
    
        // collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.isPagingEnabled = true
        self.collectionView.showsHorizontalScrollIndicator = false
        self.view.addSubview(self.collectionView)
        
        ZLPhotoPreviewCell.register(self.collectionView)
        ZLVideoPreviewCell.register(self.collectionView)
        
        // bottom view
        self.bottomView = UIView()
        self.bottomView.backgroundColor = config.customUI.previewBgColor
        self.view.addSubview(self.bottomView)
        
        if config.showSelectedPhotoPreview {
            self.selPhotoPreview = ZLPhotoPreviewSelectedView(selModels: self.arrSelectedModels, currentShowModel: self.arrDataSources[self.currentIndex], customConfig: config.customUI)
            self.selPhotoPreview?.selectBlock = { [weak self] (model) in
                self?.scrollToSelPreviewCell(model)
            }
//            self.selPhotoPreview?.endSortBlock = { [weak self] (models) in
//
//            }
            self.bottomView.addSubview(self.selPhotoPreview!)
        }
        
        func createBtn(_ title: String, _ action: Selector) -> UIButton {
            let btn = UIButton(type: .custom)
            btn.setTitle(title, for: .normal)
            btn.addTarget(self, action: action, for: .touchUpInside)
            return btn
        }
        
        self.editBtn = createBtn(self.config.customUI.editButtonTitle, #selector(editBtnClick))
        self.editBtn.isHidden = (!config.image.allowEditImage && !config.video.allowEditVideo)
        self.editBtn.titleLabel?.font = self.config.customUI.editButtonTitleFont
        self.editBtn.setTitleColor(self.config.customUI.editButtonTitleColor, for: .normal)
        self.bottomView.addSubview(self.editBtn)
        
        self.doneBtn = createBtn(self.config.customUI.finishButtonTitle, #selector(doneBtnClick))
        self.doneBtn.titleLabel?.font = self.config.customUI.finishButtonTitleFont
        self.doneBtn.setTitleColor(self.config.customUI.finishButtonTitleColor, for: .normal)
        self.doneBtn.layer.masksToBounds = true
        self.doneBtn.layer.cornerRadius = bottomToolBtnCornerRadius
        self.bottomView.addSubview(self.doneBtn)
        
        self.view.bringSubviewToFront(self.navView)
        
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
    }
    
    func refreshBottomViewFrame() {
        var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            insets = self.view.safeAreaInsets
        }
        var bottomViewH = bottomToolViewH
        var showSelPhotoPreview = false
        if self.config.showSelectedPhotoPreview {
            if !self.arrSelectedModels.isEmpty {
                showSelPhotoPreview = true
                bottomViewH += PhotoPreviewController.selPhotoPreviewH
                self.selPhotoPreview?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: PhotoPreviewController.selPhotoPreviewH)
            }
        }
        let btnH = bottomToolBtnH
        
        self.bottomView.frame = CGRect(x: 0, y: self.view.frame.height-insets.bottom-bottomViewH, width: self.view.frame.width, height: bottomViewH+insets.bottom)
        self.bottomBlurView?.frame = self.bottomView.bounds
        
        let btnY: CGFloat = showSelPhotoPreview ? PhotoPreviewController.selPhotoPreviewH + bottomToolBtnY : bottomToolBtnY
        
        let editTitle = self.config.customUI.editButtonTitle
        let editBtnW = editTitle.boundingRect(font: .systemFont(ofSize: 17), limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)).width
        self.editBtn.frame = CGRect(x: 15, y: btnY, width: editBtnW, height: btnH)
        
        let selCount = self.arrSelectedModels.count
        var doneTitle = self.config.customUI.finishButtonTitle
        if selCount > 0 {
            doneTitle += "(" + String(selCount) + ")"
        }
        let doneBtnW = doneTitle.boundingRect(font: .systemFont(ofSize: 17), limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)).width + 20
        self.doneBtn.frame = CGRect(x: self.bottomView.bounds.width-doneBtnW-15, y: btnY, width: doneBtnW, height: btnH)
        self.doneBtn.setTitle(doneTitle, for: .normal)
        
        if selCount == 0 {
            doneBtn.removeGradientLayer()
            doneBtn.backgroundColor = self.config.customUI.finishButtonUnEnableBgColor
            doneBtn.setTitleColor(self.config.customUI.finishButtonUnEnableTitleColor, for: .normal)
            doneBtn.isUserInteractionEnabled = false
        } else {
            if let themeGradientColor = self.config.customUI.themeGradientColor {
                doneBtn.gradientColor(CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), themeGradientColor)
            } else {
                doneBtn.backgroundColor = self.config.customUI.themeColor
            }
            doneBtn.setTitleColor(self.config.customUI.finishButtonTitleColor, for: .normal)
            doneBtn.isUserInteractionEnabled = true
        }
    }
    
    func addPopInteractiveTransition() {
        guard (self.navigationController?.viewControllers.count ?? 0 ) > 1 else {
            // 仅有当前vc一个时候，说明不是从相册进入，不添加交互动画
            return
        }
        self.popInteractiveTransition = PhotoPreviewPopInteractiveTransition(viewController: self)
        self.popInteractiveTransition?.shouldStartTransition = { [weak self] (point) -> Bool in
            guard let `self` = self else { return false }
            if !self.hideNavView && (self.navView.frame.contains(point) || self.bottomView.frame.contains(point)) {
                return false
            }
            return true
        }
        self.popInteractiveTransition?.startTransition = { [weak self] in
            guard let `self` = self else { return }
            
            self.navView.alpha = 0
            self.bottomView.alpha = 0
            
            guard let cell = self.collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0)) else {
                return
            }
            if cell is ZLVideoPreviewCell {
                (cell as? ZLVideoPreviewCell)?.pauseWhileTransition()
            }
        }
        
        self.popInteractiveTransition?.cancelTransition = { [weak self] in
            guard let `self` = self else { return }
            
            self.hideNavView = false
            self.navView.isHidden = false
            self.bottomView.isHidden = false
            UIView.animate(withDuration: 0.5) {
                self.navView.alpha = 1
                self.bottomView.alpha = 1
            }
        }
    }
    
    func resetSubViewStatus() {
        let config = self.config
        let currentModel = self.arrDataSources[self.currentIndex]
        
        if currentModel.isCanSelected {
            self.selectBtn.isHidden = false
        } else {
            self.selectBtn.isHidden = true
        }
        
        self.selectBtn.isSelected = self.arrDataSources[self.currentIndex].isSelected
        
        guard self.showBottomViewAndSelectBtn else {
            self.selectBtn.isHidden = true
            self.bottomView.isHidden = true
            return
        }
        
        let selCount = self.arrSelectedModels.count
        self.selPhotoPreview?.isHidden = selCount == 0
        self.refreshBottomViewFrame()
        
        var hideEditBtn = true
        let maxSelectCount = currentModel.asset.mediaType == .image ? self.config.image.maxNumberOfItems : self.config.video.maxNumberOfItems
        if selCount < maxSelectCount || self.arrSelectedModels.contains(where: { $0 == currentModel }) {
            if config.image.allowEditImage && (currentModel.type == .image) {
                hideEditBtn = false
            }
            if config.video.allowEditVideo && currentModel.type == .video && (selCount == 0 || (selCount == 1 && self.arrSelectedModels.first == currentModel)) {
                hideEditBtn = false
            }
        }
        self.editBtn.isHidden = hideEditBtn
        
        // 视频单选隐藏选中和编辑按钮
        if self.arrSelectedModels.count > 0, arrSelectedModels[0].type == .video, config.video.singleVideo, config.mediaType == .video || config.mediaType == .imageAndVideo {
            self.selectBtn.isHidden = true
            self.editBtn.isHidden = true
        }
    }
    
    // MARK: btn actions
    @objc func backBtnClick() {
        
        // 视频单选，点击返回移除该视频
        if self.arrSelectedModels.count > 0, arrSelectedModels[0].type == .video, config.mediaType == .video || config.mediaType == .imageAndVideo, config.video.singleVideo {
            self.arrSelectedModels.removeAll()
        }
        
        self.backBlock?(self.arrSelectedModels)
        let vc = self.navigationController?.popViewController(animated: true)
        if vc == nil {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func doneBtnClick() {
        let currentModel = self.arrDataSources[self.currentIndex]

        if self.autoSelectCurrentIfNotSelectAnyone {
            if self.arrSelectedModels.isEmpty {
                self.arrSelectedModels.append(currentModel)
            }

            if !self.arrSelectedModels.isEmpty {
                self.selectPhotoBlock?(self.arrSelectedModels)
            }
        } else {
            self.selectPhotoBlock?(self.arrSelectedModels)
        }

        if self.config.animateStyle == .push {
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func scrollToSelPreviewCell(_ model: HPPhotoModel) {
        guard let index = self.arrDataSources.lastIndex(of: model) else {
            return
        }

        self.collectionView.performBatchUpdates {
            self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        } completion: { _ in
            self.indexBeforOrientationChanged = self.currentIndex
        }
    }
    
    func tapPreviewCell() {
        self.hideNavView = !self.hideNavView
        let currentCell = self.collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0))
        if let cell = currentCell as? ZLVideoPreviewCell {
            if cell.isPlaying {
                self.hideNavView = true
            }
        }
        self.navView.isHidden = self.hideNavView
        self.bottomView.isHidden = self.showBottomViewAndSelectBtn ? self.hideNavView : true
    }
}

// MARK: 图片选中逻辑
extension PhotoPreviewController {
    
    @objc func selectBtnClick() {
        
        let currentModel = self.arrDataSources[self.currentIndex]
        
        if self.config.allowMixSelect {
            print("同时选择照片和视频的功能，目前还不支持，敬请期待...")
            return
        }
        
        // 不满足可选的视频时长，直接return
        if !self.checkVideoDutationCanSelect(photoModel: currentModel) {
            return
        }
        
        self.selectBtn.layer.removeAllAnimations()
        
        if currentModel.isSelected {
            currentModel.isSelected = false
            self.arrSelectedModels.removeAll { $0 == currentModel }
            self.selPhotoPreview?.removeSelModel(model: currentModel)
        } else {
            currentModel.isSelected = true
            self.arrSelectedModels.append(currentModel)
            self.selPhotoPreview?.addSelModel(model: currentModel)
        }
        
        self.resetSubViewStatus()
        reloadListSelectStatus()
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
        
        // 没有选中更新为都可选
        if self.arrSelectedModels.isEmpty {
            updatePhotosCanSelectedStatus(true)
            return
        }

        if self.arrSelectedModels[0].asset.mediaType == .image {
            // 图片数量选中为最大数量列表都不可选
            if self.arrSelectedModels.count == self.config.image.maxNumberOfItems {
                updatePhotosCanSelectedStatus(false)
            } else {
                // 选中图片, 其它图片可选
                updateImageCanSelectedStatus(true)
                // 选中图片后, 视频不可选
                updateVideoCanSelectedStatus(false)
            }
        }
        
        if self.arrSelectedModels[0].asset.mediaType == .video {
            // 视频选中数量为最大数量需要将列表的照片都设置为不可选
            if self.arrSelectedModels.count == self.config.video.maxNumberOfItems {
                updatePhotosCanSelectedStatus(false)
            } else {
                // 选中视频, 其它视频可选
                updateVideoCanSelectedStatus(true)
                // 选中视频后, 图片都不可选
                updateImageCanSelectedStatus(false)
            }
        }
    }
    
    // 更新照片列表是否可以选中
    func updatePhotosCanSelectedStatus(_ isCanSelected: Bool) {
        
        // 更新没有选中的照片的可选状态
        for photoModel in arrDataSources where !photoModel.isSelected {
            photoModel.isCanSelected = isCanSelected
        }
    }
    
    // 更新图片是否可以选中
    func updateImageCanSelectedStatus(_ isCanSelected: Bool) {
        
        for photoModel in arrDataSources where photoModel.asset.mediaType == .image {
            photoModel.isCanSelected = isCanSelected
        }
    }
    
    // 更新视频是否可以选中
    func updateVideoCanSelectedStatus(_ isCanSelected: Bool) {
        
        for photoModel in arrDataSources where photoModel.asset.mediaType == .video {
            photoModel.isCanSelected = isCanSelected
        }
    }
}

// MARK: 编辑
extension PhotoPreviewController {
    
    @objc func editBtnClick() {
        let currentModel = self.arrDataSources[self.currentIndex]
        
        if let editImage = currentModel.editImage  {
            showEditImageVC(image: editImage)
            return
        }
        
        PhotoManger.fetchHighQualityOriginImage(for: currentModel.asset) { image, _ in
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
                
                self.showEditImageVC(image: clipImage)
            }
        }
    }
    
    func showEditImageVC(image: UIImage) {
        var imageCropMode: RSKImageCropMode!
        
        if self.config.image.cropMode == .circle {
            imageCropMode = .circle
        } else if self.config.image.cropMode == .square {
            imageCropMode = .square
        } else {
            imageCropMode = .custom
        }
        
        let clipVC = RSKImageCropViewController.init(image: image, cropMode: imageCropMode)
        clipVC.modalPresentationStyle = .fullScreen
        clipVC.delegate = self
        clipVC.dataSource = self.config.image.customCropDataSource
        clipVC.avoidEmptySpaceAroundImage = true
        self.present(clipVC, animated: true, completion: nil)
    }
}

extension PhotoPreviewController: RSKImageCropViewControllerDelegate {
    public func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated: true, completion: nil)
    }

    public func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        let currentModel = self.arrDataSources[self.currentIndex]
        currentModel.editImage = croppedImage
        self.selPhotoPreview?.currentShowModelChanged(model: currentModel)
        self.collectionView.reloadData()
        dismiss(animated: true, completion: nil)
    }
}

extension PhotoPreviewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return nil
        }
        return self.popInteractiveTransition?.interactive == true ? PhotoPreviewAnimatedTransition() : nil
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.popInteractiveTransition?.interactive == true ? self.popInteractiveTransition : nil
    }
}

// scroll view delegate
extension PhotoPreviewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.collectionView else {
            return
        }
        NotificationCenter.default.post(name: PhotoPreviewController.previewVCScrollNotification, object: nil)
        let offset = scrollView.contentOffset
        var page = Int(round(offset.x / (self.view.bounds.width + PhotoPreviewController.colItemSpacing)))
        page = max(0, min(page, self.arrDataSources.count-1))
        if page == self.currentIndex {
            return
        }
        self.currentIndex = page
        self.resetSubViewStatus()
        self.selPhotoPreview?.currentShowModelChanged(model: self.arrDataSources[self.currentIndex])
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    
    }
    
}

extension PhotoPreviewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return PhotoPreviewController.colItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return PhotoPreviewController.colItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: PhotoPreviewController.colItemSpacing / 2, bottom: 0, right: PhotoPreviewController.colItemSpacing / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.bounds.width, height: self.view.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrDataSources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = self.arrDataSources[indexPath.row]
        
        let baseCell: PreviewBaseCell
        
        if model.type == .video {
            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: ZLVideoPreviewCell.identifier(), for: indexPath) as? ZLVideoPreviewCell)!
            
            cell.model = model
            
            baseCell = cell
        } else {
            let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: ZLPhotoPreviewCell.identifier(), for: indexPath) as? ZLPhotoPreviewCell)!

            cell.singleTapBlock = { [weak self] in
                self?.tapPreviewCell()
            }

            cell.model = model

            baseCell = cell
        }
        
        baseCell.singleTapBlock = { [weak self] in
            self?.tapPreviewCell()
        }
        
        return baseCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let c = cell as? PreviewBaseCell {
            c.resetSubViewStatusWhenCellEndDisplay()
        }
    }
    
}

/// 下方显示的已选择照片列表
class ZLPhotoPreviewSelectedView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    var bottomBlurView: UIVisualEffectView?
    
    var collectionView: UICollectionView!
    
    var arrSelectedModels: [HPPhotoModel]
    
    var currentShowModel: HPPhotoModel
    
    var customConfig: CustomUI
    
    var selectBlock: ( (HPPhotoModel) -> Void )?
    
    var endSortBlock: ( ([HPPhotoModel]) -> Void )?
    
    var isDraging = false
    
    init(selModels: [HPPhotoModel], currentShowModel: HPPhotoModel, customConfig: CustomUI) {
        self.arrSelectedModels = selModels
        self.currentShowModel = currentShowModel
        self.customConfig = customConfig
        super.init(frame: .zero)
        self.setupUI()
    }
    
    func setupUI() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        
        layout.sectionInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.alwaysBounceHorizontal = true
        self.addSubview(self.collectionView)
        
        ZLPhotoPreviewSelectedViewCell.register(self.collectionView)
        
        if #available(iOS 11.0, *) {
            self.collectionView.dragDelegate = self
            self.collectionView.dropDelegate = self
            self.collectionView.dragInteractionEnabled = true
            self.collectionView.isSpringLoaded = true
        } else {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
            self.collectionView.addGestureRecognizer(longPressGesture)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.bottomBlurView?.frame = self.bounds
        self.collectionView.frame = CGRect(x: 0, y: 10, width: self.bounds.width, height: 80)
        if let index = self.arrSelectedModels.firstIndex(where: { $0 == self.currentShowModel }) {
            self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    func currentShowModelChanged(model: HPPhotoModel) {
       
        self.currentShowModel = model
        
        if let index = self.arrSelectedModels.firstIndex(where: { $0 == self.currentShowModel }) {
            self.collectionView.performBatchUpdates {
                self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
            } completion: { _ in
                self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            }

        } else {
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }
    }
    
    func addSelModel(model: HPPhotoModel) {
        self.arrSelectedModels.append(model)
        let indexPath = IndexPath(row: self.arrSelectedModels.count - 1, section: 0)
        self.collectionView.insertItems(at: [indexPath])
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func removeSelModel(model: HPPhotoModel) {
        guard let index = self.arrSelectedModels.firstIndex(where: { $0 == model }) else {
            return
        }
        self.arrSelectedModels.remove(at: index)
        self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
    }
    
    func refreshCell(for model: HPPhotoModel) {
        guard let index = self.arrSelectedModels.firstIndex(where: { $0 == model }) else {
            return
        }
        self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
    }
    
    // MARK: iOS10 拖动
    @objc func longPressAction(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let indexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else {
                return
            }
            self.isDraging = true
            self.collectionView.beginInteractiveMovementForItem(at: indexPath)
        } else if gesture.state == .changed {
            self.collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: self.collectionView))
        } else if gesture.state == .ended {
            self.isDraging = false
            self.collectionView.endInteractiveMovement()
            self.endSortBlock?(self.arrSelectedModels)
        } else {
            self.isDraging = false
            self.collectionView.cancelInteractiveMovement()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let moveModel = self.arrSelectedModels[sourceIndexPath.row]
        self.arrSelectedModels.remove(at: sourceIndexPath.row)
        self.arrSelectedModels.insert(moveModel, at: destinationIndexPath.row)
    }
    
    // MARK: iOS11 拖动
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        self.isDraging = true
        let itemProvider = NSItemProvider()
        let item = UIDragItem(itemProvider: itemProvider)
        return [item]
    }
    
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    @available(iOS 11.0, *)
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        self.isDraging = false
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }
        guard let item = coordinator.items.first else {
            return
        }
        guard let sourceIndexPath = item.sourceIndexPath else {
            return
        }
        
        if coordinator.proposal.operation == .move {
            collectionView.performBatchUpdates({
                let moveModel = self.arrSelectedModels[sourceIndexPath.row]
                
                self.arrSelectedModels.remove(at: sourceIndexPath.row)
                
                self.arrSelectedModels.insert(moveModel, at: destinationIndexPath.row)
                
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }, completion: nil)
            
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            
            self.endSortBlock?(self.arrSelectedModels)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrSelectedModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: ZLPhotoPreviewSelectedViewCell.identifier(), for: indexPath) as? ZLPhotoPreviewSelectedViewCell)!
        
        let model = self.arrSelectedModels[indexPath.row]
        cell.model = model
        
        if model.identifier == self.currentShowModel.identifier {
            cell.layer.borderWidth = 4
            cell.layer.borderColor = self.customConfig.themeColor.cgColor
        } else {
            cell.layer.borderWidth =  0
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !self.isDraging else {
            return
        }
        let model = self.arrSelectedModels[indexPath.row]
        self.currentShowModel = model
        
        self.collectionView.performBatchUpdates {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } completion: { _ in
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }

        self.selectBlock?(model)
    }
}

class ZLPhotoPreviewSelectedViewCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    var imageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    var imageIdentifier: String = ""
    
    var tagImageView: UIImageView!
    
    var model: HPPhotoModel! {
        didSet {
            self.configureCell()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderColor = UIColor.white.cgColor
        
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
        
        self.tagImageView = UIImageView()
        self.tagImageView.contentMode = .scaleAspectFit
        self.tagImageView.clipsToBounds = true
        self.contentView.addSubview(self.tagImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        self.tagImageView.frame = CGRect(x: 5, y: self.bounds.height-25, width: 20, height: 20)
    }
    
    func configureCell() {
        let scale = UIScreen.main.scale
        let size = CGSize(width: self.bounds.width * scale, height: self.bounds.height * scale)
        
        if self.imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.imageRequestID)
        }
        
        if self.model.editImage != nil {
            self.tagImageView.isHidden = false
            self.tagImageView.image = ResourcesTool.getBundleImg(named: "")
        } else {
            self.tagImageView.isHidden = true
        }
        
        self.imageIdentifier = self.model.identifier
        self.imageView.image = nil
        
        if let editImage = self.model.editImage {
            self.imageView.image = editImage
        } else {
            self.imageRequestID = PhotoManger.fastFetchImage(for: self.model.asset, size: size, completion: { [weak self] (image, _) in
                if self?.imageIdentifier == self?.model.identifier {
                    self?.imageView.image = image
                }
            })
        }
    }
}
