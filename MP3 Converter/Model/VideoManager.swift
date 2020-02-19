//
//  VideoManager.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class VideoManager {
    
    var videos: [Video] = []
    
    func getNumOfVideos() -> Int {
        return videos.count
    }
    
    func addVideo(url: URL) {
        if let video = Video(url: url) {
            videos.append(video)
        }
    }
    
    func getPreviewImage(at index: Int) -> UIImage {
        return videos[index].preview
    }
    
    func getDurationTime(at index: Int) -> String {
        return videos[index].getDurationTime()
    }
    
}
