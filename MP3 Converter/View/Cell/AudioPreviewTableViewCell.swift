//
//  AudioPreviewTableViewCell.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation

protocol AudioPreviewTableViewCellDelegate {
    func ringtone(_ audioPreviewTableViewCell: UITableViewCell, index: Int)
    func share(_ audioPreviewTableViewCell: UITableViewCell, index: Int)
    func rename(_ audioPreviewTableViewCell: UITableViewCell, index: Int)
    func clip(_ audioPreviewTableViewCell: UITableViewCell, index: Int)
    func delete(_ audioPreviewTableViewCell: UITableViewCell, index: Int)
}

class AudioPreviewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var audioTitleLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var triangleImage: UIImageView!
    @IBOutlet weak var audioProgressView: AudioProgressView!
    
    var rootViewController: MainViewController?
    var delegate: AudioPreviewTableViewCellDelegate?
    var index: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func playOrPause() {
        if rootViewController?.playerState == PlayerState.play && rootViewController?.currentPlayingIndex == index {
            playButton.setBackgroundImage(#imageLiteral(resourceName: "Play.circle"), for: .normal) // Pause
        } else {
            playButton.setBackgroundImage(#imageLiteral(resourceName: "Pause.circle"), for: .normal) // Play
        }
        rootViewController?.playAudio(index: index)
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        playOrPause()
    }
    
    @IBAction func ringtonePressed(_ sender: UIButton) {
        self.delegate?.ringtone(self, index: index)
    }
    
    @IBAction func sharePressed(_ sender: UIButton) {
        self.delegate?.share(self, index: index)
    }
    
    @IBAction func morePressed(_ sender: UIButton) {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let renameAction = UIAlertAction(title: "重命名", style: .default) { (action) in
            self.delegate?.rename(self, index: self.index)
        }
        let clipAction = UIAlertAction(title: "裁剪", style: .default) { (action) in
            self.rootViewController?.selectedIndex = self.index
            self.delegate?.clip(self, index: self.index)
        }
        let deleteAction = UIAlertAction(title: "删除", style: .destructive) { (action) in
            self.delegate?.delete(self, index: self.index)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        actionSheet.addAction(renameAction)
        actionSheet.addAction(clipAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        
        rootViewController?.present(actionSheet, animated: true, completion: nil)
    }
}
