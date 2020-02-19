//
//  LeftAlignLayout.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class LeftAlignLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        let attributes = super.layoutAttributesForElements(in: rect)

        if attributes?.count == 1 {

            if let currentAttribute = attributes?.first {
                currentAttribute.frame = CGRect(x: self.sectionInset.left, y: currentAttribute.frame.origin.y, width: currentAttribute.frame.size.width, height: currentAttribute.frame.size.height)
            }

        }

        return attributes

    }
}
