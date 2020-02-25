//
//  AudioType.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation

enum AudioType: CaseIterable {
    
    case m4a
    case mp3
    case wav
    case aiff
    case acc
    case m4r
    case flac
    case opus
    case caf
    case wma
    case ogg
    case adx
    
    var string: String {
        return "\(self)"
    }
}
