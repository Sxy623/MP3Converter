//
//  Video.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation

struct Video {
    
    let url: URL
    let fileName: String
    let preview: UIImage
    let durationTime: Double
    
    init?(url: URL) {
        
        self.url = url
        self.fileName = url.lastPathComponent
        
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            let image =  UIImage(cgImage: imageRef)
            self.preview = image
        } catch let error as NSError {
            print("Preview generation failed with error \(error)")
            return nil
        }
        
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
