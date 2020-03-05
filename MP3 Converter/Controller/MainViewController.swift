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
import BSImagePicker
import Photos

class MainViewController: UIViewController {
    
    @IBOutlet weak var originalButton: UIButton!
    @IBOutlet weak var convertedButton: UIButton!
    @IBOutlet weak var indicator: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var originalCollectionView: UICollectionView!
    @IBOutlet weak var nothingConvertedView: UIView!
    @IBOutlet weak var convertedTableView: UITableView!
    
    let videoManager = VideoManager()
    let audioManager = AudioManager()
    
    let dataFilePath = Configuration.sharedInstance.dataFilePath()
    let videoListPath = Configuration.sharedInstance.videoListPath()
    let audioListPath = Configuration.sharedInstance.audioListPath()
    let bandfolderPath = Configuration.sharedInstance.bandfolderPath()
    let bandfolderDirectoryPath = Configuration.sharedInstance.bandfolderDirectoryPath()
    
    var player = AVAudioPlayer()
    var currentPlayingIndex: Int = 0

    var playerState: PlayerState = .finish
    var selectedIndex: Int = 0
    var page = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Test
        print(bandfolderPath)
        
        checkDirectory()
        loadData()
        
        scrollView.delegate = self
        originalCollectionView.delegate = self
        originalCollectionView.dataSource = self
        convertedTableView.delegate = self
        convertedTableView.dataSource = self
        
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

        let imagePicker = ImagePickerController()
        imagePicker.settings.selection.max = 20
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.video]
        imagePicker.doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)

        self.presentImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { (assets) in
            
            for asset in assets {
                
                var videoURL: URL!
                var outputURLString = String()
                asset.getURL { url in
                    guard let url = url else { return }
                    videoURL = url
                    let fileName = videoURL.lastPathComponent
                    outputURLString = "file://" + self.dataFilePath + "/videos/\(fileName)"
                }
                
                PHImageManager.default().requestExportSession(forVideo: asset, options: nil, exportPreset: AVAssetExportPresetHighestQuality) { (exportSession, _) in

                    exportSession?.outputFileType = AVFileType.mov
                    exportSession?.outputURL = URL(string: outputURLString)
                    exportSession?.exportAsynchronously{

                        self.videoManager.addVideo(url: videoURL)
                        self.recordVideo()

                        DispatchQueue.main.async {
                            self.originalCollectionView.reloadData()
                        }
                    }
                }
            }
        })
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
        
        let oldCell: AudioPreviewTableViewCell?
        
        if currentPlayingIndex < audioManager.getNumOfAudios() {
            oldCell = convertedTableView.cellForRow(at: IndexPath(row: currentPlayingIndex, section: 0)) as? AudioPreviewTableViewCell
        } else {
            oldCell = nil
        }
        oldCell?.triangleImage.isHidden = true
        
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
                oldCell?.audioProgressView.pause()
            } else {
                player.stop()
                oldCell?.playButton.setBackgroundImage(#imageLiteral(resourceName: "Play.circle"), for: .normal)
                oldCell?.audioProgressView.reset()
                
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
                oldCell?.audioProgressView.resume()
            } else {
                player.stop()
                oldCell?.audioProgressView.reset()
                
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
    
    /* 切换到原视频界面 */
    @IBAction func toggleToOriginal(_ sender: UIButton) {
        page = 0
        updateUI()
        player.stop()
    }
    
    /* 切换到已转换界面 */
    @IBAction func toggleToConverted(_ sender: UIButton) {
        page = 1
        updateUI()
    }
    
    /* 更新所有用户界面 */
    func updateUI() {
        
        // 切换按钮样式
        if page == 0 {
            
            let distance = originalButton.center.x - indicator.center.x
            
            UIView.animate(withDuration: 0.1) {
                self.originalButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
                self.originalButton.alpha = 1.0
                self.indicator.transform = CGAffineTransform(translationX: distance, y: 0)
                self.convertedButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
                self.convertedButton.alpha = 0.18
            }
        } else {
            
            let distance = convertedButton.center.x - indicator.center.x
            
            UIView.animate(withDuration: 0.1) {
                self.originalButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
                self.originalButton.alpha = 0.18
                self.indicator.transform = CGAffineTransform(translationX: distance, y: 0)
                self.convertedButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
                self.convertedButton.alpha = 1.0
            }
        }
        
        // 根据是否存在已转换音频，显示不同界面
        if audioManager.getNumOfAudios() == 0 {
            nothingConvertedView.isHidden = false
            convertedTableView.isHidden = true
        } else {
            nothingConvertedView.isHidden = true
            convertedTableView.isHidden = false
        }
        
        // 界面滑动
        scrollToPage(page: page, animated: true)
    }
    
    /* 界面滑动效果，滑到指定页（页号从0开始） */
    func scrollToPage(page: Int, animated: Bool) {
        var frame: CGRect = scrollView.frame
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        self.scrollView.scrollRectToVisible(frame, animated: animated)
    }
    
    /* 手指滑动页面 */
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        page = Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        updateUI()
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
        
        // Bandfolder
        if (!FileManager.default.fileExists(atPath: bandfolderPath)) {
            do {
                try FileManager.default.copyItem(atPath: Bundle.main.path(forResource: "bandfolder.band", ofType: nil)!, toPath: bandfolderPath)
            } catch {
                print("Create directory error.")
            }
        }
        
        // Bandfolder Directory
        if (!FileManager.default.fileExists(atPath: bandfolderDirectoryPath)) {
            do {
                try FileManager.default.createDirectory(atPath: bandfolderDirectoryPath, withIntermediateDirectories: false, attributes: nil)
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
        cell.audioProgressView.duration = CGFloat(audioManager.audios[indexPath.row].duration)
        cell.audioProgressView.wave = audioManager.audios[indexPath.row].wave
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
    
    func ringtone(_ audioPreviewTableViewCell: UITableViewCell, index: Int) {
        
        let copyAtPath = Configuration.sharedInstance.bandfolderPath()
        let copyToPath = Configuration.sharedInstance.bandfolderDirectoryPath() + "/\(audioManager.getTitle(at: index)).band"
        do {
            try FileManager.default.copyItem(atPath: copyAtPath, toPath: copyToPath)
        } catch {
            print(error)
        }
        
        let audioURL = audioManager.getURL(at: index)
        let aiffURL = URL(fileURLWithPath: "\(copyToPath)/Media/ringtone.aiff")
        
        AudioConverter.sharedInstance.convertAudioToAIFF(audioURL, outputURL: aiffURL)
        
        let activityViewController = UIActivityViewController(activityItems: [URL(fileURLWithPath: copyToPath)], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }
    
    func share(_ audioPreviewTableViewCell: UITableViewCell, index: Int) {
        let audioURL = audioManager.getURL(at: index)
        let activityViewController = UIActivityViewController(activityItems: [audioURL], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }
    
    func rename(_ audioPreviewTableViewCell: UITableViewCell, index: Int) {
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
    
    func clip(_ audioPreviewTableViewCell: UITableViewCell, index: Int) {
        performSegue(withIdentifier: "Clip Audio", sender: nil)
    }
    
    func delete(_ audioPreviewTableViewCell: UITableViewCell, index: Int) {
        let deleteAlert = UIAlertController(title: "删除", message: "确认删除该文件吗？", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let confirmAction = UIAlertAction(title: "确认", style: .default) { action in
            
            guard let type = self.audioManager.getType(at: index) else { return }
            let title = self.audioManager.getTitle(at: index)
            let path = self.dataFilePath + "/audios/\(title).\(type.string)"
            
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print("Delete error")
            }
            
            if self.currentPlayingIndex == index {
                let cell = self.convertedTableView.cellForRow(at: IndexPath(row: self.currentPlayingIndex, section: 0)) as? AudioPreviewTableViewCell
                cell?.triangleImage.isHidden = true
                cell?.audioProgressView.reset()
                cell?.playButton.setBackgroundImage(#imageLiteral(resourceName: "Play.circle"), for: .normal)
                self.player.stop()
                self.playerState = .finish
            }
            
            self.audioManager.removeAudio(at: index)
            if self.audioManager.getNumOfAudios() == 0 {
                self.nothingConvertedView.isHidden = false
                self.convertedTableView.isHidden = true
            }
            self.convertedTableView.reloadData()
            self.recordAudio()
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
