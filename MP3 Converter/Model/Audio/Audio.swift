//
//  Audio.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation

struct Audio {
    
    let url: URL
    let title: String
    let durationTime: Double
    
    init(url: URL, title: String, durationTime: Double) {
        self.url = url
        self.title = title
        self.durationTime = durationTime
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
