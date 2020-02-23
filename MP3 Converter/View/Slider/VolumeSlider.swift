//
//  VolumeSlider.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/23.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class VolumeSlider: UISlider {
    
    let defaultThumbSpace: Float = 11
    lazy var startingOffset: Float = 0 - defaultThumbSpace
    lazy var endingOffset: Float = 2 * defaultThumbSpace
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let xTranslation =  startingOffset + (minimumValue + endingOffset) / maximumValue * value
        return super.thumbRect(forBounds: bounds, trackRect: rect.applying(CGAffineTransform(translationX: CGFloat(xTranslation), y: 0)), value: value)
    }
}
