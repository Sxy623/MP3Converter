//
//  MainViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation
import CoreServices

enum PlayerState {
    case play, pause, finish
}

class MainViewController: UIViewController {
    
    @IBOutlet weak var originalCollectionView: UICollectionView!
    @IBOutlet weak var nothingConvertedView: UIView!
    @IBOutlet weak var convertedTableView: UITableView!
    @IBOutlet weak var originalButton: UIButton!
    @IBOutlet weak var originalIndicator: UIImageView!
    @IBOutlet weak var convertedButton: UIButton!
    @IBOutlet weak var convertedIndicator: UIImageView!
    
    let videoManager = VideoManager()
    let audioManager = AudioManager()
    
    let dataFilePath = Configuration.sharedInstance.dataFilePath()
    let videoListPath = Configuration.sharedInstance.videoListPath()
    let audioListPath = Configuration.sharedInstance.audioListPath()
    
    var player = AVAudioPlayer()
    var currentPlayingIndex: Int = 0

    var playerState: PlayerState = .finish
    
    var selectedIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Test
        print(Configuration.sharedInstance.dataFilePath())
        
        checkDirectory()
        loadData()
        
        originalCollectionView.delegate = self
        originalCollectionView.dataSource = self
        
        convertedTableView.delegate = self
        convertedTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Upload Video
    
    func displayActionSheet() {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let uploadFromAlbumAction = UIAlertAction(title: "从相册上传", style: .default) { (action) in
            self.uploadVideoFromAlbum()
        }
        let uploadFromFilesAction = UIAlertAction(title: "从文件上传", style: .default) { (action) in
            self.uploadVideoFromFiles()
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        actionSheet.addAction(uploadFromAlbumAction)
        actionSheet.addAction(uploadFromFilesAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func uploadVideoFromAlbum() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.movie"]
        // Avoid compression
        imagePicker.videoExportPreset = AVAssetExportPresetPassthrough
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func uploadVideoFromFiles() {
        let types = [String(kUTTypeMPEG4)]
        let documentPickerViewController = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPickerViewController.delegate = self
        
        // Multiple Selection
        if #available(iOS 11.0, *) {
            documentPickerViewController.allowsMultipleSelection = true
        }
        
        present(documentPickerViewController, animated: true, completion: nil)
    }
    
    // MARK: - Extract Audio
    
    func extractAudio() {
        performSegue(withIdentifier: "Extract Audio", sender: nil)
    }
    
    func addAudio(url: URL) {
        audioManager.addAudio(url: url)
        recordAudio()
        convertedTableView.reloadData()
    }
    
    // MARK: - Player Manager
    
    func playAudio(index: Int) {
        
        let oldCell = convertedTableView.cellForRow(at: IndexPath(row: currentPlayingIndex, section: 0)) as! AudioPreviewTableViewCell
        oldCell.triangleImage.isHidden = true
        
        let newCell = convertedTableView.cellForRow(at: IndexPath(row: index, section: 0)) as! AudioPreviewTableViewCell
        
        switch playerState {
            
        case .finish:
            currentPlayingIndex = index
            player = try! AVAudioPlayer(contentsOf: audioManager.getURL(at: index))
            player.delegate = self
            player.play()
            playerState = .play
            newCell.audioProgressView.play()
            
        case .play:
            if currentPlayingIndex == index {
                player.pause()
                playerState = .pause
                oldCell.audioProgressView.pause()
            } else {
                player.stop()
                oldCell.playButton.setBackgroundImage(#imageLiteral(resourceName: "Play.circle"), for: .normal)
                oldCell.audioProgressView.reset()
                
                currentPlayingIndex = index
                player = try! AVAudioPlayer(contentsOf: audioManager.getURL(at: index))
                player.delegate = self
                player.play()
                playerState = .play
                newCell.audioProgressView.play()
            }
            
        case .pause:
            if currentPlayingIndex == index {
                player.play()
                playerState = .play
                oldCell.audioProgressView.resume()
            } else {
                player.stop()
                oldCell.audioProgressView.reset()
                
                currentPlayingIndex = index
                player = try! AVAudioPlayer(contentsOf: audioManager.getURL(at: index))
                player.delegate = self
                player.play()
                playerState = .play
                newCell.audioProgressView.play()
            }
        }
        
        newCell.triangleImage.isHidden = false
    }
    
    // MARK: - User Interface
    
    @IBAction func toggleToOriginal(_ sender: UIButton) {
        originalButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        originalIndicator.alpha = 1.0
        convertedButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.18), for: .normal)
        convertedIndicator.alpha = 0.0
        originalCollectionView.isHidden = false
        nothingConvertedView.isHidden = true
        convertedTableView.isHidden = true
        player.stop()
    }
    
    @IBAction func toggleToConverted(_ sender: UIButton) {
        originalButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.18), for: .normal)
        originalIndicator.alpha = 0.0
        convertedButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        convertedIndicator.alpha = 1.0
        originalCollectionView.isHidden = true
        if audioManager.getNumOfAudios() == 0 {
            nothingConvertedView.isHidden = false
        } else {
            convertedTableView.isHidden = false
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Settings" {
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        } else if segue.identifier == "Extract Audio" {
            let destinationViewController = segue.destination as! ExtractAudioViewController
            destinationViewController.rootViewController = self
            destinationViewController.video = videoManager.videos[selectedIndex]
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "原视频", style: .plain, target: nil, action: nil)
        } else if segue.identifier == "Clip Audio" {
            let destinationViewController = segue.destination as! ClipAudioViewController
            destinationViewController.rootViewController = self
            destinationViewController.audio = audioManager.audios[selectedIndex]
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "已完成", style: .plain, target: nil, action: nil)
        }
    }
    
    // MARK: - File Manager
    
    /* 新建目录 */
    func checkDirectory() {
        
        // Video directory
        if (!FileManager.default.fileExists(atPath: dataFilePath + "/videos/")) {
            do {
                try FileManager.default.createDirectory(atPath: dataFilePath + "/videos/", withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Create directory error.")
            }
        }
        
        // Audio directory
        if (!FileManager.default.fileExists(atPath: dataFilePath + "/audios/")) {
            do {
                try FileManager.default.createDirectory(atPath: dataFilePath + "/audios/", withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Create directory error.")
            }
        }
    }
    
    /* 加载视频和音频文件 */
    func loadData() {
        
        // Load videos
        if FileManager.default.fileExists(atPath: videoListPath) {
            let array = NSArray(contentsOfFile: videoListPath) as! [String]
            for videoFileName in array {
                let videoURLString = "file://" + dataFilePath + "/videos/\(videoFileName)"
                guard let videoURL = URL(string: videoURLString) else { continue }
                videoManager.addVideo(url: videoURL)
            }
            originalCollectionView.reloadData()
        }
        
        // Load audios
        if FileManager.default.fileExists(atPath: audioListPath) {
            let array = NSArray(contentsOfFile: audioListPath) as! [String]
            for audioFileName in array {
                let audioURLString = "file://" + dataFilePath + "/audios/\(audioFileName)"
                guard let audioURL = URL(string: audioURLString) else { continue }
                audioManager.addAudio(url: audioURL)
            }
            convertedTableView.reloadData()
        }
    }
    
    /* 将视频数据保存到文件 */
    func recordVideo() {
        if FileManager.default.fileExists(atPath: self.videoListPath) {
            FileManager.default.createFile(atPath: self.videoListPath, contents: nil, attributes: nil)
        }
        
        let array = self.videoManager.getFileNameArray() as NSArray
        array.write(toFile: self.videoListPath, atomically: true)
    }
    
    /* 将音频数据保存到文件 */
    func recordAudio() {
        if FileManager.default.fileExists(atPath: audioListPath) {
            FileManager.default.createFile(atPath: audioListPath, contents: nil, attributes: nil)
        }
        
        let array = audioManager.getFileNameArray() as NSArray
        array.write(toFile: audioListPath, atomically: true)
    }
}

// MARK: - CollectionView Delegate

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoManager.getNumOfVideos() + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.item
        
        if index == 0 {
            
            let cell = originalCollectionView.dequeueReusableCell(withReuseIdentifier: "Add Video", for: indexPath) as! AddVideoCollectionViewCell
            cell.rootViewController = self
            return cell
            
        } else {
            
            let cell = originalCollectionView.dequeueReusableCell(withReuseIdentifier: "Video Preview", for: indexPath) as! VideoPreviewCollectionViewCell
            cell.index = indexPath.item - 1
            cell.rootViewController = self
            cell.previewImageView.image = videoManager.getPreviewImage(at: index - 1)
            cell.durationTimeLabel.text = videoManager.getDurationTime(at: index - 1)
            return cell
            
        }
    }
}

// MARK: - ImagePickerController Delegate

extension MainViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let videoURL = info[.mediaURL] as! URL
        let fileName = videoURL.lastPathComponent
        let outputURLString = "file://" + dataFilePath + "/videos/\(fileName)"
        
        let asset = AVURLAsset(url: videoURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputFileType = AVFileType.mov
        exportSession.outputURL = URL(string: outputURLString)
        exportSession.exportAsynchronously{
            
            self.videoManager.addVideo(url: videoURL)
            self.recordVideo()
            
            DispatchQueue.main.async {
                self.originalCollectionView.reloadData()
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - DocumentPicker Delegate

extension MainViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for videoURL in urls {
            let fileName = videoURL.lastPathComponent
            let outputURLString = "file://" + dataFilePath + "/videos/\(fileName)"
            
            let asset = AVURLAsset(url: videoURL)
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
            exportSession.outputFileType = AVFileType.mov
            exportSession.outputURL = URL(string: outputURLString)
            exportSession.exportAsynchronously{
                
                self.videoManager.addVideo(url: videoURL)
                self.recordVideo()
                
                DispatchQueue.main.async {
                    self.originalCollectionView.reloadData()
                }
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TableView Delegate

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioManager.getNumOfAudios()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = convertedTableView.dequeueReusableCell(withIdentifier: "Audio Preview", for: indexPath) as! AudioPreviewTableViewCell
        cell.rootViewController = self
        cell.delegate = self
        cell.index = indexPath.row
        cell.audioTitleLabel.text = audioManager.getTitle(at: indexPath.row)
        cell.durationTimeLabel.text = audioManager.getDurationTime(at: indexPath.row)
        cell.audioProgressView.time = CGFloat(audioManager.audios[indexPath.row].durationTime)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - AudioPreviewTableView Delegate

extension MainViewController: AudioPreviewTableViewCellDelegate {
    
    func ringtone(_ AudioPreviewTableViewCell: UITableViewCell, index: Int) {
        let audioURL = audioManager.getURL(at: index)
        let activityViewController = UIActivityViewController(activityItems: [audioURL], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }
    
    func share(_ AudioPreviewTableViewCell: UITableViewCell, index: Int) {
        let audioURL = audioManager.getURL(at: index)
        let activityViewController = UIActivityViewController(activityItems: [audioURL], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }
    
    func rename(_ AudioPreviewTableViewCell: UITableViewCell, index: Int) {
        let ranameAlert = UIAlertController(title: "重命名", message: "请输入新名称", preferredStyle: .alert)
        
        ranameAlert.addTextField { (textField) in
            textField.placeholder = "Placeholder"
            textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(field:)), for: .editingChanged)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let confirmAction = UIAlertAction(title: "确认", style: .default) { action in
            
            guard let type = self.audioManager.getType(at: index) else { return }
            let oldTitle = self.audioManager.getTitle(at: index)
            let newTitle: String = ranameAlert.textFields![0].text!
            let oldPath = self.dataFilePath + "/audios/\(oldTitle).\(type.string)"
            let newPath = self.dataFilePath + "/audios/\(newTitle).\(type.string)"
            
            self.audioManager.renameAudio(name: newTitle, at: index)
            do {
                try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
            } catch {
                print("Rename error")
            }
            self.recordAudio()
            self.convertedTableView.reloadData()
        }
        
        ranameAlert.addAction(cancelAction)
        ranameAlert.addAction(confirmAction)
        confirmAction.isEnabled = false
        ranameAlert.preferredAction = confirmAction
        
        present(ranameAlert, animated: true, completion: nil)
    }
    
    func clip(_ AudioPreviewTableViewCell: UITableViewCell, index: Int) {
        performSegue(withIdentifier: "Clip Audio", sender: nil)
    }
    
    func delete(_ AudioPreviewTableViewCell: UITableViewCell, index: Int) {
        let deleteAlert = UIAlertController(title: "删除", message: "确认删除该文件吗？", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let confirmAction = UIAlertAction(title: "确认", style: .default) { action in
            
            guard let type = self.audioManager.getType(at: index) else { return }
            let title = self.audioManager.getTitle(at: index)
            let path = self.dataFilePath + "/audios/\(title).\(type.string)"
            
            self.audioManager.removeAudio(at: index)
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Delete error")
            }
            self.recordAudio()
            self.convertedTableView.reloadData()
            if self.audioManager.getNumOfAudios() == 0 {
                self.nothingConvertedView.isHidden = false
                self.convertedTableView.isHidden = true
            }
        }
        
        deleteAlert.addAction(cancelAction)
        deleteAlert.addAction(confirmAction)
        deleteAlert.preferredAction = confirmAction
        
        present(deleteAlert, animated: true, completion: nil)
    }
    
    @objc func alertTextFieldDidChange(field: UITextField){
        let alertController: UIAlertController = self.presentedViewController as! UIAlertController;
        let textField: UITextField  = alertController.textFields![0];
        let addAction: UIAlertAction = alertController.actions[1];
        addAction.isEnabled = (textField.text?.count)! > 0;
    }
}

// MARK: - AudioPlayer Delegate

extension MainViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let cell = convertedTableView.cellForRow(at: IndexPath(row: currentPlayingIndex, section: 0)) as! AudioPreviewTableViewCell
        cell.playButton.setBackgroundImage(#imageLiteral(resourceName: "Play.circle"), for: .normal)
        playerState = .finish
    }
    
}
