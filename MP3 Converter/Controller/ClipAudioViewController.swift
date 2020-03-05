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
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    
    @IBOutlet weak var volumeImage: UIImageView!
    @IBOutlet weak var volumeSlider: VolumeSlider!
    @IBOutlet weak var volumeLabel: UILabel!
    
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
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        titleLabel.text = audio.title
        
        audioClipView.delegate = self
        audioClipView.wave = audio.wave
        // 等待 NavigationBar 出现
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { timer in
            self.updateProgressLabel()
        }
        
        volumeImage.image = #imageLiteral(resourceName: "音量 mid")
        volumeSlider.setThumbImage(#imageLiteral(resourceName: "Oval"), for: .normal)
        
        player = AVPlayer(url: audio.url)
        player.play()
        
        progressContinue()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        let start = Double(audioClipView.startPercentage) * audio.duration
        let end = Double(audioClipView.endPercentage) * audio.duration
        audio.duration = end - start
        
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
            } else if type == .mp3 {
                let converter = ExtAudioConverter()
                converter.inputFile = outputURL.path
                converter.outputFile = audioURL.path
                converter.convert()
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
    
    func updateProgressLabel() {
        
        let centerY = audioClipView.frame.maxY + 18
        
        let start = Double(audioClipView.startPercentage) * audio.duration
        startLabel.text = start.timeString
        let startX = audioClipView.frame.size.width * audioClipView.startPercentage
        startLabel.center = CGPoint(x: startX + startLabel.frame.size.width / 2, y: centerY)
        
        let end = Double(audioClipView.endPercentage) * audio.duration
        endLabel.text = end.timeString
        let endX = audioClipView.frame.size.width * audioClipView.endPercentage
        endLabel.center = CGPoint(x: endX - endLabel.frame.size.width / 2, y: centerY)
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
        
        // 设置音量标签
        let trackRect = sender.trackRect(forBounds: sender.frame)
        let thumbRect = sender.thumbRect(forBounds: sender.bounds, trackRect: trackRect, value: sender.value)
        volumeLabel.text = "\(Int(volume))%"
        volumeLabel.center = CGPoint(x: thumbRect.midX, y: volumeLabel.center.y)
    }
    
    func progressPause() {
        timer.invalidate()
    }
    
    func progressContinue() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (timer) in
            var percantage = self.audioClipView.currentPercentage
            percantage += CGFloat(self.interval) / CGFloat(self.audio.duration)
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
        updateProgressLabel()
    }
    
    func touchEnd(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
        let start = Double(startPercentage) * audio.duration
        let startTime = CMTime(seconds: start, preferredTimescale: 120)
        player.seek(to: startTime)
        player.play()
        
        audioClipView.currentPercentage = startPercentage
        audioClipView.updatePlayer()
        
        progressContinue()
    }
}
