//
//  AudioManager.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation

class AudioManager {
    
    var audios: [Audio] = []
    
    func getNumOfAudios() -> Int {
        return audios.count
    }
    
    func addAudio(url: URL, title: String, durationTime: Double) {
        let audio = Audio(url: url, title: title, durationTime: durationTime)
        audios.append(audio)
    }
    
    func removeAudio(at index: Int) {
        audios.remove(at: index)
    }
    
    func renameAudio(name: String, at index: Int) {
        audios[index].title = name
    }
    
    func getURL(at index: Int) -> URL {
        return audios[index].url
    }
    
    func getTitle(at index: Int) -> String {
        return audios[index].title
    }
    
    func getDurationTime(at index: Int) -> String {
        return audios[index].getDurationTime()
    }
}
