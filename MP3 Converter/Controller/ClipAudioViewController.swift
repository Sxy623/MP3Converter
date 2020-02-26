//
//  ClipAudioViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/25.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation

class ClipAudioViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var audioClipView: AudioClipView!
    @IBOutlet weak var volumeImage: UIImageView!
    @IBOutlet weak var volumeSlider: VolumeSlider!
    
    let dataFilePath = Configuration.sharedInstance.dataFilePath()
    let videoListPath = Configuration.sharedInstance.videoListPath()
    let audioListPath = Configuration.sharedInstance.audioListPath()
    
    var rootViewController: MainViewController?
    var audio: Audio!
    var volume: Float = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = audio.title
        volumeImage.image = #imageLiteral(resourceName: "音量 mid")
        volumeSlider.setThumbImage(#imageLiteral(resourceName: "Oval"), for: .normal)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        let start = Double(audioClipView.startPercentage) * audio.durationTime
        let end = Double(audioClipView.endPercentage) * audio.durationTime
        audio.durationTime = end - start
        
        let startTime = CMTime(seconds: start, preferredTimescale: 120)
        let endTime = CMTime(seconds: end, preferredTimescale: 120)
        let duration = endTime - startTime
        
        let audioURL = audio.url
        let outputURL = URL(string: "file://" + self.dataFilePath + "/audios/out.m4a")!
        let asset = AVURLAsset(url: audioURL)
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(atPath: outputURL.path)
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else { return }
        let exportTimeRange = CMTimeRangeMake(start: startTime, duration: duration)
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputURL
        exportSession.timeRange = exportTimeRange
        exportSession.exportAsynchronously{
            
            if AVAssetExportSession.Status.failed == exportSession.status {
                print("\(String(describing: exportSession.error?.localizedDescription))")
            }
        
            try? FileManager.default.removeItem(at: audioURL)
            try? FileManager.default.moveItem(at: outputURL, to: audioURL)
            
            DispatchQueue.main.async {
                self.rootViewController?.convertedTableView.reloadData()
                self.navigationController?.popViewController(animated: true)
            }
        }
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
