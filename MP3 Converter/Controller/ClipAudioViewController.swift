//
//  ClipAudioViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/25.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class ClipAudioViewController: UIViewController {
    
    @IBOutlet weak var volumeImage: UIImageView!
    @IBOutlet weak var volumeSlider: VolumeSlider!
    @IBOutlet weak var titleLabel: UILabel!
    
    var rootViewController: MainViewController?
    var audio: Audio!
    var volume: Float = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = audio.title
        volumeSlider.setThumbImage(#imageLiteral(resourceName: "Oval"), for: .normal)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
    }
    
    @IBAction func volumeChanged(_ sender: UISlider) {
        volume = sender.value
        if volume == 0 {
            volumeImage.image = #imageLiteral(resourceName: "音量 min")
        } else if volume == 200 {
            volumeImage.image = #imageLiteral(resourceName: "音量 max")
        } else {
            volumeImage.image = #imageLiteral(resourceName: "音量 mid")
        }
    }
}
