//
// AlbumListCell.swift
// Ouyu
//
// Created by raohongping on 2021/7/28.
// 
//

/*
 * @功能描述：相册专辑cell
 * @创建时间：2021/7/28
 * @创建人：饶鸿平
 */

import UIKit
import Photos

class AlbumListCell: UITableViewCell {
    
    var customConfig: CustomUI? = CustomUI() {
        didSet {
            titleLabel.font = customConfig?.albumListViewTitleFont
            titleLabel.textColor = customConfig?.albumListViewTitleColor
            
            if let selectedIcon = customConfig?.albumListViewSelectedIcon {
                selectImageView.image = selectedIcon
            }
        }
    }

    private var smallImageRequestID: PHImageRequestID = PHInvalidImageRequestID

    var isSelectIndex: Bool = false {
        didSet {
            selectImageView.isHidden = !isSelectIndex
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.backgroundColor = UIColor.clear
        contentView.addSubview(albmImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(selectImageView)
        
        albmImageView.snp.makeConstraints { (make) in
            make.left.equalTo(contentView.snp.left)
            make.top.bottom.equalTo(contentView)
            make.size.equalTo(CGSize(width: AlbumListView.rowH, height: AlbumListView.rowH))
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(albmImageView.snp.right).offset(16)
            make.centerY.equalTo(contentView.snp.centerY)
        }
        
        selectImageView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 16, height: 16))
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-19)
        }
    }
    
    var album: AlbumListModel! {
        didSet {
            titleLabel.text = "\(album.title) (\(album.count))"
            guard let asset = album.result.firstObject else { return }
            
            if self.smallImageRequestID > PHInvalidImageRequestID {
                PHImageManager.default().cancelImageRequest(self.smallImageRequestID)
            }
            
            let scale = UIScreen.main.scale
            let size = CGSize(width: self.width * scale, height: self.height * scale)
            self.smallImageRequestID = PhotoManger.fastFetchThumbnailImage(for: asset, size: size, completion: { [weak self] image, isDegraded in
                self?.albmImageView.image = image
                
                if !isDegraded {
                    self?.smallImageRequestID = PHInvalidImageRequestID
                }
            })
        }
    }
    
    // MARK: Lazy
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = NSTextAlignment.left
        return label
    }()
    
    lazy var albmImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = ContentMode.scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    lazy var selectImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = ContentMode.scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
}
