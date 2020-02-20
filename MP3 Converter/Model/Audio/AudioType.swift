//
//  AudioType.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation

enum AudioType: CaseIterable {
    
    case mp3
    case ccc
    case ddd
    
    var string: String {
        get {
            return "\(self)"
        }
    }
}
