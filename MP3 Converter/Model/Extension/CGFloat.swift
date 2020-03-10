//
//  CGFloat.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/3/10.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

extension CGFloat {
    
    static func clamp(_ num: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        if num > upper {
            return upper
        }
        if num < lower {
            return lower
        }
        return num
    }
    
}
