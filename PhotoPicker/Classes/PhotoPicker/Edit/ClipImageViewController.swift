/*
 * @功能描述：图片裁剪, 功能比较全，但由于时间比较紧，暂时废弃
 * @创建时间：2021/8/27
 * @创建人：饶鸿平
 */

import UIKit

class ClipImageViewController: UIViewController {

    static let bottomToolViewH: CGFloat = 90
    
    /// 用作进入裁剪界面首次动画frame
    var presentAnimateFrame: CGRect?
    
    /// 用作进入裁剪界面首次动画和取消裁剪时动画的image
    var presentAnimateImage: UIImage?
    
    /// 取消裁剪时动画frame
    var cancelClipAnimateFrame: CGRect = .zero
    
    var viewDidAppearCount = 0
    
    var selectedRatio = ZLImageClipRatio(title: "9 : 16", whRatio: 9 / 16)
    
    let originalImage: UIImage
    
    var editImage: UIImage
    
    /// 初次进入界面时候，裁剪范围
    var editRect: CGRect
    
    var scrollView: UIScrollView!
    
    var containerView: UIView!
    
    var imageView: UIImageView!
    
    var shadowView: ZLClipShadowView!
    
    var overlayView: ZLClipOverlayView!
    
    var gridPanGes: UIPanGestureRecognizer!
    
    var bottomToolView: UIView!
    
    var bottomShadowLayer: CAGradientLayer!
    
    var cancelBtn: UIButton!
    
    var doneBtn: UIButton!
    
    var shouldLayout = true
    
    var panEdge: ClipImageViewController.ClipPanEdge = .none
    
    var beginPanPoint: CGPoint = .zero
    
    var clipBoxFrame: CGRect = .zero
    
    var clipOriginFrame: CGRect = .zero
    
    var isRotating = false
    
    var thumbnailImage: UIImage?
    
    var maxClipFrame: CGRect = {
        var insets = deviceSafeAreaInsets()
        insets.top += 100
        var rect = CGRect.zero
        rect.origin.x = 15
        rect.origin.y = insets.top
        rect.size.width = UIScreen.main.bounds.width - 15 * 2
        rect.size.height = UIScreen.main.bounds.height - insets.top - ClipImageViewController.bottomToolViewH - 25
        return rect
    }()
    
    var minClipSize = CGSize(width: 45, height: 45)
    
    var resetTimer: Timer?
    
    var dismissAnimateFromRect: CGRect = .zero
    
    var dismissAnimateImage: UIImage?
    
    var clipDoneBlock: ( (UIImage) -> Void )?
    
    var cancelClipBlock: ( () -> Void )?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    deinit {
        self.cleanTimer()
    }
    
    init(image: UIImage, editRect: CGRect?) {
        self.originalImage = image
        self.editRect = editRect ?? .zero
        self.editImage = image
        super.init(nibName: nil, bundle: nil)
        self.calculateClipRect()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: 生命周期
extension ClipImageViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.generateThumbnailImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.viewDidAppearCount == 0, let frame = self.presentAnimateFrame, let image = self.presentAnimateImage {
            let animateImageView = UIImageView(image: image)
            animateImageView.contentMode = .scaleAspectFill
            animateImageView.clipsToBounds = true
            animateImageView.frame = frame
            self.view.addSubview(animateImageView)
            
            self.cancelClipAnimateFrame = self.clipBoxFrame
            
            UIView.animate(withDuration: 0.25) {
                animateImageView.frame = self.clipBoxFrame
                self.bottomToolView.alpha = 1
            } completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self.scrollView.alpha = 1
                    self.overlayView.alpha = 1
                } completion: { _ in
                    animateImageView.removeFromSuperview()
                }
            }
        }
        
        self.viewDidAppearCount += 1
        self.transitioningDelegate = self
    }
}

// MARK: UI
extension ClipImageViewController {
    func setupUI() {
        self.view.backgroundColor = .black
        
        self.scrollView = UIScrollView()
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.alwaysBounceHorizontal = true
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        self.scrollView.delegate = self
        self.view.addSubview(self.scrollView)
        
        self.containerView = UIView()
        self.scrollView.addSubview(self.containerView)
        
        self.imageView = UIImageView(image: self.editImage)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        self.containerView.addSubview(self.imageView)
        
        self.shadowView = ZLClipShadowView()
        self.shadowView.isUserInteractionEnabled = false
        self.shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        self.view.addSubview(self.shadowView)
        
        self.overlayView = ZLClipOverlayView()
        self.overlayView.isUserInteractionEnabled = false
        self.view.addSubview(self.overlayView)
        
        self.bottomToolView = UIView()
        self.view.addSubview(self.bottomToolView)
        
        let color1 = UIColor.black.withAlphaComponent(0.15).cgColor
        let color2 = UIColor.black.withAlphaComponent(0.35).cgColor
        
        self.bottomShadowLayer = CAGradientLayer()
        self.bottomShadowLayer.colors = [color1, color2]
        self.bottomShadowLayer.locations = [0, 1]
        self.bottomToolView.layer.addSublayer(self.bottomShadowLayer)
        
        self.cancelBtn = UIButton(type: .custom)
        self.cancelBtn.setTitle("取消", for: .normal)
        self.cancelBtn.adjustsImageWhenHighlighted = false
        self.cancelBtn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        self.bottomToolView.addSubview(self.cancelBtn)
    
        self.doneBtn = UIButton(type: .custom)
        self.doneBtn.setTitle("选取", for: .normal)
        self.doneBtn.adjustsImageWhenHighlighted = false
        self.doneBtn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        self.bottomToolView.addSubview(self.doneBtn)
        self.gridPanGes = UIPanGestureRecognizer(target: self, action: #selector(gridGesPanAction(_:)))
        self.gridPanGes.delegate = self
        self.view.addGestureRecognizer(self.gridPanGes)
        self.scrollView.panGestureRecognizer.require(toFail: self.gridPanGes)
        
        self.scrollView.alpha = 0
        self.overlayView.alpha = 0
        self.bottomToolView.alpha = 0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard self.shouldLayout else {
            return
        }
        self.shouldLayout = false
        
        self.scrollView.frame = self.view.bounds
        self.shadowView.frame = self.view.bounds
        
        self.layoutInitialImage()
        
        self.bottomToolView.frame = CGRect(x: 0, y: self.view.bounds.height - ClipImageViewController.bottomToolViewH, width: self.view.bounds.width, height: ClipImageViewController.bottomToolViewH)
        self.bottomShadowLayer.frame = self.bottomToolView.bounds
        
        let toolBtnH: CGFloat = 25
        let toolBtnW: CGFloat = 60
        let toolBtnY = (ClipImageViewController.bottomToolViewH - toolBtnH) / 2 - 10
        self.cancelBtn.frame = CGRect(x: 30, y: toolBtnY, width: toolBtnW, height: toolBtnH)
        self.doneBtn.frame = CGRect(x: self.view.bounds.width-30-toolBtnH, y: toolBtnY, width: toolBtnW, height: toolBtnH)
    }
}

// MARK: 裁剪和缩放逻辑
extension ClipImageViewController {
    func generateThumbnailImage() {
        let size: CGSize
        let ratio = (self.editImage.size.width / self.editImage.size.height)
        let fixLength: CGFloat = 100
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        self.thumbnailImage = self.editImage.resize(toSize: size)
    }
    
    func calculateClipRect() {
        if self.selectedRatio.whRatio == 0 {
            self.editRect = CGRect(origin: .zero, size: self.editImage.size)
        } else {
            let imageSize = self.editImage.size
            let imageWHRatio = imageSize.width / imageSize.height
            
            var width: CGFloat = 0, height: CGFloat = 0
            if self.selectedRatio.whRatio >= imageWHRatio {
                width = imageSize.width
                height = width / self.selectedRatio.whRatio
            } else {
                height = imageSize.height
                width = height * self.selectedRatio.whRatio
            }
            
            self.editRect = CGRect(x: (imageSize.width - width) / 2, y: (imageSize.height - height) / 2, width: width, height: height)
        }
    }
    
    func layoutInitialImage() {
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 1
        self.scrollView.zoomScale = 1
        
        let editSize = self.editRect.size
        self.scrollView.contentSize = editSize
        let maxClipRect = self.maxClipFrame
        
        self.containerView.frame = CGRect(origin: .zero, size: self.editImage.size)
        self.imageView.frame = self.containerView.bounds
        
        // editRect比例，计算editRect所占frame
        let editScale = min(maxClipRect.width / editSize.width, maxClipRect.height / editSize.height)
        let scaledSize = CGSize(width: floor(editSize.width * editScale), height: floor(editSize.height * editScale))
        
        var frame = CGRect.zero
        frame.size = scaledSize
        frame.origin.x = maxClipRect.minX + floor((maxClipRect.width-frame.width) / 2)
        frame.origin.y = maxClipRect.minY + floor((maxClipRect.height-frame.height) / 2)
        
        // 按照edit image进行计算最小缩放比例
        let originalScale = min(maxClipRect.width/self.editImage.size.width, maxClipRect.height/self.editImage.size.height)
        // 将 edit rect 相对 originalScale 进行缩放，缩放到图片未放大时候的clip rect
        let scaleEditSize = CGSize(width: self.editRect.width * originalScale, height: self.editRect.height * originalScale)
        // 计算缩放后的clip rect相对maxClipRect的比例
        let clipRectZoomScale = min(maxClipRect.width/scaleEditSize.width, maxClipRect.height/scaleEditSize.height)
        
        self.scrollView.minimumZoomScale = originalScale
        self.scrollView.maximumZoomScale = 10
        // 设置当前zoom scale
        let zoomScale = (clipRectZoomScale * originalScale)
        self.scrollView.zoomScale = zoomScale
        self.scrollView.contentSize = CGSize(width: self.editImage.size.width * zoomScale, height: self.editImage.size.height * zoomScale)
        
        self.changeClipBoxFrame(newFrame: frame)
        
        if (frame.size.width < scaledSize.width - CGFloat.ulpOfOne) || (frame.size.height < scaledSize.height - CGFloat.ulpOfOne) {
            var offset = CGPoint.zero
            offset.x = -floor((self.scrollView.frame.width - scaledSize.width) / 2)
            offset.y = -floor((self.scrollView.frame.height - scaledSize.height) / 2)
            self.scrollView.contentOffset = offset
        }
        
        // edit rect 相对 image size 的 偏移量
        let diffX = self.editRect.origin.x / self.editImage.size.width * self.scrollView.contentSize.width
        let diffY = self.editRect.origin.y / self.editImage.size.height * self.scrollView.contentSize.height
        self.scrollView.contentOffset = CGPoint(x: -self.scrollView.contentInset.left+diffX, y: -self.scrollView.contentInset.top+diffY)
    }
    
    func changeClipBoxFrame(newFrame: CGRect) {
        guard self.clipBoxFrame != newFrame else {
            return
        }
        if newFrame.width < CGFloat.ulpOfOne || newFrame.height < CGFloat.ulpOfOne {
            return
        }
        var frame = newFrame
        let originX = ceil(self.maxClipFrame.minX)
        let diffX = frame.minX - originX
        frame.origin.x = max(frame.minX, originX)
        if diffX < -CGFloat.ulpOfOne {
            frame.size.width += diffX
        }
        let originY = ceil(self.maxClipFrame.minY)
        let diffY = frame.minY - originY
        frame.origin.y = max(frame.minY, originY)
        if diffY < -CGFloat.ulpOfOne {
            frame.size.height += diffY
        }
        let maxW = self.maxClipFrame.width + self.maxClipFrame.minX - frame.minX
        frame.size.width = max(self.minClipSize.width, min(frame.width, maxW))
        let maxH = self.maxClipFrame.height + self.maxClipFrame.minY - frame.minY
        frame.size.height = max(self.minClipSize.height, min(frame.height, maxH))
        self.clipBoxFrame = frame
        self.shadowView.clearRect = frame
        self.overlayView.frame = frame.insetBy(dx: -ZLClipOverlayView.cornerLineWidth, dy: -ZLClipOverlayView.cornerLineWidth)
        
        self.scrollView.contentInset = UIEdgeInsets(top: frame.minY, left: frame.minX, bottom: self.scrollView.frame.maxY-frame.maxY, right: self.scrollView.frame.maxX-frame.maxX)
        
        let scale = max(frame.height/self.editImage.size.height, frame.width/self.editImage.size.width)
        self.scrollView.minimumZoomScale = scale
        self.scrollView.zoomScale = self.scrollView.zoomScale
    }
    
    @objc func cancelBtnClick() {
        self.dismissAnimateFromRect = self.cancelClipAnimateFrame
        self.dismissAnimateImage = self.presentAnimateImage
        self.cancelClipBlock?()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneBtnClick() {
        let image = self.clipImage()
        self.dismissAnimateFromRect = self.clipBoxFrame
        self.dismissAnimateImage = image.clipImage
        self.clipDoneBlock?(image.clipImage)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func gridGesPanAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: self.view)
        if pan.state == .began {
            self.startEditing()
            self.beginPanPoint = point
            self.clipOriginFrame = self.clipBoxFrame
            self.panEdge = self.calculatePanEdge(at: point)
        } else if pan.state == .changed {
            guard self.panEdge != .none else {
                return
            }
            self.updateClipBoxFrame(point: point)
        } else if pan.state == .cancelled || pan.state == .ended {
            self.panEdge = .none
            self.startTimer()
        }
    }
    
    func calculatePanEdge(at point: CGPoint) -> ClipImageViewController.ClipPanEdge {
        let frame = self.clipBoxFrame.insetBy(dx: -30, dy: -30)
        
        let cornerSize = CGSize(width: 60, height: 60)
        let topLeftRect = CGRect(origin: frame.origin, size: cornerSize)
        if topLeftRect.contains(point) {
            return .topLeft
        }
        
        let topRightRect = CGRect(origin: CGPoint(x: frame.maxX-cornerSize.width, y: frame.minY), size: cornerSize)
        if topRightRect.contains(point) {
            return .topRight
        }
        
        let bottomLeftRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY-cornerSize.height), size: cornerSize)
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }
        
        let bottomRightRect = CGRect(origin: CGPoint(x: frame.maxX-cornerSize.width, y: frame.maxY-cornerSize.height), size: cornerSize)
        if bottomRightRect.contains(point) {
            return .bottomRight
        }
        
        let topRect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: cornerSize.height))
        if topRect.contains(point) {
            return .top
        }
        
        let bottomRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY-cornerSize.height), size: CGSize(width: frame.width, height: cornerSize.height))
        if bottomRect.contains(point) {
            return .bottom
        }
        
        let leftRect = CGRect(origin: frame.origin, size: CGSize(width: cornerSize.width, height: frame.height))
        if leftRect.contains(point) {
            return .left
        }
        
        let rightRect = CGRect(origin: CGPoint(x: frame.maxX-cornerSize.width, y: frame.minY), size: CGSize(width: cornerSize.width, height: frame.height))
        if rightRect.contains(point) {
            return .right
        }
        
        return .none
    }

    // swiftlint:disable:next cyclomatic_complexity
    func updateClipBoxFrame(point: CGPoint) {
        var frame = self.clipBoxFrame
        let originFrame = self.clipOriginFrame
        
        var newPoint = point
        newPoint.x = max(self.maxClipFrame.minX, newPoint.x)
        newPoint.y = max(self.maxClipFrame.minY, newPoint.y)
        
        let diffX = ceil(newPoint.x - self.beginPanPoint.x)
        let diffY = ceil(newPoint.y - self.beginPanPoint.y)
        let ratio = self.selectedRatio.whRatio
        
        switch self.panEdge {
        case .left:
            frame.origin.x = originFrame.minX + diffX
            frame.size.width = originFrame.width - diffX
            if ratio != 0 {
                frame.size.height = originFrame.height - diffX / ratio
            }
            
        case .right:
            frame.size.width = originFrame.width + diffX
            if ratio != 0 {
                frame.size.height = originFrame.height + diffX / ratio
            }
            
        case .top:
            frame.origin.y = originFrame.minY + diffY
            frame.size.height = originFrame.height - diffY
            if ratio != 0 {
                frame.size.width = originFrame.width - diffY * ratio
            }
            
        case .bottom:
            frame.size.height = originFrame.height + diffY
            if ratio != 0 {
                frame.size.width = originFrame.width + diffY * ratio
            }
            
        case .topLeft:
            if ratio != 0 {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffX / ratio
                frame.size.height = originFrame.height - diffX / ratio
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
            
        case .topRight:
            if ratio != 0 {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY - diffX / ratio
                frame.size.height = originFrame.height + diffX / ratio
            } else {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
            
        case .bottomLeft:
            if ratio != 0 {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height - diffX / ratio
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height + diffY
            }
            
        case .bottomRight:
            if ratio != 0 {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffX / ratio
            } else {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffY
            }
            
        default:
            break
        }
        
        let minSize: CGSize
        let maxSize: CGSize
        let maxClipFrame: CGRect
        if ratio != 0 {
            if ratio >= 1 {
                minSize = CGSize(width: self.minClipSize.height * ratio, height: self.minClipSize.height)
            } else {
                minSize = CGSize(width: self.minClipSize.width, height: self.minClipSize.width / ratio)
            }
            if ratio > self.maxClipFrame.width / self.maxClipFrame.height {
                maxSize = CGSize(width: self.maxClipFrame.width, height: self.maxClipFrame.width / ratio)
            } else {
                maxSize = CGSize(width: self.maxClipFrame.height * ratio, height: self.maxClipFrame.height)
            }
            maxClipFrame = CGRect(origin: CGPoint(x: self.maxClipFrame.minX + (self.maxClipFrame.width-maxSize.width)/2, y: self.maxClipFrame.minY + (self.maxClipFrame.height-maxSize.height)/2), size: maxSize)
        } else {
            minSize = self.minClipSize
            maxSize = self.maxClipFrame.size
            maxClipFrame = self.maxClipFrame
        }
        
        frame.size.width = min(maxSize.width, max(minSize.width, frame.size.width))
        frame.size.height = min(maxSize.height, max(minSize.height, frame.size.height))
        
        frame.origin.x = min(maxClipFrame.maxX-minSize.width, max(frame.origin.x, maxClipFrame.minX))
        frame.origin.y = min(maxClipFrame.maxY-minSize.height, max(frame.origin.y, maxClipFrame.minY))
        
        if (self.panEdge == .topLeft || self.panEdge == .bottomLeft || self.panEdge == .left) && frame.size.width <= minSize.width + CGFloat.ulpOfOne {
            frame.origin.x = originFrame.maxX - minSize.width
        }
        if (self.panEdge == .topLeft || self.panEdge == .topRight || self.panEdge == .top) && frame.size.height <= minSize.height + CGFloat.ulpOfOne {
            frame.origin.y = originFrame.maxY - minSize.height
        }
        
        self.changeClipBoxFrame(newFrame: frame)
    }
    
    func startEditing() {
        self.cleanTimer()
        self.shadowView.alpha = 0
    }
    
    func endEditing() {
        self.moveClipContentToCenter()
    }
    
    func startTimer() {
        self.cleanTimer()
        self.resetTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false, block: { (_) in
            self.cleanTimer()
            self.endEditing()
        })
    }
    
    func cleanTimer() {
        self.resetTimer?.invalidate()
        self.resetTimer = nil
    }
    
    func moveClipContentToCenter() {
        let maxClipRect = self.maxClipFrame
        var clipRect = self.clipBoxFrame
        
        if clipRect.width < CGFloat.ulpOfOne || clipRect.height < CGFloat.ulpOfOne {
            return
        }
        
        let scale = min(maxClipRect.width/clipRect.width, maxClipRect.height/clipRect.height)
        
        let focusPoint = CGPoint(x: clipRect.midX, y: clipRect.midY)
        let midPoint = CGPoint(x: maxClipRect.midX, y: maxClipRect.midY)
        
        clipRect.size.width = ceil(clipRect.width * scale)
        clipRect.size.height = ceil(clipRect.height * scale)
        clipRect.origin.x = maxClipRect.minX + ceil((maxClipRect.width-clipRect.width)/2)
        clipRect.origin.y = maxClipRect.minY + ceil((maxClipRect.height-clipRect.height)/2)
        
        var contentTargetPoint = CGPoint.zero
        contentTargetPoint.x = (focusPoint.x + self.scrollView.contentOffset.x) * scale
        contentTargetPoint.y = (focusPoint.y + self.scrollView.contentOffset.y) * scale
        
        var offset = CGPoint(x: contentTargetPoint.x - midPoint.x, y: contentTargetPoint.y - midPoint.y)
        offset.x = max(-clipRect.minX, offset.x)
        offset.y = max(-clipRect.minY, offset.y)
        UIView.animate(withDuration: 0.3) {
            if scale < 1 - CGFloat.ulpOfOne || scale > 1 + CGFloat.ulpOfOne {
                self.scrollView.zoomScale *= scale
                self.scrollView.zoomScale = min(self.scrollView.maximumZoomScale, self.scrollView.zoomScale)
            }

            if self.scrollView.zoomScale < self.scrollView.maximumZoomScale - CGFloat.ulpOfOne {
                offset.x = min(self.scrollView.contentSize.width-clipRect.maxX, offset.x)
                offset.y = min(self.scrollView.contentSize.height-clipRect.maxY, offset.y)
                self.scrollView.contentOffset = offset
            }
            self.shadowView.alpha = 1
            self.changeClipBoxFrame(newFrame: clipRect)
        }
    }
    
    func clipImage() -> (clipImage: UIImage, editRect: CGRect) {
        let frame = self.convertClipRectToEditImageRect()
        
        let origin = CGPoint(x: -frame.minX, y: -frame.minY)
        UIGraphicsBeginImageContextWithOptions(frame.size, false, self.editImage.scale)
        self.editImage.draw(at: origin)
        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgi = temp?.cgImage else {
            return (self.editImage, CGRect(origin: .zero, size: self.editImage.size))
        }
        let newImage = UIImage(cgImage: cgi, scale: self.editImage.scale, orientation: .up)
        return (newImage, frame)
    }
    
    func convertClipRectToEditImageRect() -> CGRect {
        let imageSize = self.editImage.size
        let contentSize = self.scrollView.contentSize
        let offset = self.scrollView.contentOffset
        let insets = self.scrollView.contentInset
        
        var frame = CGRect.zero
        frame.origin.x = floor((offset.x + insets.left) * (imageSize.width / contentSize.width))
        frame.origin.x = max(0, frame.origin.x)
        
        frame.origin.y = floor((offset.y + insets.top) * (imageSize.height / contentSize.height))
        frame.origin.y = max(0, frame.origin.y)
        
        frame.size.width = ceil(self.clipBoxFrame.width * (imageSize.width / contentSize.width))
        frame.size.width = min(imageSize.width, frame.width)
        
        frame.size.height = ceil(self.clipBoxFrame.height * (imageSize.height / contentSize.height))
        frame.size.height = min(imageSize.height, frame.height)
        
        return frame
    }
}

extension ClipImageViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == self.gridPanGes else {
            return true
        }
        let point = gestureRecognizer.location(in: self.view)
        let frame = self.overlayView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22)
        
        if innerFrame.contains(point) || !outerFrame.contains(point) {
            return false
        }
        return true
    }
    
}

extension ClipImageViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.startEditing()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
        self.startEditing()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
        self.startTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == self.scrollView else {
            return
        }
        if !decelerate {
            self.startTimer()
        }
    }
    
}

extension ClipImageViewController {
    enum ClipPanEdge {
        case none
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}

extension ClipImageViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ClipImageDismissAnimatedTransition()
    }
}

class ZLClipShadowView: UIView {
    
    var clearRect: CGRect = .zero {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        UIColor(white: 0, alpha: 0.7).setFill()
        UIRectFill(rect)
        let tempRect = self.clearRect.intersection(rect)
        UIColor.clear.setFill()
        UIRectFill(tempRect)
    }
    
}

// MARK: 裁剪网格视图
class ZLClipOverlayView: UIView {
    
    static let cornerLineWidth: CGFloat = 3
    
    var cornerBoldLines: [UIView] = []
    
    var velLines: [UIView] = []
    
    var horLines: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.clipsToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(1)

        context?.beginPath()
        var width: CGFloat = 3
        for _ in 0..<4 {
            context?.move(to: CGPoint(x: rect.origin.x+width, y: rect.origin.y+3))
            context?.addLine(to: CGPoint(x: rect.origin.x+width, y: rect.origin.y+rect.height-3))
            width += (rect.size.width - 6) / 3
        }

        var height: CGFloat = 3
        for _ in 0..<4 {
            context?.move(to: CGPoint(x: rect.origin.x+3, y: rect.origin.y+height))
            context?.addLine(to: CGPoint(x: rect.origin.x+rect.width-3, y: rect.origin.y+height))
            height += (rect.size.height - 6) / 3
        }

        context?.strokePath()

        context?.setLineWidth(3)

        let boldLineLength: CGFloat = 20
        // 左上
        context?.move(to: CGPoint(x: 0, y: 1.5))
        context?.addLine(to: CGPoint(x: boldLineLength, y: 1.5))

        context?.move(to: CGPoint(x: 1.5, y: 0))
        context?.addLine(to: CGPoint(x: 1.5, y: boldLineLength))

        // 右上
        context?.move(to: CGPoint(x: rect.width-boldLineLength, y: 1.5))
        context?.addLine(to: CGPoint(x: rect.width, y: 1.5))

        context?.move(to: CGPoint(x: rect.width-1.5, y: 0))
        context?.addLine(to: CGPoint(x: rect.width-1.5, y: boldLineLength))

        // 左下
        context?.move(to: CGPoint(x: 1.5, y: rect.height-boldLineLength))
        context?.addLine(to: CGPoint(x: 1.5, y: rect.height))

        context?.move(to: CGPoint(x: 0, y: rect.height-1.5))
        context?.addLine(to: CGPoint(x: boldLineLength, y: rect.height-1.5))

        // 右下
        context?.move(to: CGPoint(x: rect.width-boldLineLength, y: rect.height-1.5))
        context?.addLine(to: CGPoint(x: rect.width, y: rect.height-1.5))

        context?.move(to: CGPoint(x: rect.width-1.5, y: rect.height-boldLineLength))
        context?.addLine(to: CGPoint(x: rect.width-1.5, y: rect.height))

        context?.strokePath()

        context?.setShadow(offset: CGSize(width: 1, height: 1), blur: 0)
    }
}

public class ZLImageClipRatio: NSObject {
    
    let title: String
    
    let whRatio: CGFloat
    
    @objc public init(title: String, whRatio: CGFloat) {
        self.title = title
        self.whRatio = whRatio
    }
    
}
