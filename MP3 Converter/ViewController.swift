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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalCollectionView.delegate = self
        originalCollectionView.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = originalCollectionView.dequeueReusableCell(withReuseIdentifier: "Add Video", for: indexPath)
        
        return cell
    }

}

