//
//  Wave.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/3/6.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class Wave {
    
    static let minWave: CGFloat = 0.1
    static let maxWave: CGFloat = 0.5
    static let midWave: CGFloat = 0.3
    static let maxDistance: CGFloat = 0.05
    
    static func generateWave() -> [CGFloat] {
        
        var wave: [CGFloat] = [0.1]
            
        for _ in 1...70 {
            
            var lastNum = wave.last!
            var nextNum = CGFloat.random(in: minWave...maxWave)
            
            while lastNum != nextNum {
                nextNum = min(nextNum, lastNum + maxDistance)
                nextNum = max(nextNum, lastNum - maxDistance)
                wave.append(nextNum)
                lastNum = wave.last!
            }
        }
        
        return wave
    }
    
}
