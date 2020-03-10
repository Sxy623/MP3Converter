//
//  ExtractAudioViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation

protocol ExtractAudioViewControllerDelegate {
    func delete(_ ExtractAudioViewController: UIViewController, index: Int)
}

class ExtractAudioViewController: UIViewController {
    
    @IBOutlet weak var barButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var videoPlayView: VideoPlayView!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    
    @IBOutlet weak var audioClipView: AudioClipView!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var volumeImage: UIImageView!
    @IBOutlet weak var volumeSlider: VolumeSlider!
    @IBOutlet weak var volumeLabel: UILabel!
    
    @IBOutlet var buttons: [UIButton]!
    
    let dataFilePath = Configuration.sharedInstance.dataFilePath()
    let videoListPath = Configuration.sharedInstance.videoListPath()
    let audioListPath = Configuration.sharedInstance.audioListPath()
    
    var delegate: ExtractAudioViewControllerDelegate?
    
    var rootViewController: MainViewController?
    var video: Video!
    var index: Int!
    var timer: Timer!
    var interval: TimeInterval = 0.03
    var volume: Float = 100
    var state: PlayerState = .play
    var type: AudioType = Configuration.sharedInstance.audioType
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ""
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        barButtonItem.setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .normal)
        
        videoPlayView.video = video
        updateTimeLabel()
        
        audioClipView.delegate = self
        audioClipView.wave = video.wave
        // 等待 NavigationBar 出现
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { timer in
            self.updateProgressLabel()
        }

        settingsView.clipsToBounds = true
        settingsView.layer.cornerRadius = 12.0
        volumeImage.image = #imageLiteral(resourceName: "音量 mid")
        volumeSlider.setThumbImage(#imageLiteral(resourceName: "Oval"), for: .normal)
        updateTypeButtons()
        
        progressContinue()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoPlayView.player.pause()
    }
    
    // MARK: - Toolbar
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if state == .play {
            playButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
            videoPlayView.player.pause()
            state = .pause
            progressPause()
        } else {
            playButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
            videoPlayView.player.play()
            state = .play
            progressContinue()
        }
    }
    
    @IBAction func trashButtonPressed(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "该视频删除后将无法复原", message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "删除视频", style: .destructive) { action in
            self.delegate?.delete(self, index: self.index)
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func updateTypeButtons() {
        for button in buttons {
            if button.currentTitle == type.string {
                button.setTitleColor(#colorLiteral(red: 1, green: 0.3725490196, blue: 0.337254902, alpha: 1), for: .normal)
            } else {
                button.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3), for: .normal)
            }
        }
    }
    
    @IBAction func typeButtonPressed(_ sender: UIButton) {
        guard let type = AudioType(string: sender.currentTitle!) else { return }
        self.type = type
        updateTypeButtons()
    }
    
    @IBAction func startButtonPressed(_ sender: UIBarButtonItem) {
        
        let ranameAlert = UIAlertController(title: "音频文件重命名", message: "请输入名称", preferredStyle: .alert)
        
        ranameAlert.addTextField { (textField) in
            textField.placeholder = Date.currentDate
            textField.text = Date.currentDate
            textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(field:)), for: .editingChanged)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let confirmAction = UIAlertAction(title: "确认", style: .default) { action in
            
            let audioTitle: String = ranameAlert.textFields![0].text!
            
            // Create a composition
            let composition = AVMutableComposition()
            let mutableAudioMix = AVMutableAudioMix()
            
            do {
                let sourceUrl = self.video.url
                let asset = AVURLAsset(url: sourceUrl)
                guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
                
                guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
                try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
                
                let mixParamters = AVMutableAudioMixInputParameters(track: audioAssetTrack)
                mixParamters.setVolume(self.volume / 100, at: .zero)
                mutableAudioMix.inputParameters = [mixParamters]
            } catch {
                print(error)
            }
            
            // Get url for temp m4a file
            let outputURLString = "file://" + self.dataFilePath + "/audios/\(audioTitle).m4a"
            guard let outputURL = URL(string: outputURLString) else { return }
            
            // Get url for target
            let targetURLString = "file://" + self.dataFilePath + "/audios/\(audioTitle).\(self.type.string)"
            guard let targetURL = URL(string: targetURLString) else { return }
            
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try? FileManager.default.removeItem(atPath: targetURL.path)
            }
            
            // Create an export session
            // AVAssetExportPresetPassthrough 无法改变音量
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
            
            // m4a 直接通过 exportSession 导出
            // 其他格式通过 m4a 转换
            if self.type == .m4a {
                exportSession.outputFileType = .m4a
                exportSession.outputURL = targetURL
            } else {
                exportSession.outputFileType = .m4a
                exportSession.outputURL = outputURL
            }
            
            exportSession.audioMix = mutableAudioMix
            
            // Set time range
            let start = Double(self.audioClipView.startPercentage) * self.video.duration
            let end = Double(self.audioClipView.endPercentage) * self.video.duration
            let startTime = CMTime(seconds: start, preferredTimescale: 120)
            let endTime = CMTime(seconds: end, preferredTimescale: 120)
            let duration = endTime - startTime
            let exportTimeRange = CMTimeRangeMake(start: startTime, duration: duration)
            exportSession.timeRange = exportTimeRange
            
            // Export file
            exportSession.exportAsynchronously {
                
                guard case exportSession.status = AVAssetExportSession.Status.completed else {
                    print("\(String(describing: exportSession.error?.localizedDescription))")
                    return
                }
                
                if self.type == .caf {
                    AudioConverter.sharedInstance.convertAudioToCAF(outputURL, outputURL: targetURL)
                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        try? FileManager.default.removeItem(atPath: outputURL.path)
                    }
                } else if self.type == .wav {
                    AudioConverter.sharedInstance.convertAudioToWAV(outputURL, outputURL: targetURL)
                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        try? FileManager.default.removeItem(atPath: outputURL.path)
                    }
                } else if self.type == .aiff {
                    AudioConverter.sharedInstance.convertAudioToAIFF(outputURL, outputURL: targetURL)
                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        try? FileManager.default.removeItem(atPath: outputURL.path)
                    }
                } else if self.type == .mp3 {
//                    AudioWrapper.audioPCMtoMP3(outputURL.path, targetURL.path)
                    
                    let converter = ExtAudioConverter()
                    converter.inputFile = outputURL.path
                    converter.outputFile = targetURL.path
                    converter.convert()
                    
                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        try? FileManager.default.removeItem(atPath: outputURL.path)
                    }
                }
                
                DispatchQueue.main.async {
                    self.rootViewController?.addAudio(url: targetURL)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        ranameAlert.addAction(cancelAction)
        ranameAlert.addAction(confirmAction)
        confirmAction.isEnabled = false
        ranameAlert.preferredAction = confirmAction
        
        present(ranameAlert, animated: true, completion: nil)
    }
    
    @objc func alertTextFieldDidChange(field: UITextField) {
        let alertController: UIAlertController = self.presentedViewController as! UIAlertController;
        let textField: UITextField  = alertController.textFields![0];
        let addAction: UIAlertAction = alertController.actions[1];
        addAction.isEnabled = (textField.text?.count)! > 0;
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
        videoPlayView.player.volume = volume / 100
        
        // 设置音量标签
        let trackRect = sender.trackRect(forBounds: sender.frame)
        let thumbRect = sender.thumbRect(forBounds: sender.bounds, trackRect: trackRect, value: sender.value)
        volumeLabel.text = "\(Int(volume))%"
        volumeLabel.center = CGPoint(x: thumbRect.midX, y: volumeLabel.center.y)
    }
    
    func updateTimeLabel() {
        let totalTime = video.duration
        let currentTime = Double(audioClipView.currentPercentage) * video.duration
        timeLabel.text = "\(currentTime.timeString):\(totalTime.timeString)"
    }

    func updateProgressLabel() {
        
        let centerY = audioClipView.frame.maxY + 15
        let originX = audioClipView.frame.origin.x
        
        let start = Double(audioClipView.startPercentage) * video.duration
        startLabel.text = start.timeString
        let startX = audioClipView.frame.size.width * audioClipView.startPercentage
        startLabel.center = CGPoint(x: originX + startX, y: centerY)
        
        let end = Double(audioClipView.endPercentage) * video.duration
        endLabel.text = end.timeString
        let endX = audioClipView.frame.size.width * audioClipView.endPercentage
        endLabel.center = CGPoint(x: originX + endX, y: centerY)
    }
    
    func progressPause() {
        timer.invalidate()
    }
    
    func progressContinue() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (timer) in
            var percantage = self.audioClipView.currentPercentage
            percantage += CGFloat(self.interval) / CGFloat(self.video.duration)
            if percantage > self.audioClipView.endPercentage {
                percantage = self.audioClipView.endPercentage
                self.playButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
                self.videoPlayView.player.pause()
                self.progressPause()
                self.state = .finish
                self.audioClipView.currentPercentage = self.audioClipView.startPercentage
                self.audioClipView.updatePlayer()
            }
            self.audioClipView.currentPercentage = percantage
            self.updateTimeLabel()
            self.audioClipView.updatePlayer()
        }
    }
}

extension ExtractAudioViewController: AudioClipViewDelegate {
    
    func touchBegan(_ audioClipView: AudioClipView) {
//        videoPlayView.player.pause()
    }
    
    func touchMove(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
//        let start = Double(audioClipView.startPercentage) * video.duration
//        let startTime = CMTime(seconds: start, preferredTimescale: 120)
//        videoPlayView.player.seek(to: startTime)
        
      updateProgressLabel()
        
    }
    
    func touchEnd(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
//        videoPlayView.player.play()
    }
}
