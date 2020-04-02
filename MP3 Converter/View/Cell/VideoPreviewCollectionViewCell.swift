//
//  VideoPreviewCollectionViewCell.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class VideoPreviewCollectionViewCell: UICollectionViewCell, UIActionSheetDelegate {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var durationTimeLabel: UILabel!
    
    var rootViewController: MainViewController?
    var index: Int = 0
    
    override func awakeFromNib() {
        let longPress = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(longPressed))
        addGestureRecognizer(longPress)
    }
    
    @IBAction func extractAudioButtonPressed(_ sender: UIButton) {
        rootViewController?.selectedIndex = index
        rootViewController?.extractAudio()
    }
    
    @objc private func longPressed(sender : UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began{
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let convertAction = UIAlertAction(title: "转换", style: .default) { (action) in
                self.rootViewController?.selectedIndex = self.index
                self.rootViewController?.extractAudio()
            }
            let deleteAction = UIAlertAction(title: "删除", style: .destructive) { (action) in
                
                let alert = UIAlertController(title: "该视频删除后将无法复原", message: nil, preferredStyle: .actionSheet)
                
                let deleteAction = UIAlertAction(title: "删除视频", style: .destructive) { action in
                    self.rootViewController?.delete(index: self.index)
                }
                let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                
                alert.addAction(deleteAction)
                alert.addAction(cancelAction)
                self.rootViewController?.present(alert, animated: true, completion: nil)
                
            }
            let cancelAction = UIAlertAction(title: "取消", style: .cancel)
            
            actionSheet.addAction(convertAction)
            actionSheet.addAction(deleteAction)
            actionSheet.addAction(cancelAction)
            
            rootViewController?.present(actionSheet, animated: true, completion: nil)
        }
    }
}
