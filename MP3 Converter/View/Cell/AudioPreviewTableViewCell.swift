//
//  AudioPreviewTableViewCell.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation

class AudioPreviewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var audioTitleLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var triangleImage: UIImageView!
    
    var rootViewController: MainViewController?
    var index: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if rootViewController?.playerState == PlayerState.play && rootViewController?.currentPlayingIndex == index {
            sender.setBackgroundImage(#imageLiteral(resourceName: "Play.circle"), for: .normal) // Pause
        } else {
            sender.setBackgroundImage(#imageLiteral(resourceName: "Pause.circle"), for: .normal) // Play
        }
        rootViewController?.playAudio(index: index)
    }
    
}
