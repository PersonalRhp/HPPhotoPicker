//
// PhotoPickerCameraCell.swift
// Ouyu
//
// Created by raohongping on 2021/7/29.
// 
//

/*
 * @功能描述：相机占位cell
 * @创建时间：2021/7/29
 * @创建人：饶鸿平
 */

import UIKit
import AVFoundation

class PhotoPickerCameraCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    var session: AVCaptureSession?
    
    var videoInput: AVCaptureDeviceInput?
    
    var photoOutput: AVCapturePhotoOutput?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    deinit {
        self.session?.stopRunning()
        self.session = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.layer.masksToBounds = true
        self.imageView = UIImageView(image: ResourcesTool.getBundleImg(named: "photoPicker_add_icon"))
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
        
        self.imageView.snp.makeConstraints { make in
            make.center.equalTo(self.contentView)
        }
    }
    
    var isCapture: Bool = false {
        didSet {
            if isCapture {
                startCapture()
            } else {
                self.contentView.backgroundColor = .gray
            }
        }
    }
    
    var isCanTakePhoto: Bool = true {
        didSet {
            if isCanTakePhoto {
                self.customMaskView.removeFromSuperview()
                
            } else {
                self.contentView.addSubview(self.customMaskView)
                
                self.customMaskView.snp.makeConstraints { make in
                    make.edges.equalTo(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
                }
            }
        }
    }
    
    func startCapture() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) || status == .denied {
            return
        }
        
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.setupSession()
                    }
                }
            }
        } else {
            
            self.setupSession()
        }
    }
    
    private func setupSession() {
        guard self.session == nil, (self.session?.isRunning ?? false) == false else {
            return
        }
        self.session?.stopRunning()
        if let input = self.videoInput {
            self.session?.removeInput(input)
        }
        if let output = self.photoOutput {
            self.session?.removeOutput(output)
        }
        self.session = nil
        self.previewLayer?.removeFromSuperlayer()
        self.previewLayer = nil
        
        guard let camera = self.backCamera() else {
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        self.videoInput = input
        self.photoOutput = AVCapturePhotoOutput()
        
        self.session = AVCaptureSession()
        
        if self.session?.canAddInput(input) == true {
            self.session?.addInput(input)
        }
        if self.session?.canAddOutput(self.photoOutput!) == true {
            self.session?.addOutput(self.photoOutput!)
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session!)
        self.contentView.layer.masksToBounds = true
        self.previewLayer?.frame = self.contentView.layer.bounds
        self.previewLayer?.videoGravity = .resizeAspectFill
        self.contentView.layer.insertSublayer(self.previewLayer!, at: 0)
        
        DispatchQueue.global().async {
            self.session?.startRunning()
        }
        
    }
    
    private func backCamera() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices
        for device in devices where device.position == .back {
            return device
        }
        return nil
    }
    
    // MARK: Lazy
    lazy var customMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = .hexColor("000000", alpha: 0.6)
        return view
    }()
}
