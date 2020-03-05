//
//  Audio.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation
import AVFoundation

class Audio {
    
    var url: URL
    var title: String
    var type: AudioType?
    var duration: Double
    
    init(url: URL) {
        self.url = url
        self.title = url.deletingPathExtension().lastPathComponent
        self.type = AudioType(string: url.pathExtension)
        
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        self.duration = CMTimeGetSeconds(duration)
    }
    
    func getDurationString() -> String {
        return duration.timeString
    }
}
