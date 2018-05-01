//
//  ImageCollectionViewController.swift
//  ImageViewer
//
//  Created by Vivek Narsingh Gupta on 11/02/18.
//  Copyright © 2018 Vivek Narsingh Gupta. All rights reserved.
//


import UIKit

private let reuseIdentifier = "cellIdentifier"



public class HandsomeImageGallery: UICollectionViewController {
    var _closeButton : UIButton = {
        let closeButton = UIButton(type: UIButtonType.roundedRect)
        closeButton.titleLabel?.font       = UIFont.boldSystemFont(ofSize: 13)
        closeButton.setTitle("*", for: UIControlState.normal)
        closeButton.setTitleColor(UIColor.blue, for: UIControlState.normal)
        closeButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 50))
        closeButton.addTarget(self, action: #selector(HandsomeImageGallery.close), for: UIControlEvents.touchUpInside)
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.5)
        return closeButton
    }()
    var closeButton: UIButton {
        set { _closeButton = newValue }
        get { return _closeButton }
    }
    
    private var _imageArray: [String] = []
    var imageArray: [String] {
        set { _imageArray = newValue }
        get { return _imageArray }
    }
    var indexPathFromDismissed: IndexPath?
    var currentIndexPath: IndexPath?
    var nextViewController : ImageZoomViewController?
    var indexChanged: Bool = false
    func loadImg() -> [String]{
        var arr: [String] = []
        for i in 1...43{
            arr.append("v\(i)")
        }
        return arr
    }
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        self._imageArray = self.loadImg()
    }
    
    @objc func close()  {
        self.dismiss(animated: false, completion: nil)
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .none
    }
    
    public  override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: UICollectionViewDataSource
     public override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public  override func collectionView(_ collectionView: UICollectionView,  numberOfItemsInSection section: Int) -> Int {
        return self.imageArray.count
    }
    
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let imageVw: UIImageView = cell.viewWithTag(2222) as? UIImageView {
            imageVw.image = nil
            imageVw.contentMode = .scaleAspectFill
            imageVw.image = UIImage()
        }
        return cell
    }
    
    public override var shouldAutorotate: Bool {
        return true
    }
    
    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let identifier = String(describing: ImageZoomViewController.self)
        nextViewController =  self.storyboard!.instantiateViewController(withIdentifier: identifier) as! ImageZoomViewController
        nextViewController!.photoStringArray = self.imageArray
        nextViewController!.selectedIndex    = indexPath
        self.currentIndexPath = indexPath
        nextViewController!.delegateIndexPathFromDismissedVw = self
        let attr = self.collectionView?.layoutAttributesForItem(at: self.currentIndexPath!)
        let nextFrame = (self.collectionView?.convert((attr?.frame)!, to: nil))!
        //MARK: Image dismiss callbacks, hide unHide indexPath in background, destination frame calculations
        nextViewController!.presentOverlay(from: self, fromFrame: nextFrame , toFrame:
            UIScreen.main.bounds,indexPath: indexPath, completion:{
            let cell = self.collectionView?.cellForItem(at: indexPath)
            cell?.isHidden = true
        })
        nextViewController!.unHideIndexPath = { (indexPth) in
            if !self.indexChanged{
                let cell = self.collectionView?.cellForItem(at: indexPath)
                cell?.isHidden = false
            }
            let cell2 = self.collectionView?.cellForItem(at: indexPth)
            cell2?.isHidden = false
            self.indexChanged = true
            print("Unhide")
        }
        nextViewController!.hideIndexPath = { (indxPth, shouldScroll) in
            print("-Hide")
            self.indexPathFromDismissed = indxPth
            let cell2 = self.collectionView?.cellForItem(at: indxPth)
            cell2?.isHidden = true
            if self.indexChanged{
                if shouldScroll{
                    self.collectionView?.scrollToItem(at: indxPth, at: .centeredVertically, animated: false)
                }
            }
        }
        nextViewController!.dismissClosure = { (fromView, fromFrame) in
            guard let frmView = fromView else {
                let cell2 = self.collectionView?.cellForItem(at: indexPath)
                cell2?.isHidden = false
                if let nextIndx = self.indexPathFromDismissed{
                    let cell2 = self.collectionView?.cellForItem(at: nextIndx)
                    cell2?.isHidden = false
                }
                self.nextViewController!.dismissOverlay(completion:{
                    self.currentIndexPath = nil
                    self.nextViewController = nil
                })
                return
            }
            if self.indexPathFromDismissed == nil && self.currentIndexPath == nil {
                return
            }
            let attr = self.collectionView?.layoutAttributesForItem(at: self.indexPathFromDismissed != nil ? self.indexPathFromDismissed! : self.currentIndexPath!)
            let cellFrameInSuperVw = self.collectionView?.convert((attr?.frame)!, to: self.collectionView?.superview)
            if let frm = cellFrameInSuperVw{
                self.nextViewController!.dismissOverlay(parentViewController: self, fromView: frmView, toView: self.view, fromFrame: fromFrame, toFrame: frm, completion: {
                    if self.indexChanged{
                        let cell2 = self.collectionView?.cellForItem(at: self.indexPathFromDismissed!)
                        cell2?.isHidden = false
                    } else {
                        let cell = self.collectionView?.cellForItem(at: indexPath)
                        cell?.isHidden = false
                    }
                    self.indexChanged = false
                    self.indexPathFromDismissed = nil
                    self.currentIndexPath = nil
                    self.nextViewController = nil
                    DispatchQueue.main.async {
                        for index in 0..<self.imageArray.count - 1{
                            let _cell = self.collectionView?.cellForItem(at: IndexPath(row: index, section: 0))
                            _cell?.isHidden = false
                        }
                    }
                })
            }
        }
    }
    
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { (UVTCtx) in
            self.inavlidateLayout()
        }
        
    }
    
    func inavlidateLayout(){
        guard let flowLayout = self.collectionView?.collectionViewLayout as? FlowLayout else {
            return
        }
        var numberOfColumns: Int = 0
        if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
            //here you can do the logic for the cell size if phone is in landscape
            numberOfColumns = ISIPAD ? 6: 4
        } else {
            //logic if not landscape
            numberOfColumns = ISIPAD ? 4: 2
        }
        flowLayout.numberOfColumns = numberOfColumns
        flowLayout.invalidateLayout()
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
}


extension HandsomeImageGallery: IndexPathFromDismissedVw{
    func sendIndexPathAndSizeToParent(indexPath: IndexPath, frame: CGRect) {
        self.indexPathFromDismissed = indexPath
    }
}

