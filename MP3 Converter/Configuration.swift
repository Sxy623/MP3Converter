//
//  Configuration.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class Configuration {
    
    static let sharedInstance = Configuration()
    
    var videoType: VideoType = .mp4
    var audioType: AudioType = .m4a
    
    func dataFilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func videoListPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory + "/videos/data.plist"
    }
    
    func audioListPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory + "/audios/data.plist"
    }
    
    func bandfolderPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cachesDirectory = paths[0]
        return cachesDirectory + "/bandfolder"
    }
    
    func bandfolderDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cachesDirectory = paths[0]
        return cachesDirectory + "/bandfolderDirectory"
    }
}
