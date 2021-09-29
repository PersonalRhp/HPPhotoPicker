//
// PhotoPickerBottomView.swift
// Ouyu
//
// Created by raohongping on 2021/7/28.
// 
//

/*
 * @功能描述：相册底部栏
 * @创建时间：2021/7/28
 * @创建人：饶鸿平
 */

import UIKit

protocol PhotoPickerBottomViewDelegate: NSObjectProtocol {
    // 预览
    func photoPickerBottomViewPreview(view: PhotoPickerBottomView)
    // 完成
    func photoPickerBottomViewFinish(view: PhotoPickerBottomView)
}

class PhotoPickerBottomView: UIView {
    
    var customConfig: CustomUI

    var finishCount: Int = 0 {
        didSet {
            updateUI()
        }
    }
    
    weak var delegate: PhotoPickerBottomViewDelegate?
    
    init(frame: CGRect, customConfig: CustomUI) {
        self.customConfig = customConfig
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lazy
    lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = customConfig.bottomViewBgColor
        return view
    }()
    
    lazy var previewButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(customConfig.previewButtonTitle, for: .normal)
        button.titleLabel?.font = customConfig.navBarTitleFont
        return button
    }()
    
    lazy var finishButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = customConfig.finishButtonTitleFont
        button.setTitleColor(customConfig.finishButtonTitleColor, for: .normal)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.setTitle(customConfig.finishButtonTitle, for: .normal)
        return button
    }()
}

extension PhotoPickerBottomView {
    
    func setupUI() {
        self.backgroundColor = customConfig.bottomViewBgColor
        addSubview(bgView)
        bgView.addSubview(previewButton)
        previewButton.addTarget(self, action: #selector(previewAction), for: .touchUpInside)
        bgView.addSubview(finishButton)
        finishButton.addTarget(self, action: #selector(finishAction), for: .touchUpInside)
        
        bgView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-kSafeAreaInsets.bottom)
        }
        
        previewButton.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(8)
            $0.width.equalTo(60)
        }
        
        finishButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-8)
            $0.size.equalTo(CGSize(width: 78, height: 32))
        }
        
        updateUI()
    }
    
    func updateUI() {
        let title = finishCount > 0 ? customConfig.finishButtonTitle + "(\(finishCount))" : customConfig.finishButtonTitle
        
        if finishCount == 0 {
            finishButton.removeGradientLayer()
            finishButton.backgroundColor = customConfig.finishButtonUnEnableBgColor
            finishButton.setTitleColor(customConfig.finishButtonUnEnableTitleColor, for: .normal)
            finishButton.isUserInteractionEnabled = false
            previewButton.setTitleColor(customConfig.previewButtonUnEnableTitleColor, for: .normal)
        } else {
            if let themeGradientColor = customConfig.themeGradientColor {
                finishButton.gradientColor(CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5), themeGradientColor)
            } else {
                finishButton.backgroundColor = customConfig.themeColor
            }
            finishButton.setTitleColor(customConfig.finishButtonTitleColor, for: .normal)
            finishButton.isUserInteractionEnabled = true
            previewButton.setTitleColor(customConfig.previewButtonTitleColor, for: .normal)
        }
        
        finishButton.setTitle(title, for: .normal)
    }
}

extension PhotoPickerBottomView {
    
    @objc func previewAction() {
        delegate?.photoPickerBottomViewPreview(view: self)
    }
    
    @objc func finishAction() {
        delegate?.photoPickerBottomViewFinish(view: self)
    }
}
