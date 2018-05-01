//
//  FlowLayout.swift
//  ImageViewer
//
//  Created by Vivek Narsingh Gupta on 10/02/18.
//  Copyright © 2018 Vivek Narsingh Gupta. All rights reserved.
//

import UIKit
class FlowLayout: UICollectionViewFlowLayout {
    
    var numberOfColumns = ISIPAD ? 4: 2
    private var cache = [UICollectionViewLayoutAttributes]()
    private var contentHeight: CGFloat  = 0.0
    
    var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        return UIScreen.main.bounds.width - (insets.left + insets.right)
    }
    
    override func prepare() {
        super.prepare()
        self.cache.removeAll()
        
        let columnWidth = self.contentWidth / CGFloat(self.numberOfColumns)
        var xOffset = [CGFloat]()
        for column in 0 ..< self.numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        
        var column = 0
        var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
        for item in 0 ..< collectionView!.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let photoHeight = columnWidth
            let height = (item == 0) ? UIScreen.main.bounds.width: photoHeight
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: ((item == 0) ? UIScreen.main.bounds.width: columnWidth), height: height)
            let insetFrame = frame.insetBy(dx: 1, dy: 1)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            
            contentHeight = max(contentHeight, frame.maxY)
            if (item == 0) {
                for columnT in 0 ..< self.numberOfColumns {
                    yOffset[columnT] = yOffset[columnT] + height
                }
            }else {
                yOffset[column] = yOffset[column] + height
                column = Int(fmod(CGFloat(item), CGFloat(self.numberOfColumns)))
            }
        }
    }
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: (contentHeight < self.collectionView!.frame.height ? self.collectionView!.frame.height + 20: contentHeight))
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for attributes in cache {
            layoutAttributes.append(attributes)
        }
        return layoutAttributes
    }
    
}
