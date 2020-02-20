//
//  Configuration.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation

class Configuration {
    
    static let sharedInstance = Configuration()
    
    var videoType: VideoType = .mp4
    var audioType: AudioType = .mp3
    
}
