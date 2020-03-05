//
//  Double.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/3/5.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation

extension Double {
    
    var timeString: String {
        let totalSeconds = Int(ceil(self))
        let secondsPerMinute = 60
        let minutes = totalSeconds / secondsPerMinute
        let seconds = totalSeconds - minutes * secondsPerMinute
        let secondsToString = String(format: "%02d", seconds)
        return "\(minutes):" + secondsToString
    }
    
}
