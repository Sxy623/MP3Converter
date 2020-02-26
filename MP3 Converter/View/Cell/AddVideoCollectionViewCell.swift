//
//  AddVideoCollectionViewCell.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class AddVideoCollectionViewCell: UICollectionViewCell {
    
    var rootViewController: MainViewController?
    
    @IBAction func addVideoButtonPressed(_ sender: UIButton) {
        guard let rootViewController = rootViewController else { return }
        rootViewController.displayActionSheet()
    }
}