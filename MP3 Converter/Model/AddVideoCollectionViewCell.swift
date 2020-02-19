//
//  AddVideoCollectionViewCell.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class AddVideoCollectionViewCell: UICollectionViewCell {
    
    var videoManager: VideoManager?
    var collectionView: UICollectionView?
    
    @IBAction func addVideoButtonPressed(_ sender: UIButton) {
        
        guard let videoManager = videoManager else { return }
        guard let collectionView = collectionView else { return }
        
        videoManager.addVideo()
        collectionView.reloadData()
        
    }
    
}
