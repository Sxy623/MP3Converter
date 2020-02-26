//
//  VideoPlayView.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/26.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class VideoPlayView: UIView {
    
    var player: AVPlayer!
    var video: Video!

    override func draw(_ rect: CGRect) {
        let videoURL = video.url
        player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.bounds
        layer.addSublayer(playerLayer)
        player.play()
    }
}
