//
//  ViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var originalCollectionView: UICollectionView!
    
    let videoManager = VideoManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalCollectionView.delegate = self
        originalCollectionView.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoManager.getNumOfVideos() + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if (indexPath.item == 0) { // Add video button
            
            let cell = originalCollectionView.dequeueReusableCell(withReuseIdentifier: "Add Video", for: indexPath) as! AddVideoCollectionViewCell
            
            cell.videoManager = videoManager
            cell.collectionView = originalCollectionView
            
            return cell
            
        } else {  // Show video details
            
            let cell = originalCollectionView.dequeueReusableCell(withReuseIdentifier: "Video Details", for: indexPath)
            
            return cell

        }
        
    }
}

