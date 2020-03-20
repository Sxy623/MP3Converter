//
//  AudioType.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation
import AVFoundation

enum AudioType: CaseIterable {
    
    case mp3
    case m4a
    case wav
    case aiff
//    case acc
//    case m4r
//    case flac
//    case opus
    case caf
//    case wma
//    case ogg
//    case adx
    
    var string: String {
        return "\(self)"
    }
    
    init?(string: String) {
        switch string {
        case "m4a":
            self = .m4a
        case "mp3":
            self = .mp3
        case "wav":
            self = .wav
        case "aiff":
            self = .aiff
//        case "acc":
//            self = .acc
//        case "m4r":
//            self = .m4r
//        case "flac":
//            self = .flac
//        case "opus":
//            self = .opus
        case "caf":
            self = .caf
//        case "wma":
//            self = .wma
//        case "ogg":
//            self = .ogg
//        case "adx":
//            self = .adx
        default:
            return nil
        }
    }
}
