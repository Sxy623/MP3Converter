//
//  GradientView.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/3/5.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class GradientView: UIView {
    override open class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // 定义渐变的颜色
        let topColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        let buttomColor = UIColor.white
        let gradientColors = [topColor.cgColor, buttomColor.cgColor]
        
        // 定义每种颜色所在的位置
        let gradientLocations : [NSNumber] = [0.0, 1.0]
        
        // 为Layer设置参数
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations
    }
}
