//
//  ImageDownloadOperation.swift
//  ImageViewer
//
//  Created by Vivek Narsingh Gupta on 11/02/18.
//  Copyright © 2018 Vivek Narsingh Gupta. All rights reserved.
//


import Foundation
import ImageIO
import CoreGraphics
import  UIKit

var CC_MD5_DIGEST_LENGTH : Int = 16;          /* digest length in bytes */
var CC_MD5_BLOCK_BYTES : Int = 64;         /* block size in bytes */
var CC_MD5_BLOCK_LONG : Int = (CC_MD5_BLOCK_BYTES / MemoryLayout<CC_LONG>.size.self)

class ImageDownloadOperation : Operation {
    
    private var _executing          = false
    private var _finished           = false
    private var urlString           : String
    private var shouldStore         : Bool
    private var downlodTask         : URLSessionDownloadTask?
    
    private var completion : ((_ hashable : Data?, _ error : Error?) -> Swift.Void)
    
    init(urlString: String, shouldStore: Bool, completion:@escaping ((_ hashable : Data?, _ error : Error?) -> Swift.Void)) {
        self.urlString      = urlString
        self.completion     = completion
        self.shouldStore    = shouldStore
        super.init()
    }
    
    override internal(set) var isExecuting: Bool {
        get {
            return _executing
        }
        set {
            if _executing != newValue {
                willChangeValue(forKey: "isExecuting")
                _executing = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }
    
    override internal(set) var isFinished: Bool {
        get {
            return _finished
        }
        set {
            if _finished != newValue {
                willChangeValue(forKey: "isFinished")
                _finished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    static var pathForDictionary : URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[urls.count-1].appendingPathComponent("imageStore")
    }()
    
    override func start() {
        if isCancelled {
            isFinished = true
            return
        }
        
        isExecuting = true
        self.main()
    }
    
    private func performCompletion (data: Data?, error: Error?) {
        self.completion(data,error)
        self.isExecuting = false
        self.isFinished = true
        self.downlodTask = nil
    }
    
    func performOperation() {
        let configuration   = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15.0
        let session         = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        self.downlodTask    = session.downloadTask(with: URL(string: self.urlString)!)
        self.downlodTask!.resume()
    }
    
    override func main() {
        performOperation()
    }
    
    override func cancel() {
        super.cancel()
        if let task = self.downlodTask {
            task.cancel()
            self.downlodTask = nil
        }
        self.isExecuting = false
        self.isFinished = true
    }
    
    deinit {
        print("IMAGE DOWNLOAD DEINIT")
    }
}

extension ImageDownloadOperation : URLSessionDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    @available(iOS 7.0, *)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        var data : Data?
        if var compressData = self.getDataFromDisk(location: location) {
            if self.shouldStore {
                compressData = compressData.compressImage()
                if !FileManager.default.fileExists(atPath: ImageDownloadOperation.pathForDictionary.path) {
                    do {
                        try FileManager.default.createDirectory(atPath: ImageDownloadOperation.pathForDictionary.path, withIntermediateDirectories: true, attributes: nil)
                    }catch let error {
                        print(error)
                    }
                }
                let filePath = ImageDownloadOperation.pathForDictionary.appendingPathComponent(self.urlString.md5)
                FileManager.default.createFile(atPath: filePath.path, contents: compressData, attributes: nil)
            }
            data = compressData
        }
        self.performCompletion(data: data, error: nil)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        self.performCompletion(data: nil, error: error)
    }
    
    func getDataFromDisk(location: URL) -> Data? {
        
        var imageData : Data?
        
        do {
            imageData = try Data(contentsOf: location, options: Data.ReadingOptions.dataReadingMapped)
        }catch {
            
        }
        
        if (imageData != nil) {
            return imageData
        }
        return nil
    }
    
}
extension String  {
    var md5: String! {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.deinitialize()
        
        return String(format: hash as String)
    }
}

extension Data{
    func compressImage() -> Data {
        // Reducing file size to a 10th
        let source : CGImageSource = CGImageSourceCreateWithData(self as CFData, nil)!
        let count : size_t = CGImageSourceGetCount(source)
        if (count <= 1) {
            if let image:UIImage = UIImage(data: self) {
                var actualHeight : CGFloat = image.size.height
                var actualWidth : CGFloat = image.size.width
                let maxHeight : CGFloat = 1136.0
                let maxWidth : CGFloat = 640.0
                var imgRatio : CGFloat = actualWidth/actualHeight
                let maxRatio : CGFloat = maxWidth/maxHeight
                
                if (actualHeight > maxHeight || actualWidth > maxWidth){
                    if(imgRatio < maxRatio){
                        //adjust width according to maxHeight
                        imgRatio = maxHeight / actualHeight
                        actualWidth = imgRatio * actualWidth
                        actualHeight = maxHeight
                    }
                    else if(imgRatio > maxRatio){
                        //adjust height according to maxWidth
                        imgRatio = maxWidth / actualWidth
                        actualHeight = imgRatio * actualHeight
                        actualWidth = maxWidth
                    }
                    else{
                        actualHeight = maxHeight
                        actualWidth = maxWidth
                    }
                }
                
                let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
                UIGraphicsBeginImageContext(rect.size)
                image.draw(in: rect)
                
                let img = UIGraphicsGetImageFromCurrentImageContext()
                UIColor.red.set()
                UIRectFill(CGRect(x: 0.0, y: 0.0, width: rect.size.width,height: rect.size.height)); //fill the bitmap context
                
                let imageData = UIImagePNGRepresentation(img!)//UIImageJPEGRepresentation(img, compressionQuality);
                UIGraphicsEndImageContext()
                return imageData!
                
            }
        }
        return self
    }
    func animatedImageFromData() -> UIImage? {
        var animatedImage : UIImage?
        let source : CGImageSource = CGImageSourceCreateWithData(self as CFData, nil)!
        let count : size_t = CGImageSourceGetCount(source)
        let EPS:Float = 1e-6
        if (count <= 1) {
            animatedImage = UIImage(data: self)
        }else {
            var imageArray : [UIImage] = [UIImage]()
            var duration : TimeInterval = 0.0
            
            for size : Int in 0 ..< count {
                let image : CGImage = CGImageSourceCreateImageAtIndex(source, size, nil)!
                let imagesourceProperty = CGImageSourceCopyPropertiesAtIndex(source, size, nil)
                let key = Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
                if  let value = CFDictionaryGetValue(imagesourceProperty, key) {
                    let unclampedKey = Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()
                    let unclampedPointer:UnsafeRawPointer? = CFDictionaryGetValue(unsafeBitCast(value, to:CFDictionary.self), unclampedKey)
                    if let delayVal = convertToDelay(unclampedPointer), delayVal >= EPS {
                        duration += TimeInterval(delayVal)
                    }else {
                        let unclampedKey = Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()
                        let unclampedPointer:UnsafeRawPointer? = CFDictionaryGetValue(unsafeBitCast(value, to:CFDictionary.self), unclampedKey)
                        if let delayVal = convertToDelay(unclampedPointer), delayVal >= EPS {
                            duration += TimeInterval(delayVal)
                        }
                    }
                }
                imageArray.append(UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: UIImageOrientation.up))
            }
            animatedImage = UIImage.animatedImage(with: imageArray as [UIImage], duration: duration)
        }
        return animatedImage
    }
    fileprivate func convertToDelay(_ pointer:UnsafeRawPointer?) -> Float? {
        if pointer == nil {
            return nil
        }
        let value = unsafeBitCast(pointer, to:AnyObject.self)
        return value.floatValue
    }
}
