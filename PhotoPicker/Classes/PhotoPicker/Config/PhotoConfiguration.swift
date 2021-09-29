//
// PhotoConfiguration.swift
// Ouyu
//
// Created by raohongping on 2021/7/26.
// 
//

/**
 * @功能描述：相册配置
 * @创建时间：2021/7/26
 * @创建人：饶鸿平
 */

import Photos
import RSKImageCropper

public enum MediaType {
    case image // 图片
    case video // 视频
    case imageAndVideo // 图片和视频
}

public enum CameraPlaceholderType {
    case none // 无占位
    case placeholderImage // 占位图片
    case realTimePreview // 实时预览
}

public enum AnimateStyle {
    case push
    case present
}

public enum ImageCropMode: Int {
    case circle // 圆
    case square // 正方形
    case custom // 自定义裁剪
}

import UIKit

public struct PhotoConfiguration {
    /// 媒体类型,默认图片
    public var mediaType = MediaType.image
    /// 相册占位
    public var cameraPlaceholderType = CameraPlaceholderType.none
    /// 图片配置
    public var image = Image()
    /// 视频配置
    public var video = Video()
    /// 记录选中的图片
    public var selectPhotos: [HPPhotoModel]?
    /// 进入动画类型
    public var animateStyle = AnimateStyle.push
    /// 创建时间正序排列
    public var ascending = false
    
    // MARK: UI层
    public var customUI = CustomUI()
    /// 每列展示数量，默认为4
    public var numberOfItemsInRow: Int = 4
    /// 预览是否显示状态栏
    public var showStatusBarInPreviewInterface = false
    /// 状态栏类型
    public var statusBarStyle: UIStatusBarStyle = .lightContent
    /// 在预览大图界面底部显示选中的照片。 默认为真
    public var showSelectedPhotoPreview = true
    
    // MARK: 暂未实现，评估后期需求，敬请期待
    /// 是否可以同时选择照片和视频。 默认为假
    /// 如果设置为true，则能同时选择视频或者图片
    var allowMixSelect = false
    
    public init() {
        
    }
}

// MARK: 图片配置
public struct Image {
    /** 是否支持图片单选，默认是false，如果是ture只允许选择一张图片（如果 mediaType = imageAndVideo 或者 imageOrVideo 此属性无效） */
    public var singlePicture = false
    /// 最大选择照片数量, 默认为9，0相册不可选
    /// 需要记录选择数量传 最大选择数量 - 选中数量
    public var maxNumberOfItems = 9
    /// 允许编辑图片
    public var allowEditImage = true
    /// 裁剪模式， 默认圆形
    /// 自定义裁剪通过customCropDataSource实现
    public var cropMode: ImageCropMode = .circle
    /// 自定义裁剪数据源
    public var customCropDataSource: RSKImageCropViewControllerDataSource? {
        didSet {
            cropMode = .custom
        }
    }
}

// MARK: 视频配置
public struct Video {
    /** 是否支持视频单选 默认是false，如果是ture只允许选择一个视频（如果 mediaType = imageAndVideo 此属性无效） */
    public var singleVideo = false
    /// 最大选择视频数量，为0相册不可选
    /// 需要记录选择数量传 最大选择数量 - 选中数量
    public var maxNumberOfItems = 1
    /// 视频最长时间限制，默认60s
    public var maximumTimeLimit: TimeInterval = 60.0
    /// 视频最短时间限制，默认3s
    public var minimumTimeLimit: TimeInterval = 3.0
    /// 允许编辑视频, 暂未实现，评估后期需求，敬请期待
    var allowEditVideo = false
}

/// 自定义UI
public struct CustomUI {
    /// 主题颜色
    public var themeColor = UIColor.hexColor("A665FF")
    /// 主题渐变色，有的UI色彩运用太优秀，需要用渐变色
    public var themeGradientColor: [CGColor]?
    
    /// 选择相册列表背景颜色
    public var pickerViewBgColor = UIColor.white
    
    /// 选中图标
    public var selectedIcon = ResourcesTool.getBundleImg(named: "photoPicker_selected_icon")
    /// 非选中图标
    public var normalIcon = ResourcesTool.getBundleImg(named: "photoPicker_normal_icon")
    
    /// 导航条背景颜色颜色
    public var navBarBgColor = UIColor.white
    /// 导航标题颜色
    public var navBarTitleColor = UIColor.hexColor("111118")
    /// 导航标题背景颜色
    public var navBarTitleBgColor = UIColor.hexColor("F8F9FC")
    /// 导航栏字体
    public var navBarTitleFont = UIFont.pingFangSCMedium(size: 14)
    /// 导航栏相册指示图标
    public var navBarArrowIcon = ResourcesTool.getBundleImg(named: "photoPicker_down_icon")
    /// 导航栏关闭图标
    public var navBarCloseIcon = ResourcesTool.getBundleImg(named: "photoPicker_close_icon")
    /// 导航栏返回图标
    public var navBarBackIcon = ResourcesTool.getBundleImg(named: "photoPreview_back_icon")
    
    /// 导航取消按钮标题颜色
    public var cancelButtonTitleColor = UIColor.hexColor("111118")
    /// 导航取消按钮字体
    public var cancelButtonTitleFont = UIFont.pingFangSCRegular(size: 14)
    
    /// 底部背景颜色
    public var bottomViewBgColor = UIColor.white
    /// 底部预览按钮标题颜色
    public var previewButtonTitleColor = UIColor.hexColor("111118")
    /// 底部完成按钮不可点击标题颜色
    public var previewButtonUnEnableTitleColor = UIColor.gray
    /// 底部预览按钮字体
    public var previewButtonTitleFont = UIFont.pingFangSCRegular(size: 15)
    /// 底部完成按钮标题颜色
    public var finishButtonTitleColor = UIColor.white
    /// 底部完成按钮不可点击标题颜色
    public var finishButtonUnEnableTitleColor = UIColor.white
    /// 底部完成按钮不可点击背景颜色
    public var finishButtonUnEnableBgColor = UIColor.gray
    /// 底部完成按钮字体
    public var finishButtonTitleFont = UIFont.pingFangSCRegular(size: 15)
    
    /// 底部编辑按钮标题颜色
    public var editButtonTitleColor = UIColor.hexColor("111118")
    /// 底部编辑按钮字体
    public var editButtonTitleFont = UIFont.pingFangSCRegular(size: 15)
    
    // 相册视图背景色
    public var albumBgColor = UIColor.hexColor("000000").withAlphaComponent(0.4)
    // 相册列表背景色
    public var albumListViewBgColor = UIColor.hexColor("FEFFFE")
    // 相册列表分割线颜色
    public var albumListSplitLineColor = UIColor.hexColor("F8F9FC")
    // 相册cell标题颜色
    public var albumListViewTitleColor = UIColor.hexColor("3C3647")
    // 相册cell字体
    public var albumListViewTitleFont = UIFont.pingFangSCRegular(size: 14)
    // 相册列表选中icon
    public var albumListViewSelectedIcon: UIImage?
    
    // 预览视图背景色
    public var previewBgColor = UIColor.white
    public var previewNormalIcon = ResourcesTool.getBundleImg(named: "photoPreview_normal_icon")
    
    /// 文案
    public var cancelButtonTitle = "取消"
    public var finishButtonTitle = "完成"
    public var previewButtonTitle = "预览"
    public var editButtonTitle = "编辑"
}
