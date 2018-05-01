//
//  UIImageView+Extension.swift
//  ImageViewer
//
//  Created by Vivek Narsingh Gupta on 10/02/18.
//  Copyright © 2018 Vivek Narsingh Gupta. All rights reserved.
//

import Foundation
import UIKit
protocol DownloadImage : class {}

var loadUrlString : UInt8 = 0

extension DownloadImage where Self : UIImageView {
    var loadingString : String? {
        set {
            objc_setAssociatedObject(self, &loadUrlString, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &loadUrlString) as? String
        }
    }
    
    func loadImage(urlString: String?, shouldReload: Bool = false, completion: ((_ image : UIImage?) -> Swift.Void)? = nil)  {
        if urlString != nil {
            if urlString?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count == 0 {
                return
            }
            self.loadingString = urlString!.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: " ").inverted)!
            _ = ImageLoadManager.shared.downloadImage(withUrl: self.loadingString!, shouldStore: !shouldReload) {[weak self] (url, image) in
                DispatchQueue.main.async {
                    if let slf = self, let img = image {
                        if slf.loadingString == url {
                            slf.image = img
                            if let cmp = completion{
                                cmp(image)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension UIImageView: DownloadImage {
    
}

