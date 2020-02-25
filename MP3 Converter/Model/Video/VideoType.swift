//
//  VideoType.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation

enum VideoType: CaseIterable {
    
    case mp4
    case asf
    case mov
    case _3gp
    case _3g2
    case mk4
    case vob
    case mpeg
    case wmv
    case flv
    case avi
    case m4v

    var string: String {
        if self == ._3g2 {
            return "3g2"
        } else if self == ._3gp {
            return "3gp"
        }
        return "\(self)"
    }
}
