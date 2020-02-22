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
    
    var rootViewController: MainViewController?
    var audio: Audio!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        sender.setBackgroundImage(#imageLiteral(resourceName: "Pause.circle"), for: .normal)
        rootViewController?.playAudio(url: audio.url)
    }
    
}
