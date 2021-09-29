//
// PhotoPickerCell.swift
// Ouyu
//
// Created by raohongping on 2021/7/27.
// 
//

/*
 * @功能描述：专辑列表cell
 * @创建时间：2021/7/27
 * @创建人：饶鸿平
 */

import UIKit
import Photos

protocol PhotoPickerCellDelegate: NSObjectProtocol {
    // 更新选中的照片
    func photoPickerCellUpdatePhoto(cell: PhotoPickerCell)
}

class PhotoPickerCell: UICollectionViewCell {
    
    var config: PhotoConfiguration?
    weak var delegate: PhotoPickerCellDelegate?
    
    var photoModel: HPPhotoModel! {
        didSet {
            
            self.selectButton.isSelected = photoModel.isSelected
            selectButton.setImage(config?.customUI.normalIcon, for: .normal)
            selectButton.setImage(config?.customUI.selectedIcon, for: .selected)
            
            if photoModel.type == .video {
                self.selectButton.isHidden = self.config?.video.singleVideo ?? false
            } else {
                self.selectButton.isHidden = self.config?.image.singlePicture ?? false
            }
    
            self.fetchSmallImage()
            
            self.customMaskView.isHidden = photoModel.isCanSelected
                        
            self.durationLabel.isHidden = photoModel.type != .video
            self.videoTagImageView.isHidden = photoModel.type != .video
            self.durationLabel.text = photoModel.duration
        }
    }
    
    private var imageIdentifier = ""
    private var smallImageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        }
        
        contentView.addSubview(selectButton)
        
        selectButton.snp.makeConstraints { make in
            make.top.equalTo(self).offset(0)
            make.trailing.equalTo(self).offset(0)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        contentView.addSubview(videoTagImageView)
        
        videoTagImageView.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(8)
            make.bottom.equalTo(contentView).offset(-8)
        }
        
        contentView.addSubview(durationLabel)
        
        durationLabel.snp.makeConstraints { make in
            make.bottom.trailing.equalTo(contentView).offset(-8)
        }
        
        contentView.addSubview(self.customMaskView)
        
        customMaskView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        }
        
        videoTagImageView.isHidden = true
        durationLabel.isHidden = true
        customMaskView.isHidden = true
    }
    
    func fetchSmallImage() {
        
        if let editImage = self.photoModel.editImage {
            self.imageView.image = editImage
            return
        }
        
        if let image = self.photoModel.thumbnailImage {
            self.imageView.image = image
            return
        }
        
        let scale = UIScreen.main.scale
        let size = CGSize(width: self.width * scale, height: self.height * scale)
        
        if self.smallImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.smallImageRequestID)
        }
        
        self.imageIdentifier = self.photoModel.identifier
        self.imageView.image = nil
        self.smallImageRequestID = PhotoManger.fastFetchThumbnailImage(for: self.photoModel.asset, size: size, completion: { [weak self] image, isDegraded in
            if self?.imageIdentifier == self?.photoModel.identifier {
                self?.imageView.image = image
                self?.photoModel.thumbnailImage = image
            }
            if !isDegraded {
                self?.smallImageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    // MARK: Action
    @objc func selectButtonAction() {
        self.delegate?.photoPickerCellUpdatePhoto(cell: self)
    }
    
    // MARK: Lazy
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var videoTagImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = ResourcesTool.getBundleImg(named: "photoPicker_video_icon")
        return imageView
    }()
     
    lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .pingFangSCRegular(size: 12)
        return label
    }()
    
    lazy var selectButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(selectButtonAction), for: .touchUpInside)
        return button
    }()
    
    lazy var customMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = .hexColor("000000", alpha: 0.6)
        return view
    }()
}
