//
//  ImageZoomViewController.swift
//  ImageViewer
//
//  Created by Vivek Narsingh Gupta on 11/02/18.
//  Copyright © 2018 Vivek Narsingh Gupta. All rights reserved.
//


import UIKit

protocol IndexPathFromDismissedVw {
    func sendIndexPathAndSizeToParent(indexPath: IndexPath, frame: CGRect)
    func dismissClosure(fromView: UIView?,_ fromFrame: CGRect)
    func unHideIndexPath(indexPth: IndexPath)
    func hideIndexPath(indexPth: IndexPath,_ shouldScroll: Bool)
    func showIndexPath(indexPth: IndexPath)
    
}

@objc public protocol ImageZoomViewDataSource {
    func numberOfImagesInGallery(gallery:ImageZoomViewController) -> Int
    func imageInGallery(gallery:ImageZoomViewController, forIndex:Int) -> UIImage?
}

@objc public protocol ImageZoomViewDelegate {
    func galleryDidTapToClose(gallery:ImageZoomViewController)
}

enum DragDirection
{
    case down
    case up
    case left
    case right
    case none
}

private let reuseIdentifier = "Cell"

public class ImageZoomViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    var panGesture: UIPanGestureRecognizer!
    let self_ViewSize: CGSize? = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    var photoStringArray: [Any]?
    var selectedIndex: IndexPath = IndexPath(item: 0, section: 0)
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var titleBaseView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    var hasTitle: Bool = true
    let gradient = CAGradientLayer()
    var dragDirection: DragDirection = .none
    lazy var tap: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(ImageZoomViewController.handleTap(_:)))
    }()
    var delegateIndexPathFromDismissedVw: IndexPathFromDismissedVw?
    var dismissClosure: ((_ fromView: UIView?,_ fromFrame: CGRect ) -> Void)?
    var unHideIndexPath: ((_ indexPth: IndexPath) -> Void)?
    var hideIndexPath: ((_ indexPth: IndexPath,_ shouldScroll: Bool) -> Void)?
    var showIndexPath: ((_ indexPth: IndexPath) -> Void)?
    let actualAlpha: CGFloat = 0.9
    private var didLayoutFlag: Bool = false
    private var needsLayout = false
    
    public weak var dataSource: ImageZoomViewDataSource?
    public weak var delegate: ImageZoomViewDelegate?
    
    init(dataSource: ImageZoomViewDataSource, delegate: ImageZoomViewDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.dataSource = dataSource
        self.delegate = delegate
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.register(ImageCollectionCell.self)
        (self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = UIScreen.main.bounds.size
        self.view.addGestureRecognizer(self.tap)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.reloadData()
        if let array = self.photoStringArray {
            if array.count > self.selectedIndex.row {
                if let imageDict: [String: AnyObject] = array[self.selectedIndex.row] as? [String: AnyObject] {
                    self.settitleLableString(imageDict)
                }
            }
        }
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(ImageZoomViewController.handlePanGesture))
        panGesture.delegate = self
        self.collectionView.addGestureRecognizer(panGesture)
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        self.originalViewOrigin = self.view.frame.origin
        self.setAlpha(shouldAlpha: false, alpha: actualAlpha)
        self.view.layer.removeAllAnimations()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView.scrollToItem(at: self.selectedIndex, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true        
    }
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        if needsLayout{
            if self.selectedIndex.row >= 0 {
                scrollToImage(withIndex: self.selectedIndex.row, animated: false)
            }
            UIView.animate(withDuration: 0.8,delay: 0.0, options: [.curveLinear], animations: {
                flowLayout.itemSize = self.view.bounds.size
                flowLayout.invalidateLayout()
            }, completion: { (BOOL) in
                self.needsLayout = false
            })
        }
    }
    
    
    private func scrollToImage(withIndex: Int, animated: Bool = false) {
        self.collectionView!.scrollToItem(at: IndexPath(item: withIndex, section: 0), at: .centeredHorizontally, animated: animated)
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        needsLayout = true
        coordinator.animate(alongsideTransition: nil) { (UVTCtx) in
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
    }
    
    @objc func handleTap(_ tap: UIGestureRecognizer) {
        self.doneButton.isHidden = !self.doneButton.isHidden
        if self.hasTitle {
            self.titleBaseView.isHidden = self.doneButton.isHidden
        }else {
            self.titleBaseView.isHidden = true
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    var indexPath: IndexPath?
    @IBAction func doneButtonClick(_ sender: Any) {
        /////self.hideIndexPath?(self.selectedIndex, false)
        delegateIndexPathFromDismissedVw?.hideIndexPath(indexPth: self.selectedIndex, false)
        dismissOverlayTransparently()
    }
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override public var prefersStatusBarHidden: Bool{
        return true
    }
    
    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .none
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let array = self.photoStringArray {
            return array.count
        }
        return 0
    }
    
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        let cellWidth = UIScreen.main.bounds.width
//        let cellCount = self.photoStringArray!.count
//        let totalCellWidth = Int(cellWidth) * (cellCount)
//        let totalSpacingWidth = 0 * (cellCount - 1)
//
//        let leftInset = (cellWidth - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
//        let rightInset = leftInset
//
//        return UIEdgeInsetsMake(0, leftInset, 0, rightInset)
//    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath) as ImageCollectionCell
        if let array = self.photoStringArray {
            if array.count > indexPath.row {
                cell.imageZoomUIView.loadImage(imageURL: array[indexPath.row] as! String)
                self.titleBaseView.isHidden = true
                self.hasTitle = false
            }
        }
        self.tap.require(toFail: cell.imageZoomUIView.doubleTapRecognizer)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    var currentIndexPath: IndexPath?
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let cellViews = self.collectionView.indexPathsForVisibleItems
        if cellViews.count > 0 {
            let indexPath = cellViews[0]
            delegateIndexPathFromDismissedVw?.unHideIndexPath(indexPth: indexPath)
            /////self.unHideIndexPath?(indexPath)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cellViews = self.collectionView.indexPathsForVisibleItems
        if cellViews.count > 0 {
            let indexPath = cellViews[0]
            if let array = self.photoStringArray {
                if array.count > indexPath.row {
                    if let imageDict: [String: AnyObject] = array[indexPath.row] as? [String: AnyObject] {
                        self.settitleLableString(imageDict)
                    }
                }
            }
            self.selectedIndex = indexPath
            delegateIndexPathFromDismissedVw?.hideIndexPath(indexPth: indexPath, true)
            /////self.hideIndexPath?(indexPath,true)
        }
    }
    
    func settitleLableString(_ imageDict: [String: AnyObject]) {
        if let string: String = imageDict["caption"] as? String {
            self.titleLabel.text = string.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil)
            self.titleBaseView.isHidden = self.doneButton.isHidden
            self.gradient.frame = self.titleBaseView.bounds
            self.hasTitle = true
        }else {
            self.titleBaseView.isHidden = true
            self.hasTitle = false
        }
    }
    
    //    override var shouldAutorotate: Bool {
    //        return true
    //    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    // MARK: Swipe to dismiss implementation
    
    // MARK: Cell
    var cell: UICollectionViewCell!
    var originalViewOrigin = CGPoint()
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        //==translation in percentage
        let percentThreshold: CGFloat = 0.20
        let translation = sender.translation(in: collectionView      )
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let upwardMovement = fminf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let upwardMovementPercent = fminf(upwardMovement, 1.0)
        let downProgress = CGFloat(downwardMovementPercent)
        let upProgress = CGFloat(upwardMovementPercent)
        let progress = downwardMovement == 0.0 ? -(upProgress): downProgress
        let locationInCollectionView: CGPoint = panGesture.location(in: collectionView)
        let  actualVelocity = sender.velocity(in: self.view)
        let duration = Double(translation.y) / Double(actualVelocity.y)
        let indexPathOfMovingCell = collectionView.indexPathForItem(at: locationInCollectionView)
        cell = collectionView.cellForItem(at: indexPathOfMovingCell!)
        switch sender.state{
        case .began:
            self.setPanDirection(velocity: actualVelocity)
            
        case .changed:
            
            if dragDirection == .up || dragDirection == .down
            {
                UIView.animate(withDuration: duration, animations: {
                    self.view.frame.origin = CGPoint(x: 0, y: self.originalViewOrigin.y + translation.y)
                })
                UIView.animate(withDuration: duration, animations: {
                    let vm = verticalMovement < 0 ? -(verticalMovement): verticalMovement
                    self.doneButton.alpha = 1.0 - (vm + 0.8)
                    self.setAlpha(shouldAlpha: true, alpha: 1.0 - (vm + 0.95))
                })
                if progress > percentThreshold{
                    /////self.hideIndexPath?(indexPathOfMovingCell!,true)
                    if indexPathOfMovingCell != nil{
                            delegateIndexPathFromDismissedVw?.hideIndexPath(indexPth: indexPathOfMovingCell!, true)
                    }
                }
            }
        case .cancelled:
            self.setAlpha(shouldAlpha: false, alpha: actualAlpha)
        case .ended:
            if progress < percentThreshold {
                if actualVelocity.y > 0 {
                    if actualVelocity.y > 1100{
                        dismissOverlayTransparently(verticalMovement: locationInCollectionView.y)
                        return
                    }
                }else{
                    if -(actualVelocity.y) > 1100{
                        dismissOverlayTransparently(verticalMovement: locationInCollectionView.y)
                        return
                    }
                }
                // Bounces back to middle of the View
                let dr = duration > 0.7 ? 0.6 : duration
                UIView.animate(withDuration: dr, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                    self.doneButton.alpha = 1.0
                    self.view.frame.origin = self.originalViewOrigin
                    self.setAlpha(shouldAlpha: false, alpha: self.actualAlpha)
                }, completion: { (_) in
                    self.view.layer.removeAllAnimations()
                    return
                })
            }
            else if progress > percentThreshold{
                dismissOverlayTransparently(verticalMovement: locationInCollectionView.y)
                return
            }
        default:
            break
        }
    }
    
    func dismissOverlayTransparently(verticalMovement: CGFloat? = nil){
        let centerPoint = self.collectionView.contentOffset.x / self.collectionView.bounds.size.width
        self.indexPath = IndexPath(row: Int(round(centerPoint)), section: 0)
        self.showIndexPath?(self.indexPath!)
        //if let cell = self.collectionView.cellForItem(at: self.indexPath!) as? ImageCollectionCell{
        if let cell = self.collectionView.cellForItem(at: self.indexPath!) as? ImageCollectionCell{
            var frm: CGRect = CGRect.zero
            var pt: CGPoint = CGPoint.zero
            pt = CGPoint(x: (UIScreen.main.bounds.width - frm.size.width) / 2 , y: (UIScreen.main.bounds.height - frm.size.height) / 2)
            if cell.imageZoomUIView.imageView.frame.height > cell.imageZoomUIView.imageView.frame.width{
                frm.size = CGSize(width: cell.imageZoomUIView.imageView.frame.width , height: cell.imageZoomUIView.imageView.frame.width)
                pt = CGPoint(x: (UIScreen.main.bounds.width - frm.size.width) / 2 , y: (UIScreen.main.bounds.height - frm.size.height) / 2)
            } else if cell.imageZoomUIView.imageView.frame.height < cell.imageZoomUIView.imageView.frame.width{
                frm.size = CGSize(width: cell.imageZoomUIView.imageView.frame.height , height: cell.imageZoomUIView.imageView.frame.height)
                pt = CGPoint(x: (UIScreen.main.bounds.width - frm.size.width) / 2 , y: (UIScreen.main.bounds.height - frm.size.height) / 2)
            } else{
                frm.size = CGSize(width: cell.imageZoomUIView.imageView.frame.width , height: cell.imageZoomUIView.imageView.frame.height)
                pt = CGPoint(x: (UIScreen.main.bounds.width - frm.size.width) / 2 , y: (UIScreen.main.bounds.height - frm.size.height) / 2)
            }
            frm.origin = pt
            guard let imageData = cell.imageZoomUIView.imageView.image else{
                if delegateIndexPathFromDismissedVw != nil{
                    delegateIndexPathFromDismissedVw?.dismissClosure(fromView: nil, frm)
                    /////dismissClosure?(nil, frm)
                }else{
                    self.dismiss(animated: true, completion: nil)
                }
                return
            }
            let img = UIImageView(image: imageData)
            img.contentMode = .scaleAspectFill
            img.frame.size = frm.size
            img.clipsToBounds = true
            if let vm = verticalMovement{
                frm.origin = CGPoint(x: 0 , y: UIScreen.main.bounds.height - vm)
            }
            if self.indexPath != nil{
                //delegateIndexPathFromDismissedVw?.sendIndexPathAndSizeToParent(indexPath: self.indexPath!)
            }            
            setAlpha(shouldAlpha: true, alpha: 0.05)
            if delegateIndexPathFromDismissedVw != nil{
                delegateIndexPathFromDismissedVw?.dismissClosure(fromView: img, frm)
            }else{
                self.dismiss(animated: true, completion: nil)
            }
            
        }
        
    }
    
    private func setPanDirection(velocity: CGPoint)
    {
        if fabs(velocity.x) > fabs(velocity.y)
        {
            if velocity.x > 0
            {
                dragDirection = .right
            }
            else
            {
                dragDirection = .left
            }
        }
        else
        {
            if velocity.y > 0
            {
                dragDirection = .down
            }
            else
            {
                dragDirection = .up
            }
        }
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: collectionView!)
            if fabs(translation.y) > fabs(translation.x) {
                return true
            }
            return false
        }
        return false
    }
    
    func setAlpha(shouldAlpha: Bool, alpha: CGFloat){
        if shouldAlpha{
            self.view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            self.collectionView.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            self.gradient.isHidden = true
        } else{
            self.view.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            self.collectionView.backgroundColor = UIColor.black.withAlphaComponent(alpha)
            self.gradient.isHidden = true
        }
    }
}

extension ImageZoomViewController: ImageOverlayViewControllerProtocol{
    func presentOverlay(from parentViewController: UIViewController) {
        
    }
    func dismissOverlay() {
        
    }
    
}

