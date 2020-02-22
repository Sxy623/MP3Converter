//
//  VideoPreviewCollectionViewCell.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class VideoPreviewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var durationTimeLabel: UILabel!
    
    var rootViewController: MainViewController?
    var index: Int = 0
    
    @IBAction func extractAudioButtonPressed(_ sender: UIButton) {
        rootViewController?.selectedIndex = index
        rootViewController?.extractAudio()
    }
}
