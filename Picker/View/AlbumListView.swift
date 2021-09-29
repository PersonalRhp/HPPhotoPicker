//
// AlbumListView.swift
// Ouyu
//
// Created by raohongping on 2021/7/26.
//
//

/**
 * @功能描述：专辑列表
 * @创建时间：2021/7/26
 * @创建人：饶鸿平
 */

import UIKit
import Photos

class AlbumListView: UIView {

    static let rowH: CGFloat = 54
    
    var config: PhotoConfiguration?
    var selectedAlbum: AlbumListModel?
    
    var tableBgView: UIView!
    
    var tableView: UITableView!
    
    var albumListModels: [AlbumListModel] = []
    
    var customConfig: CustomUI
    
    var selectAlbumBlock: ( (AlbumListModel) -> Void )?
    
    var hideBlock: ( () -> Void )?
    
    var orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
    
    init(selectedAlbum: AlbumListModel?, customConfig: CustomUI) {
        self.selectedAlbum = selectedAlbum
        self.customConfig = customConfig
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let currOri = UIApplication.shared.statusBarOrientation
        
        guard currOri != self.orientation else {
            return
        }
        self.orientation = currOri
        
        guard !self.isHidden else {
            return
        }
        
        let bgFrame = self.calculateBgViewBounds()
        
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.frame.width, height: bgFrame.height), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
        self.tableBgView.layer.mask = nil
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        self.tableBgView.layer.mask = maskLayer
        
        self.tableBgView.frame = bgFrame
        self.tableView.frame = self.tableBgView.bounds
    }
    
    func setupUI() {
        self.clipsToBounds = true
        
        self.backgroundColor = customConfig.albumBgColor
        
        self.tableBgView = UIView()
        self.addSubview(self.tableBgView)
        
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.backgroundColor = customConfig.albumListViewBgColor
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = AlbumListView.rowH
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: AlbumListView.rowH, bottom: 0, right: 0)
        self.tableView.separatorColor = customConfig.albumListSplitLineColor
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(AlbumListCell.classForCoder(), forCellReuseIdentifier: AlbumListCell.className)
        self.tableBgView.addSubview(self.tableView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
    func loadAlbumList(completion: ( () -> Void )? = nil) {
        DispatchQueue.global().async {
            PhotoManger.getPhotoAlbumList(ascending: self.config?.ascending ?? false, mediaType: self.config?.mediaType ?? .image) { [weak self] (albumList) in
                self?.albumListModels.removeAll()
                self?.albumListModels.append(contentsOf: albumList)
                
                DispatchQueue.main.async {
                    completion?()
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    func calculateBgViewBounds() -> CGRect {
        let contentH = CGFloat(self.albumListModels.count) * AlbumListView.rowH
        
        let maxH: CGFloat
        if UIApplication.shared.statusBarOrientation.isPortrait {
            maxH = min(self.frame.height * 0.7, contentH)
        } else {
            maxH = min(self.frame.height * 0.8, contentH)
        }
        
        return CGRect(x: 0, y: 0, width: self.frame.width, height: maxH)
    }
    
    /// 这里不采用监听相册发生变化的方式，是因为每次变化，系统都会回调多次，造成重复获取相册列表
    func show(reloadAlbumList: Bool) {
        func animateShow() {
            let toFrame = self.calculateBgViewBounds()
            
            self.isHidden = false
            self.alpha = 0
            var newFrame = toFrame
            newFrame.origin.y -= newFrame.height
            
            if newFrame != self.tableBgView.frame {
                let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: newFrame.width, height: newFrame.height), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
                self.tableBgView.layer.mask = nil
                let maskLayer = CAShapeLayer()
                maskLayer.path = path.cgPath
                self.tableBgView.layer.mask = maskLayer
            }
            
            self.tableBgView.frame = newFrame
            self.tableView.frame = self.tableBgView.bounds
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1
                self.tableBgView.frame = toFrame
            }
        }
        
        if reloadAlbumList {
            if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
                self.loadAlbumList {
                    animateShow()
                }
            } else {
                self.loadAlbumList()
                animateShow()
            }
        } else {
            animateShow()
        }
    }
    
    func hide() {
        var toFrame = self.tableBgView.frame
        toFrame.origin.y = -toFrame.height
        
        UIView.animate(withDuration: 0.25) {
            self.alpha = 0
            self.tableBgView.frame = toFrame
        } completion: { _ in
            self.isHidden = true
            self.alpha = 1
        }
    }
    
    @objc func tapAction(_ tap: UITapGestureRecognizer) {
        self.hide()
        self.hideBlock?()
    }
    
}

extension AlbumListView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let pan = gestureRecognizer.location(in: self)
        return !self.tableBgView.frame.contains(pan)
    }
}

extension AlbumListView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albumListModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: AlbumListCell.className, for: indexPath) as? AlbumListCell)!
        let album =  self.albumListModels[indexPath.row]
        cell.album = album
        cell.customConfig = self.config?.customUI
        cell.isSelectIndex = self.selectedAlbum == album
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let album = self.albumListModels[indexPath.row]
        self.selectedAlbum = album
        self.selectAlbumBlock?(album)
        self.hide()
        if let inx = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: inx, with: .none)
        }
    }
}
