//
//  UIViewController+Extension.swift
//  ImageViewer
//
//  Created by Vivek Narsingh Gupta on 10/02/18.
//  Copyright © 2018 Vivek Narsingh Gupta. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC

let ISIPAD  = UIDevice.current.userInterfaceIdiom == .pad

protocol StoryBoardID: class {}

extension StoryBoardID where Self: UIViewController {
    static var storyBoardID: String {
        return String(describing: self)
    }
}



protocol ImageOverlayViewControllerProtocol: class {
    var imageViewSize: CGSize? { get }
    func presentOverlay(from parentViewController: UIViewController)
    func dismissOverlay()
}

extension ImageOverlayViewControllerProtocol where Self: UIViewController {
    var imageViewSize: CGSize? {
        return nil
    }
    var duration: Double?{
        return 0.5
    }
    
    func animateTransition(parentViewController: UIViewController  ,presenting: Bool, fromView: UIView, toView: UIView, fromFrame: CGRect,toFrame: CGRect, completion: (() -> Void)? = nil) {
        //This will hold your animation code
        let initialFrame = fromFrame
        let finalFrame = toFrame
        let xScaleFactor = presenting ?
            initialFrame.width / finalFrame.width:
            finalFrame.width / initialFrame.width
        let yScaleFactor = presenting ?
            initialFrame.height / finalFrame.height:
            finalFrame.height / initialFrame.height
        let scaleTransform = CGAffineTransform(scaleX: presenting ? xScaleFactor: xScaleFactor,
                                               y: presenting ? yScaleFactor: yScaleFactor)
        if presenting {
            toView.transform = scaleTransform
            toView.center = CGPoint(
                x: initialFrame.midX,
                y: initialFrame.midY)
            toView.clipsToBounds = true
        }
        if presenting{
            UIView.animate(withDuration: 0.3 , delay: 0.0, usingSpringWithDamping: 0.5 , initialSpringVelocity: 0.5, animations: {
                toView.transform = CGAffineTransform.identity
                toView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
            },
                           completion: { _ in
            })
        }else{
            self.view.alpha = 0
            var _toFrame: CGRect = toFrame
            if parentViewController.navigationController != nil{
                if (parentViewController.navigationController?.navigationBar.isHidden)!{
                    parentViewController.navigationController?.isNavigationBarHidden = false
                    if !ISIPAD{
                        if let nvHt = parentViewController.navigationController?.navigationBar.frame.size {
                            _toFrame.origin = CGPoint(x: _toFrame.origin.x, y: _toFrame.origin.y + nvHt.height )
                        }
                    }
                }
            }
            let _fromView = fromView
            _fromView.frame = fromFrame
            parentViewController.view.addSubview(_fromView) //usingSpringWithDamping: 0.8 , initialSpringVelocity: 0.8,
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState],
                           animations: {
                            _fromView.frame = _toFrame
            }, completion: { _ in
                _fromView.removeFromSuperview()
                completion?()
            })
        }
    }
    
    func presentOverlay(from parentViewController: UIViewController, fromFrame: CGRect, toFrame: CGRect,indexPath: IndexPath, completion: (() -> Void)? = nil) {
        parentViewController.view.addSubview(self.view)
        parentViewController.addChildViewController(self)
        self.didMove(toParentViewController: parentViewController)
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        
        self.view.transform = CGAffineTransform(scaleX: 0.55, y: 0.55)
        if let vc = self as? ImageZoomViewController {
            vc.doneButton.isHidden = true
            vc.setAlpha(shouldAlpha: true, alpha: 0.0)
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
                vc.setAlpha(shouldAlpha: true, alpha: 0.85)
                self.addConstraint(parentViewController: parentViewController,myView: self.view)
                self.view.transform = .identity
            },
                           completion: { _ in
                            completion?()
                            //self.view.layer.removeAllAnimations()
                            UIView.animate(withDuration: 0.2, animations:{
                                vc.setAlpha(shouldAlpha: true, alpha: vc.actualAlpha)
                            },completion: { _ in
                                vc.doneButton.isHidden = false
                                self.view.layer.removeAllAnimations()
                            })
            })
        }
    }
    
    func rotate(toSize: CGSize){
        if let vw = self.view.superview{
            UIView.animate(withDuration: 0.1, animations: {
                self.view.frame.size = toSize
                vw.frame.size = toSize
            },
                           completion: { _ in
                            self.view.layer.removeAllAnimations()
            })
        }
        
    }
    
    func addConstraint(parentViewController: UIViewController, myView: UIView){
        parentViewController.view.addConstraint(NSLayoutConstraint(item: myView, attribute: .top, relatedBy: .equal, toItem: parentViewController.view, attribute: .top, multiplier: 1, constant: 0))
        parentViewController.view.addConstraint(NSLayoutConstraint(item: myView, attribute: .bottom, relatedBy: .equal, toItem: parentViewController.view, attribute:.bottom, multiplier: 1, constant: 0))
        parentViewController.view.addConstraint(NSLayoutConstraint(item: myView, attribute: .left, relatedBy: .equal, toItem: parentViewController.view, attribute:.left, multiplier: 1, constant: 0))
        parentViewController.view.addConstraint(NSLayoutConstraint(item: myView, attribute: .right, relatedBy: .equal, toItem: parentViewController.view, attribute:.right, multiplier: 1, constant: 0))
    }
    
    func dismissOverlay(parentViewController: UIViewController ,fromView: UIView, toView: UIView, fromFrame: CGRect, toFrame: CGRect, completion: (() -> Void)? = nil) {
        animateTransition(parentViewController: parentViewController, presenting: false, fromView: fromView, toView: toView, fromFrame: fromFrame, toFrame: toFrame, completion: {
            self.view.layer.removeAllAnimations()
            self.view.removeConstraints(self.view.constraints)
            if let vc = self as? ImageZoomViewController {
                vc.view.removeFromSuperview()
                vc.removeFromParentViewController()
            }
            completion?()
        })
    }
    
    func dismissOverlay(completion: (() -> Void)? = nil){
        self.view.layer.removeAllAnimations()
        self.view.removeConstraints(self.view.constraints)
        if let vc = self as? ImageZoomViewController {
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
        }
        completion?()
    }
}
protocol NibLoadableView: class { }

extension NibLoadableView where Self: UIView {
    static var nibName: String {
        return String(describing: self)
    }
}
extension UICollectionReusableView: NibLoadableView { }
extension UICollectionView {
    
    func register<T: UICollectionViewCell>(_: T.Type)  {
        let nib = UINib(nibName: T.nibName, bundle: nil)
        register(nib, forCellWithReuseIdentifier: T.reuseIdentifier)
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
}
protocol ReusableView: class {}

extension ReusableView where Self: UIView {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
extension UICollectionReusableView: ReusableView { }
