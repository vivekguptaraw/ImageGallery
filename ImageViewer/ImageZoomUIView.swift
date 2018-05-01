//
//  ImageZoomUIView.swift
//  ImageViewer
//
//  Created by Vivek Narsingh Gupta on 11/02/18.
//  Copyright © 2018 Vivek Narsingh Gupta. All rights reserved.
//


import UIKit
import Foundation

class ImageZoomUIView: UIView, UIScrollViewDelegate {
    
    let scrollView: UIScrollView  = UIScrollView()
    let imageView: UIImageView   = UIImageView()
    var pointInView: CGPoint       = CGPoint.zero
    
    lazy var doubleTapRecognizer: UITapGestureRecognizer =  {
        return UITapGestureRecognizer(target: self, action: #selector(ImageZoomUIView.scrollViewDoubleTapped(_:)))
    }()
    
    lazy var twoFingerTapRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(ImageZoomUIView.scrollViewTwoFingerTapped(_:)))
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup () {
        doubleTapRecognizer.numberOfTapsRequired    = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        
        twoFingerTapRecognizer.numberOfTapsRequired     = 1
        twoFingerTapRecognizer.numberOfTouchesRequired  = 2
        
        doubleTapRecognizer.delaysTouchesBegan  = true
        
        self.scrollView.addGestureRecognizer(doubleTapRecognizer)
        self.scrollView.addGestureRecognizer(twoFingerTapRecognizer)
        
        self.scrollView.minimumZoomScale    = 1
        self.scrollView.maximumZoomScale    = 4
        
        self.scrollView.showsHorizontalScrollIndicator  = false
        self.scrollView.showsVerticalScrollIndicator    = false
        
        self.scrollView.delegate    = self
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.imageView)
        
    }
    
    func loadImage (imageURL: String!) {
        if let imageurl = imageURL {
            if let image = UIImage(named: imageurl) {
                self.imageView.contentMode  = UIViewContentMode.scaleAspectFit
                self.imageView.image        = image
                self.setScrollToZoom(image)
            }
        }
    }
    
    func setScrollToZoom (_ image: UIImage) {
        self.layoutSubviews()
        self.zoomScrollViewToNormal()
        var frame: CGRect = CGRect(origin: CGPoint.zero, size: CGSize(width: self.scrollView.frame.width, height: self.scrollView.frame.height))
        if (image.size.height < image.size.width) || (image.size.height > image.size.width) {
            if self.scrollView.frame.width > self.scrollView.frame.height {
                let ratio = image.size.width/image.size.height
                frame.size.width = ratio * frame.height
            }else {
                let ratio = image.size.height/image.size.width
                frame.size.height = ratio * frame.width
            }
        }else {
            if self.scrollView.frame.width > self.scrollView.frame.height {
                frame.size.width = frame.height
            }else {
                frame.size.height = frame.width
            }
        }
        self.imageView.frame = frame
        self.scrollView.addSubview(self.imageView)
        self.scrollView.contentSize = self.imageView.frame.size
        self.imageView.center = self.scrollView.center
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView.contentInset = UIEdgeInsets.zero
        self.scrollView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.frame.width, height: self.frame.height))
        var frame: CGRect = CGRect.zero
        self.imageView.contentMode = UIViewContentMode.scaleAspectFit
        
        if let image = self.imageView.image {
            if (image.size.height < image.size.width) || (image.size.height > image.size.width) {
                if self.scrollView.frame.width > self.scrollView.frame.height {
                    let ratio = image.size.width/image.size.height
                    frame.size.width = ratio * self.scrollView.frame.height
                    frame.size.height = self.scrollView.frame.height
                    if (frame.width > self.scrollView.frame.width) {
                        let ratio = image.size.height/image.size.width
                        frame.size.height = ratio * self.scrollView.frame.width
                        frame.size.width = self.scrollView.frame.width
                    }
                }else {
                    let ratio = image.size.height/image.size.width
                    frame.size.height = ratio * self.scrollView.frame.width
                    frame.size.width = self.scrollView.frame.width
                    if (frame.height > self.scrollView.frame.height) {
                        let ratio = image.size.width/image.size.height
                        frame.size.width = ratio * self.scrollView.frame.height
                        frame.size.height = self.scrollView.frame.height
                    }
                    
                }
            }else {
                if self.scrollView.frame.width > self.scrollView.frame.height {
                    frame.size.height = self.scrollView.frame.height
                    frame.size.width = self.scrollView.frame.height
                }else {
                    frame.size.height = self.scrollView.frame.width
                    frame.size.width = self.scrollView.frame.width
                }
                
            }
        }
        
        self.imageView.frame = frame
        self.scrollView.contentSize = self.imageView.frame.size
        self.scrollView.contentOffset = CGPoint.zero
        self.imageView.center = self.scrollView.center
    }
    
    @objc func scrollViewDoubleTapped (_ recognizer: UITapGestureRecognizer) {
        self.pointInView = recognizer.location(in: self.scrollView)
        var newZoomScale: CGFloat = self.scrollView.zoomScale * 4.0
        newZoomScale = (newZoomScale > self.scrollView.maximumZoomScale ? self.scrollView.minimumZoomScale : newZoomScale)
        let scrollViewSize: CGSize = self.scrollView.bounds.size
        let w: CGFloat = scrollViewSize.width / newZoomScale
        let h: CGFloat = scrollViewSize.height / newZoomScale
        let x: CGFloat = self.pointInView.x - (w / 2.0)
        let y: CGFloat = self.pointInView.y - (h / 2.0)
        
        let rectToZoomTo: CGRect = CGRect(x: x, y: y, width: w, height: h)
        self.scrollView.zoom(to: rectToZoomTo, animated: true)
        
    }
    
    func zoomScrollViewToNormal () {
        
        self.pointInView = self.imageView.center
        let newZoomScale: CGFloat = scrollView.minimumZoomScale
        let scrollViewSize: CGSize = self.scrollView.bounds.size
        let w: CGFloat = scrollViewSize.width / newZoomScale
        let h: CGFloat = scrollViewSize.height / newZoomScale
        let x: CGFloat = self.pointInView.x - (w / 2.0)
        let y: CGFloat = self.pointInView.y - (h / 2.0)
        
        let rectToZoomTo: CGRect = CGRect(x: x, y: y, width: w, height: h)
        self.scrollView.zoom(to: rectToZoomTo, animated: true)
        self.scrollView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    @objc func scrollViewTwoFingerTapped(_ recognizer: UITapGestureRecognizer) {
        var newZoomScale: CGFloat = self.scrollView.zoomScale / 4.0
        newZoomScale = (newZoomScale < self.scrollView.maximumZoomScale ? self.scrollView.maximumZoomScale : newZoomScale)
        self.scrollView.setZoomScale(newZoomScale, animated: true)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.centerScrollViewContents(scrollView: scrollView)
    }
    
    func centerScrollViewContents (scrollView: UIScrollView) {
        let boundsSize: CGSize = scrollView.bounds.size
        var contentsFrame: CGRect = scrollView.frame
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        if (self.imageView.frame.size.height > scrollView.frame.size.height) {
            self.imageView.center = CGPoint(x: scrollView.contentSize.width / 2, y: scrollView.contentSize.height / 2)
        }else if (self.imageView.frame.size.width < scrollView.frame.size.width) {
            self.imageView.center = CGPoint(x: scrollView.frame.size.width / 2, y: scrollView.frame.size.height / 2)
        }else {
            self.imageView.center = CGPoint(x: scrollView.contentSize.width / 2, y: scrollView.frame.size.height / 2)
        }
    }
}

