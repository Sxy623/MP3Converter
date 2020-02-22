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
    
    var rootViewController: MainViewController?
    var video: Video!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func startButtonPressed(_ sender: UIBarButtonItem) {
        
        let ranameAlert = UIAlertController(title: "音频文件重命名", message: "请输入名称", preferredStyle: .alert)
        
        ranameAlert.addTextField { (textField) in
            textField.placeholder = "Placeholder"
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let confirmAction = UIAlertAction(title: "确认", style: .default) { action in
            
            var audioTitle: String = ranameAlert.textFields?[0].text ?? ""
            
            if audioTitle.isEmpty {
                audioTitle = "out.m4a"
            }
            
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
            let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory() + audioTitle)
            let audioURL = outputUrl
            
            if FileManager.default.fileExists(atPath: outputUrl.path) {
                try? FileManager.default.removeItem(atPath: outputUrl.path)
            }
            
            // Create an export session
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
            exportSession.outputFileType = AVFileType.m4a
            exportSession.outputURL = outputUrl
            
            // Export file
            exportSession.exportAsynchronously {
                guard case exportSession.status = AVAssetExportSession.Status.completed else { return }
                
                DispatchQueue.main.async {
                    //                    // Present a UIActivityViewController to share audio file
                    //                    guard let outputURL = exportSession.outputURL else { return }
                    //                    let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: [])
                    //                    self.present(activityViewController, animated: true, completion: nil)
                    
                    self.rootViewController?.addAudio(url: audioURL, title: audioTitle, durationTime: self.video.durationTime)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        ranameAlert.addAction(cancelAction)
        ranameAlert.addAction(confirmAction)
        ranameAlert.preferredAction = confirmAction
        
        present(ranameAlert, animated: true, completion: nil)
    }
}
