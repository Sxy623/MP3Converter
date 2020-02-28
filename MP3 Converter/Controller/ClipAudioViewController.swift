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
    var player = AVPlayer()
    var audio: Audio!
    var timer: Timer!
    var interval: TimeInterval = 0.03
    var volume: Float = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = audio.title
        audioClipView.delegate = self
        volumeImage.image = #imageLiteral(resourceName: "音量 mid")
        volumeSlider.setThumbImage(#imageLiteral(resourceName: "Oval"), for: .normal)
        
        player = AVPlayer(url: audio.url)
        player.play()
        
        progressContinue()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        player.pause()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        let start = Double(audioClipView.startPercentage) * audio.durationTime
        let end = Double(audioClipView.endPercentage) * audio.durationTime
        audio.durationTime = end - start
        
        let startTime = CMTime(seconds: start, preferredTimescale: 120)
        let endTime = CMTime(seconds: end, preferredTimescale: 120)
        let duration = endTime - startTime
        
        let audioURL = audio.url
        let type = audio.type!
        
        let asset = AVURLAsset(url: audioURL)
        let outputURL = URL(string: "file://" + self.dataFilePath + "/audios/out.m4a")!
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(atPath: outputURL.path)
        }
        
        guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
        let mixParamters = AVMutableAudioMixInputParameters(track: audioAssetTrack)
        mixParamters.setVolume(volume / 100, at: .zero)
        let mutableAudioMix = AVMutableAudioMix()
        mutableAudioMix.inputParameters = [mixParamters]
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else { return }
        let exportTimeRange = CMTimeRangeMake(start: startTime, duration: duration)
        
        exportSession.outputFileType = .m4a
        exportSession.outputURL = outputURL
        exportSession.audioMix = mutableAudioMix
        exportSession.timeRange = exportTimeRange
        exportSession.exportAsynchronously {
            
            guard case exportSession.status = AVAssetExportSession.Status.completed else {
                print("\(String(describing: exportSession.error?.localizedDescription))")
                return
            }
            
            if type == .caf {
                AudioConverter.sharedInstance.convertAudioToCAF(outputURL, outputURL: audioURL)
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    try? FileManager.default.removeItem(atPath: outputURL.path)
                }
            } else if type == .wav {
                AudioConverter.sharedInstance.convertAudioToWAV(outputURL, outputURL: audioURL)
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    try? FileManager.default.removeItem(atPath: outputURL.path)
                }
            } else if type == .aiff {
                AudioConverter.sharedInstance.convertAudioToAIFF(outputURL, outputURL: audioURL)
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    try? FileManager.default.removeItem(atPath: outputURL.path)
                }
            } else {
                try? FileManager.default.removeItem(at: audioURL)
                try? FileManager.default.moveItem(at: outputURL, to: audioURL)
            }
            
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
        player.volume = volume / 100
    }
    
    func progressPause() {
        timer.invalidate()
    }
    
    func progressContinue() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (timer) in
            var percantage = self.audioClipView.currentPercentage
            percantage += CGFloat(self.interval) / CGFloat(self.audio.durationTime)
            if percantage > self.audioClipView.endPercentage {
                percantage = self.audioClipView.endPercentage
                self.player.pause()
            }
            self.audioClipView.currentPercentage = percantage
            self.audioClipView.updatePlayer()
        }
    }
}

extension ClipAudioViewController: AudioClipViewDelegate {
    
    func touchBegan(_ audioClipView: AudioClipView) {
        player.pause()
        progressPause()
    }
    
    func touchMove(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
    }
    
    func touchEnd(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
        let start = Double(startPercentage) * audio.durationTime
        let startTime = CMTime(seconds: start, preferredTimescale: 120)
        player.seek(to: startTime)
        player.play()
        
        audioClipView.currentPercentage = startPercentage
        audioClipView.updatePlayer()
        
        progressContinue()
    }
}
