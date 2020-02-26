//
//  Audio.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation
import AVFoundation

struct Audio {
    
    let url: URL
    var title: String
    var type: AudioType?
    let durationTime: Double
    
    init(url: URL) {
        self.url = url
        self.title = url.deletingPathExtension().lastPathComponent
        self.type = AudioType(string: url.pathExtension)
        
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        self.durationTime = CMTimeGetSeconds(duration)
    }
    
    func getDurationTime() -> String {
        let totalSeconds = Int(durationTime) + 1
        let secondsPerMinute = 60
        let minutes = totalSeconds / secondsPerMinute
        let seconds = totalSeconds - minutes * secondsPerMinute
        let secondsToString = String(format: "%02d", seconds)
        return "\(minutes):" + secondsToString
    }
}
