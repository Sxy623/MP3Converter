//
//  ExtractAudioViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation

class ExtractAudioViewController: UIViewController {
    
    @IBOutlet weak var videoPlayView: VideoPlayView!
    @IBOutlet weak var pauseImageView: UIImageView!
    @IBOutlet weak var audioClipView: AudioClipView!
    @IBOutlet weak var volumeImage: UIImageView!
    @IBOutlet weak var volumeSlider: VolumeSlider!
    @IBOutlet var buttons: [UIButton]!
    
    let dataFilePath = Configuration.sharedInstance.dataFilePath()
    let videoListPath = Configuration.sharedInstance.videoListPath()
    let audioListPath = Configuration.sharedInstance.audioListPath()
    
    var rootViewController: MainViewController?
    var video: Video!
    var type: AudioType = Configuration.sharedInstance.audioType
    
    var volume: Float = 100
    var state: PlayerState = .play
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayView.video = video
        audioClipView.delegate = self
        volumeImage.image = #imageLiteral(resourceName: "音量 mid")
        volumeSlider.setThumbImage(#imageLiteral(resourceName: "Oval"), for: .normal)
        updateTypeButtons()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoPlayView.player.pause()
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
    
    @IBAction func videoPlayViewPressed(_ sender: UIButton) {
        if state == .play {
            pauseImageView.image = #imageLiteral(resourceName: "Play")
            videoPlayView.player.pause()
            state = .pause
        } else {
            pauseImageView.image = nil
            videoPlayView.player.play()
            state = .play
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
            textField.placeholder = "Placeholder"
            textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(field:)), for: .editingChanged)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let confirmAction = UIAlertAction(title: "确认", style: .default) { action in
            
            let audioTitle: String = ranameAlert.textFields![0].text!
            
            // Create a composition
            let composition = AVMutableComposition()
//            let mutableAudioMix = AVMutableAudioMix()
            
            do {
                let sourceUrl = self.video.url
                let asset = AVURLAsset(url: sourceUrl)
                guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
                
                guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
                audioCompositionTrack.preferredVolume = 0.0
                try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
                
//                let mixParamters = AVMutableAudioMixInputParameters(track: audioAssetTrack)
//                mixParamters.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.0, timeRange: CMTimeRangeMake(start: CMTime.zero, duration: composition.duration))
//                mutableAudioMix.inputParameters = [mixParamters]
                
            } catch {
                print(error)
            }
            
            // Get url for temp m4a file
            let m4aURLString = "file://" + self.dataFilePath + "/audios/\(audioTitle).m4a"
            guard let m4aURL = URL(string: m4aURLString) else { return }
            
            // Get url for output
            let outputURLString = "file://" + self.dataFilePath + "/audios/\(audioTitle).\(self.type.string)"
            guard let outputURL = URL(string: outputURLString) else { return }
            
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(atPath: outputURL.path)
            }
            
            // Create an export session
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
            
            // m4a 和 caf 直接通过 exportSession 导出
            // 其他格式通过 m4a 转换
            if self.type == .m4a || self.type == .caf {
                exportSession.outputFileType = self.type.avFileType
                exportSession.outputURL = outputURL
            } else {
                exportSession.outputFileType = .m4a
                exportSession.outputURL = m4aURL
            }
            
//            exportSession.audioMix = mutableAudioMix
            
            // Set time range
            let start = Double(self.audioClipView.startPercentage) * self.video.durationTime
            let end = Double(self.audioClipView.endPercentage) * self.video.durationTime
            
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
                
                if self.type == .wav {
                    AudioConverter.sharedInstance.convertAudioToWAV(m4aURL, outputURL: outputURL)
                    if FileManager.default.fileExists(atPath: m4aURL.path) {
                        try? FileManager.default.removeItem(atPath: m4aURL.path)
                    }
                } else if self.type == .aiff {
                    AudioConverter.sharedInstance.convertAudioToAIFF(m4aURL, outputURL: outputURL)
                    if FileManager.default.fileExists(atPath: m4aURL.path) {
                        try? FileManager.default.removeItem(atPath: m4aURL.path)
                    }
                }
                
                DispatchQueue.main.async {
                    self.rootViewController?.addAudio(url: outputURL)
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
    }
}

extension ExtractAudioViewController: AudioClipViewDelegate {
    
    func touchBegan(_ audioClipView: AudioClipView) {
//        videoPlayView.player.pause()
    }
    
    func touchMove(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
//        let start = Double(audioClipView.startPercentage) * video.durationTime
//        let startTime = CMTime(seconds: start, preferredTimescale: 120)
//        videoPlayView.player.seek(to: startTime)
    }
    
    func touchEnd(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
//        videoPlayView.player.play()
    }
}
