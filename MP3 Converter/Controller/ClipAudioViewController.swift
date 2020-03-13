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
    
    @IBOutlet weak var barButtonItem: UIBarButtonItem!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var audioClipScrollView: UIScrollView!
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
        barButtonItem.setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .normal)
        titleLabel.text = audio.title
        
        audioClipView.waveHeight = 48.0
        audioClipView.clipHeight = 82.0
        audioClipView.spaceToLabel = 15.0
        
        audioClipView.delegate = self
        audioClipView.parentScrollView = audioClipScrollView
        audioClipView.rootView = view
        audioClipView.wave = audio.wave
        audioClipView.startLabel = startLabel
        audioClipView.endLabel = endLabel
        updateProgressLabel()
        
        volumeImage.image = #imageLiteral(resourceName: "Volume")
        volumeSlider.setThumbImage(#imageLiteral(resourceName: "Oval"), for: .normal)
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { (timer) in
            self.updateVolumeLabel()
        }
        
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
        let start = Double(audioClipView.startPercentage) * audio.duration
        startLabel.text = start.timeString
        let end = Double(audioClipView.endPercentage) * audio.duration
        endLabel.text = end.timeString
    }
    
    @IBAction func volumeChanged(_ sender: UISlider) {
        volume = sender.value
        if volume == 0 {
            volumeImage.image = #imageLiteral(resourceName: "Volume min")
        } else if volume == 200 {
            volumeImage.image = #imageLiteral(resourceName: "Volume max")
        } else {
            volumeImage.image = #imageLiteral(resourceName: "Volume")
        }
        player.volume = volume / 100
        updateVolumeLabel()
    }
    
    /* 音量百分比标签 */
    func updateVolumeLabel() {
        let trackRect = volumeSlider.trackRect(forBounds: volumeSlider.frame)
        let thumbRect = volumeSlider.thumbRect(forBounds: volumeSlider.bounds, trackRect: trackRect, value: volumeSlider.value)
        volumeLabel.text = "\(Int(volume))%"
        volumeLabel.center = CGPoint(x: thumbRect.midX, y: volumeSlider.frame.maxY + 20)
    }
    
    func progressPause() {
        timer.invalidate()
    }
    
    func progressContinue() {
        timer = Timer(timeInterval: interval, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
    }
    
    @objc func updateTimer() {
        var percantage = audioClipView.currentPercentage
        percantage += CGFloat(interval) / CGFloat(audio.duration)
        if percantage > audioClipView.endPercentage {
            percantage = audioClipView.endPercentage
            self.player.pause()
        }
        audioClipView.currentPercentage = percantage
        audioClipView.updatePlayer()
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
