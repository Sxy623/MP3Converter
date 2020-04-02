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
import MBProgressHUD

class MainViewController: UIViewController {
    
    @IBOutlet weak var originalButton: UIButton!
    @IBOutlet weak var convertedButton: UIButton!
    @IBOutlet weak var indicator: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var originalCollectionView: UICollectionView!
    @IBOutlet weak var nothingConvertedView: UIView!
    @IBOutlet weak var convertedTableView: UITableView!
    @IBOutlet weak var gradientView: UIView!
    
    let defaults = UserDefaults.standard
    
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
        print(dataFilePath)
        
        if defaults.object(forKey: "ShowTutorial") == nil {
            defaults.set(true, forKey: "ShowTutorial")
        }
        
        checkDirectory()
        loadData()
        
        scrollView.delegate = self
        originalCollectionView.delegate = self
        originalCollectionView.dataSource = self
        convertedTableView.delegate = self
        convertedTableView.dataSource = self
        convertedTableView.separatorColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1)
        convertedTableView.separatorInset = UIEdgeInsets(top: 0, left: 31, bottom: 0, right: 0)
        convertedTableView.tableFooterView = UIView()
        
        updateUI()
        
        
        // Play sound in silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.hideHairline()
        if #available(iOS 13.0, *) {
            let attributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
            navigationController?.navigationBar.standardAppearance.titleTextAttributes = attributes
        }
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
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.label.text = "正在载入视频"
            hud.backgroundView.blurEffectStyle = .regular
            hud.graceTime = 1
            
            for asset in assets {
                
                let option = PHVideoRequestOptions()
                option.isNetworkAccessAllowed = true
                option.version = .original
                option.progressHandler = { (progress, error, stop, info) in
                    DispatchQueue.main.async {
                        hud.label.text = "正在从 iCloud 载入视频"
                    }
                }

                let operation = BlockOperation {
                    PHImageManager.default().requestAVAsset(forVideo: asset, options: option) { (asset, audioMix, info) in
                        if let asset = asset as? AVURLAsset, let videoData = try? Data(contentsOf: asset.url) {
                            let fileName = Date.currentDate + asset.url.lastPathComponent
                            let outputURL = URL(fileURLWithPath: self.dataFilePath + "/videos/\(fileName)")
                            try? videoData.write(to: outputURL)
                            self.videoManager.addNewVideo(url: outputURL)
                            self.recordVideo()
                            DispatchQueue.main.async {
                                self.originalCollectionView.reloadData()
                                hud.hide(animated: true)
                            }
                        } else {
                            DispatchQueue.main.async {
                                hud.label.text = "载入失败，请重试"
                                hud.hide(animated: true, afterDelay: 1)
                            }
                        }
                    }
                }
                queue.addOperation(operation)
            }
        })
    }
    
    func uploadVideoFromFiles() {
        let types = ["public.movie"]
        let documentPickerViewController = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPickerViewController.delegate = self
        documentPickerViewController.allowsMultipleSelection = true
        present(documentPickerViewController, animated: true, completion: nil)
    }
    
    // MARK: - Extract Audio
    
    func extractAudio() {
        performSegue(withIdentifier: "Extract Audio", sender: nil)
    }
    
    func addAudio(url: URL) {
        audioManager.addNewAudio(url: url)
        recordAudio()
        convertedTableView.reloadData()
        page = 1
        updateUI()
    }
    
    // MARK: - Player ManagerNew
    
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
//                player = try! AVPlayer(url: audioManager.getURL(at: index))
            player = try! AVAudioPlayer(data: Data(contentsOf: audioManager.getURL(at: index)), fileTypeHint: AVFileType.mp3.rawValue)
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
//                player = try! AVPlayer(url: audioManager.getURL(at: index))
                player = try! AVAudioPlayer(data: Data(contentsOf: audioManager.getURL(at: index)), fileTypeHint: AVFileType.mp3.rawValue)
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
//                player = try! AVPlayer(url: audioManager.getURL(at: index))
                player = try! AVAudioPlayer(data: Data(contentsOf: audioManager.getURL(at: index)), fileTypeHint: AVFileType.mp3.rawValue)
                player.delegate = self
                player.play()
                playerState = .play
                newCell.audioProgressView.play()
            }
        }
        
        newCell.triangleImage.isHidden = false
    }
    
    func stopAudio() {
        if playerState == .pause || playerState == .play {
            player.stop()
            playerState = .finish
            let cell = convertedTableView.cellForRow(at: IndexPath(row: currentPlayingIndex, section: 0)) as! AudioPreviewTableViewCell
            cell.audioProgressView.reset()
            cell.playButton.setBackgroundImage(#imageLiteral(resourceName: "Play.circle"), for: .normal)
        }
    }
    
    // MARK: - User Interface
    
    /* 切换到原视频界面 */
    @IBAction func toggleToOriginal(_ sender: UIButton) {
        page = 0
        updateUI()
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
        let pageWidth = self.scrollView.frame.size.width
        page = Int(floor(self.scrollView.contentOffset.x / pageWidth))
        updateUI()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Settings" {
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        } else if segue.identifier == "Extract Audio" {
            stopAudio()
            let destinationViewController = segue.destination as! ExtractAudioViewController
            destinationViewController.rootViewController = self
            destinationViewController.delegate = self
            destinationViewController.video = videoManager.videos[selectedIndex]
            destinationViewController.index = selectedIndex
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        } else if segue.identifier == "Clip Audio" {
            stopAudio()
            let destinationViewController = segue.destination as! ClipAudioViewController
            destinationViewController.rootViewController = self
            destinationViewController.audio = audioManager.audios[selectedIndex]
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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
                let videoURLString = dataFilePath + "/videos/\(videoFileName)"
                let videoURL = URL(fileURLWithPath: videoURLString)
                videoManager.appendVideo(url: videoURL)
            }
            originalCollectionView.reloadData()
        }
        
        // Load audios
        if FileManager.default.fileExists(atPath: audioListPath) {
            let array = NSArray(contentsOfFile: audioListPath) as! [String]
            for audioFileName in array {
                let audioURLString = dataFilePath + "/audios/\(audioFileName)"
                let audioURL = URL(fileURLWithPath: audioURLString)
                audioManager.appendAudio(url: audioURL)
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

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 33) / 3
        return CGSize(width: width, height: width)
    }
    
}

// MARK: - DocumentPicker Delegate

extension MainViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for videoURL in urls {
            
            let asset = AVURLAsset(url: videoURL)
            
            if let videoData = try? Data(contentsOf: asset.url) {
                print(asset.url)
                let fileName = Date.currentDate + asset.url.lastPathComponent
                let outputURL = URL(fileURLWithPath: self.dataFilePath + "/videos/\(fileName)")
                try? videoData.write(to: outputURL)
                self.videoManager.addNewVideo(url: outputURL)
                self.recordVideo()
                DispatchQueue.main.async {
                    self.originalCollectionView.reloadData()
                }
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - ExtractAudioViewController Delegate

extension MainViewController: ExtractAudioViewControllerDelegate {
    
    func delete(_ ExtractAudioViewController: UIViewController, index: Int) {
        
        let fileName = videoManager.videos[index].fileName
        let path = dataFilePath + "/videos/\(fileName)"
        
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        
        videoManager.removeVideo(at: index)
        recordVideo()
        originalCollectionView.reloadData()
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
        cell.audioTitleLabel.text = audioManager.getURL(at: indexPath.row).lastPathComponent
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
        if let cell = tableView.cellForRow(at: indexPath) as? AudioPreviewTableViewCell {
            cell.playOrPause()
        }
    }
}

// MARK: - AudioPreviewTableView Delegate

extension MainViewController: AudioPreviewTableViewCellDelegate {
    
    func ringtone(_ audioPreviewTableViewCell: UITableViewCell, index: Int) {
        
        let showTutorial = defaults.bool(forKey: "ShowTutorial")
        if showTutorial {
            defaults.set(false, forKey: "ShowTutorial")
            performSegue(withIdentifier: "Ringtone Tutorial", sender: self)
            return
        }
        
        let copyAtPath = Configuration.sharedInstance.bandfolderPath()
        let copyToPath = Configuration.sharedInstance.bandfolderDirectoryPath() + "/\(audioManager.getTitle(at: index)).band"
        do {
            try FileManager.default.copyItem(atPath: copyAtPath, toPath: copyToPath)
        } catch {
            print(error)
        }
        
        let audioURL = audioManager.getURL(at: index)
        let aiffURL = URL(fileURLWithPath: "\(copyToPath)/Media/ringtone.aiff")
        
//        let converter = ExtAudioConverter()
//        converter.inputFile = audioURL.path
//        converter.outputFile = aiffURL.path
//        converter.convert()
        
        // MP3
        if audioManager.getType(at: index) == .mp3 {
            
            let asset = AVURLAsset(url: audioURL)
            let targetURL = audioURL.deletingPathExtension().appendingPathExtension("m4a")
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
            exportSession.outputFileType = .m4a
            exportSession.outputURL = targetURL
            
            exportSession.exportAsynchronously {
                
                guard case exportSession.status = AVAssetExportSession.Status.completed else {
                    print("\(String(describing: exportSession.error?.localizedDescription))")
                    return
                }
                
                AudioConverter.sharedInstance.convertAudioToAIFF(targetURL, outputURL: aiffURL)
                
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try? FileManager.default.removeItem(atPath: targetURL.path)
                }
            }
            
        } else {
            AudioConverter.sharedInstance.convertAudioToAIFF(audioURL, outputURL: aiffURL)
        }
        
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
//            textField.placeholder = self.audioManager.getTitle(at: index)
            textField.text = self.audioManager.getTitle(at: index)
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
