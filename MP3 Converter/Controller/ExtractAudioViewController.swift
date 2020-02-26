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
    @IBOutlet weak var audioClipView: AudioClipView!
    @IBOutlet weak var volumeSlider: VolumeSlider!
    @IBOutlet weak var volumeImage: UIImageView!
    
    var rootViewController: MainViewController?
    var video: Video!
    var type: AudioType = Configuration.sharedInstance.audioType
    
    var volume: Float = 100
    
    let dataFilePath = Configuration.sharedInstance.dataFilePath()
    let videoListPath = Configuration.sharedInstance.videoListPath()
    let audioListPath = Configuration.sharedInstance.audioListPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayView.video = video
        audioClipView.delegate = self
        volumeSlider.setThumbImage(#imageLiteral(resourceName: "Oval"), for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        videoPlayView.player.pause()
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
            
            do {
                let sourceUrl = self.video.url
                let asset = AVURLAsset(url: sourceUrl)
                guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
                guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
                try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
            } catch {
                print(error)
            }
            
            // Get url for output
            let outputURLString = "file://" + self.dataFilePath + "/audios/\(audioTitle).\(self.type.string)"
            
            guard let outputUrl = URL(string: outputURLString) else { return }
            
            if FileManager.default.fileExists(atPath: outputUrl.path) {
                try? FileManager.default.removeItem(atPath: outputUrl.path)
            }
            
            // Create an export session
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
            exportSession.outputFileType = AVFileType.m4a
            exportSession.outputURL = outputUrl
            
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
                guard case exportSession.status = AVAssetExportSession.Status.completed else { return }
                
                DispatchQueue.main.async {
                    self.rootViewController?.addAudio(url: outputUrl)
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
    
    @objc func alertTextFieldDidChange(field: UITextField){
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
    }
}

extension ExtractAudioViewController: AudioClipViewDelegate {
    
    func touchBegan(_ audioClipView: AudioClipView) {
        videoPlayView.player.pause()
    }
    
    func touchMove(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
        let start = Double(audioClipView.startPercentage) * video.durationTime
        let startTime = CMTime(seconds: start, preferredTimescale: 120)
        videoPlayView.player.seek(to: startTime)
    }
    
    func touchEnd(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat) {
        videoPlayView.player.play()
    }
}
