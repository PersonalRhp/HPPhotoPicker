//
// ViewController.swift
// Ouyu
//
// Created by raohongping on 2021/7/15.
//
//

import UIKit
import RSKImageCropper
import PhotoPicker

class ViewController: UIViewController, PhotoPickerMangerDelegate, RSKImageCropViewControllerDataSource {
    
    var selectPhotoCount = 0
    var selectPhotos: [HPPhotoModel]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
    
        let button = UIButton.init(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        button.addTarget(self, action: #selector(showPhotoPicker), for: .touchUpInside)
        button.backgroundColor = .red
        view.addSubview(button)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @objc func showPhotoPicker() {
        var config = PhotoConfiguration()
        config.animateStyle = .present
        config.mediaType = .imageAndVideo
        config.numberOfItemsInRow = 4
        config.cameraPlaceholderType = .realTimePreview
        config.ascending = false
        config.image.maxNumberOfItems = 3
        config.image.singlePicture = false
        config.video.maxNumberOfItems = 2
        config.video.maximumTimeLimit = 30
        config.video.minimumTimeLimit = 3
        config.video.singleVideo = true
        config.image.customCropDataSource = self
        config.image.cropMode = .custom
        config.selectPhotos = selectPhotos
        PhotoPickerManger.pickerPhoto(config: config, delegate: self)
    }
    
    func photoPickerEnterMangerDidFinish(selectPhotos: [HPPhotoModel]) {
        
        self.selectPhotos = selectPhotos
        selectPhotoCount += selectPhotos.count
        
        if selectPhotos.isEmpty {
            return
        }
        
        let iamgeView = UIImageView.init(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        iamgeView.contentMode = .scaleAspectFill
        iamgeView.layer.masksToBounds = true
        view.addSubview(iamgeView)
        iamgeView.image = self.selectPhotos?[0].editImage ?? selectPhotos[0].compressImage
    }
    
    public func imageCropViewControllerCustomMaskRect(_ controller: RSKImageCropViewController) -> CGRect {
        let clipW: CGFloat = UIScreen.main.bounds.size.width - CGFloat(30)*CGFloat(2)
        
        let cropSize = CGSize.init(width: clipW, height: clipW*CGFloat(4.0 / 3.0))
        return CGRect(x: (self.view.width - cropSize.width) / 2.0, y: (self.view.height - cropSize.height) / 2, width: cropSize.width, height: cropSize.height)
    }
    
    public func imageCropViewControllerCustomMaskPath(_ controller: RSKImageCropViewController) -> UIBezierPath {
        let clipW: CGFloat = UIScreen.main.bounds.size.width - CGFloat(30)*CGFloat(2)
        let cropSize = CGSize.init(width: clipW, height: clipW*CGFloat(4.0 / 3.0))
        let path = UIBezierPath(roundedRect: CGRect(x: (self.view.width - cropSize.width) / 2.0, y: (self.view.height - cropSize.height) / 2, width: cropSize.width, height: cropSize.height), cornerRadius: 0)
        return path
    }
    
    public func imageCropViewControllerCustomMovementRect(_ controller: RSKImageCropViewController) -> CGRect {
        let clipW: CGFloat = UIScreen.main.bounds.size.width - CGFloat(30)*CGFloat(2)
        let cropSize = CGSize.init(width: clipW, height: clipW*CGFloat(4.0 / 3.0))
        return CGRect(x: (self.view.width - cropSize.width) / 2.0, y: (self.view.width - cropSize.height) / 2, width: cropSize.width, height: cropSize.height)
    }
}

