//
// PhotoPickerManger.swift
// Ouyu
//
// Created by raohongping on 2021/7/27.
//
//

/*
 * @功能描述：相册进入管理类
 * @创建时间：2021/7/27
 * @创建人：饶鸿平
 */

import UIKit
import Photos

public protocol PhotoPickerMangerDelegate: NSObjectProtocol {
    // 选中照片完成
    func photoPickerEnterMangerDidFinish(selectPhotos: [HPPhotoModel])
}

public typealias NoAuthorizedHandler = (_ status: PHAuthorizationStatus?) -> Void

public class PhotoPickerManger: NSObject {
    
    weak var delegate: PhotoPickerMangerDelegate?
    
    /// Key Window
    public static var keyWindow: UIWindow? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        } else {
            window = UIApplication.shared.keyWindow
        }
        
        return window
    }
    
    private static var enterManger: PhotoPickerManger?
    
    /// 选择照片
    /// - Parameters:
    ///   - config: 配置
    ///   - delegate: 代理控制器
    ///   - noAuthorizedHandler: 相册没有全部授权回调，默认不需要传noAuthorizedHandler，
    ///   统一给相册无权限提示弹窗，需要单独处理没权限的场景就传
    public static func pickerPhoto(config: PhotoConfiguration, delegate: PhotoPickerMangerDelegate, noAuthorizedHandler: NoAuthorizedHandler? = nil) {
        
        enterManger = PhotoPickerManger()
        enterManger?.delegate = delegate
        
        PhotoPickerManger.authorize { status in
            if #available(iOS 14, *) {
                if status == .authorized {
                    // 有权限, 直接进入选择页面
                    PhotoPickerManger.pushPickerPhotoVC(config: config, delegate: delegate)
                } else if status == .limited {
                    // iOS14有部分权限，需要特殊处理就给回调，默认直接进入选择页面
                    if let handler = noAuthorizedHandler {
                        handler(status)
                    } else {
                        PhotoPickerManger.pushPickerPhotoVC(config: config, delegate: delegate)
                    }
                } else {
                    // 没有权限，需要特殊处理就给回调，默认弹出权限引导弹窗
                    if let handler = noAuthorizedHandler {
                        handler(status)
                    } else {
                        PhotoPickerManger.showPhotoLibraryAlert()
                    }
                }
            } else {
                guard status == .authorized else {
                    PhotoPickerManger.showPhotoLibraryAlert()
                    return
                }
                
                PhotoPickerManger.pushPickerPhotoVC(config: config, delegate: delegate)
            }
        }
    }
    
    /// 跳转照片选择器
    /// - Parameters:
    ///   - config: 配置
    ///   - delegateVC: 代理控制器
    private static func pushPickerPhotoVC(config: PhotoConfiguration, delegate: PhotoPickerMangerDelegate) {
        
        if config.cameraPlaceholderType == .realTimePreview {
            authorizeCamera { status in
                if status == .authorized {
                    self.push(config: config, delegate: delegate)
                }
            }
            
            return
        }
        
        self.push(config: config, delegate: delegate)
        
    }
    
    private static func push(config: PhotoConfiguration, delegate: PhotoPickerMangerDelegate) {
        guard let manger = enterManger else {
            return
        }
    
        let photoPickerVC = PhotoPickerVC.init(config: config, delegate: manger)
        
        if config.animateStyle == .push {
            getCurrentViewController()?.navigationController?.pushViewController(photoPickerVC)
        } else if config.animateStyle == .present {
            let navi = UINavigationController.init(rootViewController: photoPickerVC)
            navi.modalPresentationStyle = .fullScreen
            getCurrentViewController()?.present(navi, animated: true, completion: nil)
        }
    }
}

// MARK: 相册和相机的权限
extension PhotoPickerManger {
    // 用户是否开启相册权限
    public static func authorize(authorizeClouse:@escaping (PHAuthorizationStatus) -> Void) {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
            if status == .authorized {
                authorizeClouse(status)
            } else if status == .notDetermined { // 未授权，请求授权
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { state in
                    DispatchQueue.main.async(execute: {
                        authorizeClouse(state)
                    })
                }
            } else {
                authorizeClouse(status)
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .authorized {
                authorizeClouse(status)
            } else if status == .notDetermined { // 未授权，请求授权
                PHPhotoLibrary.requestAuthorization({ (state) in
                    DispatchQueue.main.async(execute: {
                        authorizeClouse(state)
                    })
                })
            } else {
                authorizeClouse(status)
            }
        }
    }
    
    // 用户是否开启相机权限
    public static func authorizeCamera(authorizeClouse: @escaping (AVAuthorizationStatus) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if status == .authorized {
            authorizeClouse(status)
        } else if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                DispatchQueue.main.async(execute: {
                    if granted {  // 允许
                        authorizeClouse(.authorized)
                    }
                })
            })
        } else {
            showCameraAlert()
        }
    }
    
    /// 相册无权限提示弹窗
    private static func showPhotoLibraryAlert() {
        DispatchQueue.main.async {
            
            let alertController = UIAlertController(title: "相册访问被阻止", message: "请进入手机设置>隐私>照片，允许访缘分餐厅问您的照片", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: "设置", style: .default, handler: {
                action in
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            getCurrentViewController()?.present(alertController, animated: true, completion: nil)
            
            //            var config = AlertConfig.default
            //            config.actionButtonAttributed = [NSAttributedString(string: "取消", attributes: AlertConfig.defaultActionButtonAttribute),
            //                                              NSAttributedString(string: "确定", attributes: AlertConfig.defaultActionButtonAttribute)]
            
            //            AlertViewController(config: config, content: "请进入手机设置>隐私>照片，允许访问您的照片").show().completion { (idx) in
            //                switch idx {
            //                case 1:
            //                    if let url = URL(string: UIApplication.openSettingsURLString),
            //                       UIApplication.shared.canOpenURL(url) {
            //                        UIApplication.shared.open(url)
            //                    }
            //                default:
            //                    break
            //                }
            //            }
        }
    }
    
    /// 相机无权限提示弹窗
    private static func showCameraAlert() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "相机访问被阻止", message: "请进入手机设置>隐私>相机，允许访缘分餐厅问您的相机", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: "设置", style: .default, handler: {
                action in
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            getCurrentViewController()?.present(alertController, animated: true, completion: nil)
            
            //            var config = AlertConfig.default
            //            config.actionButtonAttributed = [NSAttributedString(string: "取消", attributes: AlertConfig.defaultActionButtonAttribute),
            //                                              NSAttributedString(string: "确定", attributes: AlertConfig.defaultActionButtonAttribute)]
            //
            //            AlertViewController(config: config, content: "相册需要实时预览，点击“设置”，允许访问您的相机").show().completion { (idx) in
            //                switch idx {
            //                case 1:
            //                    if let url = URL(string: UIApplication.openSettingsURLString),
            //                       UIApplication.shared.canOpenURL(url) {
            //                        UIApplication.shared.open(url)
            //                    }
            //                default:
            //                    break
            //                }
            //            }
        }
    }

    // MARK: - Returns: 当前控制器
    public static func getCurrentViewController(base: UIViewController? = keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getCurrentViewController(base: nav.visibleViewController)
        } else if let tabBarVC = base as? UITabBarController, let selected = tabBarVC.selectedViewController {
            return getCurrentViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getCurrentViewController(base: presented)
        }
        return base
    }
}
 
// MARK: PhotoPickerVC代理
extension PhotoPickerManger: PhotoPickerVCDelegate {
    // 选择照片完成
    func photoPickerDidFinish(selectPhotos: [HPPhotoModel]) {
        PhotoPickerManger.enterManger = nil
        self.delegate?.photoPickerEnterMangerDidFinish(selectPhotos: selectPhotos)
    }
    
    // 取消选择
    func photoPickerCancel() {
        PhotoPickerManger.enterManger = nil
    }
}


