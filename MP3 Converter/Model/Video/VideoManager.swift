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
    
    func addNewVideo(url: URL) {
        if let video = Video(url: url) {
            videos.insert(video, at: 0)
        }
    }
    
    func appendVideo(url: URL) {
           if let video = Video(url: url) {
               videos.append(video)
           }
       }
    
    func removeVideo(at index: Int) {
        videos.remove(at: index)
    }
    
    func getURL(at index: Int) -> URL {
        return videos[index].url
    }
    
    func getPreviewImage(at index: Int) -> UIImage {
        return videos[index].preview
    }
    
    func getDurationTime(at index: Int) -> String {
        return videos[index].getDurationString()
    }
    
    func getFileNameArray() -> [String] {
        return videos.map { $0.fileName }
    }
}
