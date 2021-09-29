//
// PhotoPickerNavitionView.swift
// Ouyu
//
// Created by raohongping on 2021/7/28.
// 
//

/*
 * @功能描述：相册导航栏
 * @创建时间：2021/7/28
 * @创建人：饶鸿平
 */

import UIKit

protocol PhotoPickerNavitionViewDelegate: NSObjectProtocol {
    // 选中相册
    func photoPickerNavitionViewSelectAlbum(view: PhotoPickerNavitionView)
    // 取消
    func photoPickerNavitionViewCancel(view: PhotoPickerNavitionView)
}

class PhotoPickerNavitionView: UIView {
    
    var config: PhotoConfiguration
    
    weak var delegate: PhotoPickerNavitionViewDelegate?
    
    var title: String {
        didSet {
            self.albumTitleLabel.text = title
            self.refreshTitleViewFrame()
        }
    }
    
    var navBlurView: UIVisualEffectView?
    
    var titleBgControl: UIControl!
    
    var albumTitleLabel: UILabel!
    
    var arrow: UIImageView!
    
    var cancelBtn: UIButton!
    
    init(title: String, config: PhotoConfiguration) {
        self.title = title
        self.config = config
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            insets = self.safeAreaInsets
        }
        
        self.refreshTitleViewFrame()
        let cancelBtnW = config.customUI.cancelButtonTitle.boundingRect(font: config.customUI.navBarTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)).width
        self.cancelBtn.frame = CGRect(x: insets.left+20, y: insets.top, width: cancelBtnW, height: 44)
    }
    
    func refreshTitleViewFrame() {
        var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            insets = self.safeAreaInsets
        }
        
        self.navBlurView?.frame = self.bounds
        
        let albumTitleW = min(self.bounds.width / 2, self.title.boundingRect(font: config.customUI.navBarTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)).width)
        let titleBgControlW = albumTitleW + 20 + 20
        
        UIView.animate(withDuration: 0.25) {
            self.titleBgControl.frame = CGRect(x: (self.frame.width-titleBgControlW)/2, y: insets.top+(44-28)/2, width: titleBgControlW, height: 28)
            self.albumTitleLabel.frame = CGRect(x: 10, y: 0, width: albumTitleW, height: 28)
            self.arrow.frame = CGRect(x: self.albumTitleLabel.frame.maxX+5, y: (28-20)/2.0, width: 20, height: 20)
        }
    }
    
    func setupUI() {
        self.backgroundColor = config.customUI.navBarBgColor
        self.titleBgControl = UIControl()
        self.titleBgControl.backgroundColor = config.customUI.navBarTitleBgColor
        self.titleBgControl.layer.cornerRadius = 28 / 2
        self.titleBgControl.layer.masksToBounds = true
        self.titleBgControl.addTarget(self, action: #selector(titleBgControlClick), for: .touchUpInside)
        self.addSubview(titleBgControl)
        
        self.albumTitleLabel = UILabel()
        self.albumTitleLabel.textColor = config.customUI.navBarTitleColor
        self.albumTitleLabel.font = config.customUI.navBarTitleFont
        self.albumTitleLabel.text = self.title
        self.albumTitleLabel.textAlignment = .center
        self.titleBgControl.addSubview(self.albumTitleLabel)
        
        self.arrow = UIImageView(image: config.customUI.navBarArrowIcon)
        self.arrow.clipsToBounds = true
        self.arrow.contentMode = .scaleAspectFill
        self.titleBgControl.addSubview(self.arrow)
        
        self.cancelBtn = UIButton(type: .custom)
        self.cancelBtn.setImage(config.animateStyle == .present ? config.customUI.navBarCloseIcon : config.customUI.navBarBackIcon, for: .normal)
        self.cancelBtn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        self.addSubview(self.cancelBtn)
    }
    
    @objc func titleBgControlClick() {
        self.delegate?.photoPickerNavitionViewSelectAlbum(view: self)
        if self.arrow.transform == .identity {
            UIView.animate(withDuration: 0.25) {
                self.arrow.transform = CGAffineTransform(rotationAngle: .pi)
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.arrow.transform = .identity
            }
        }
    }
    
    @objc func cancelBtnClick() {
        self.delegate?.photoPickerNavitionViewCancel(view: self)
    }
    
    func reset() {
        UIView.animate(withDuration: 0.25) {
            self.arrow.transform = .identity
        }
    }
    
}
