//
//  TestViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/22.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import SoundWave

class TestViewController: UIViewController {
    
    @IBOutlet weak var audioVisualizationView: AudioVisualizationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.audioVisualizationView.meteringLevelBarWidth = 5.0
        self.audioVisualizationView.meteringLevelBarInterItem = 1.0
        self.audioVisualizationView.meteringLevelBarCornerRadius = 2.0
        
        self.audioVisualizationView.gradientStartColor = #colorLiteral(red: 1, green: 0.3725490196, blue: 0.337254902, alpha: 1)
        self.audioVisualizationView.gradientEndColor = .red
        
        self.audioVisualizationView.audioVisualizationMode = .read
        self.audioVisualizationView.meteringLevels = [0.1, 0.67, 0.13, 0.78, 0.31]
        for i in 0...10 {
            self.audioVisualizationView.meteringLevels?.append(Float(i) / 10)
        }
        for i in 0...10 {
            self.audioVisualizationView.meteringLevels?.append(Float(i) / 10)
        }
        for i in 0...10 {
            self.audioVisualizationView.meteringLevels?.append(Float(i) / 10)
        }
        
    
        //        self.audioVisualizationView.reset()
    }
    
    
    @IBAction func buttonPressed(_ sender: Any) {
        
        self.audioVisualizationView.play(for: 5.0)
    }
    
}
