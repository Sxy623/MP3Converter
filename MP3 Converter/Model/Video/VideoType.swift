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
    case aaa
    case bbb

    var string: String {
        get {
            return "\(self)"
        }
    }
}
