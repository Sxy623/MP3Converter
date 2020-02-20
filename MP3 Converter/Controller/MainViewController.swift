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

class MainViewController: UIViewController {
    
    @IBOutlet weak var originalCollectionView: UICollectionView!
    @IBOutlet weak var nothingConvertedView: UIView!
    @IBOutlet weak var convertedTableView: UITableView!
    @IBOutlet weak var originalButton: UIButton!
    @IBOutlet weak var originalIndicator: UIImageView!
    @IBOutlet weak var convertedButton: UIButton!
    @IBOutlet weak var convertedIndicator: UIImageView!
    
    let videoManager = VideoManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let uploadFromAlbumAction = UIAlertAction(title: "从相册上传", style: .default) { (action) in
            self.uploadVideoFromAlbum()
        }
        let uploadFromFilesAction = UIAlertAction(title: "从文件上传", style: .default) { (action) in
            self.uploadVideoFromFiles()
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        optionMenu.addAction(uploadFromAlbumAction)
        optionMenu.addAction(uploadFromFilesAction)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func uploadVideoFromAlbum() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.movie"]
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func uploadVideoFromFiles() {
        let types = [String(kUTTypeMPEG4)]
        let documentPickerViewController = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPickerViewController.delegate = self
        present(documentPickerViewController, animated: true, completion: nil)
    }
    
    // MARK: - Extract Audio
    
    func extractAudio() {
        performSegue(withIdentifier: "extractAudio", sender: nil)
    }
    
    // MARK: - User Interface
    
    @IBAction func toggleToOriginal(_ sender: UIButton) {
        originalButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        originalIndicator.alpha = 1.0
        convertedButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.18), for: .normal)
        convertedIndicator.alpha = 0.0
        originalCollectionView.isHidden = false
        nothingConvertedView.isHidden = true
    }
    
    @IBAction func toggleToConverted(_ sender: UIButton) {
        originalButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.18), for: .normal)
        originalIndicator.alpha = 0.0
        convertedButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        convertedIndicator.alpha = 1.0
        originalCollectionView.isHidden = true
        nothingConvertedView.isHidden = false
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Settings" {
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        } else if segue.identifier == "Extract Audio" {
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "原视频", style: .plain, target: nil, action: nil)
        }
    }
}

// MARK: - CollectionView Delegate

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoManager.getNumOfVideos() + 1
    }
    
    //    func collectionView(_ collectionView: UICollectionView,
    //        layout collectionViewLayout: UICollectionViewLayout,
    //        sizeForItemAt indexPath: IndexPath) -> CGSize {
    //    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.item
        
        if index == 0 {
            
            let cell = originalCollectionView.dequeueReusableCell(withReuseIdentifier: "Add Video", for: indexPath) as! AddVideoCollectionViewCell
            cell.rootViewController = self
            return cell
            
        } else {
            
            let cell = originalCollectionView.dequeueReusableCell(withReuseIdentifier: "Video Preview", for: indexPath) as! VideoPreviewCollectionViewCell
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
        videoManager.addVideo(url: videoURL)
        originalCollectionView.reloadData()
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - DocumentPicker Delegate

extension MainViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            videoManager.addVideo(url: url)
        }
        originalCollectionView.reloadData()
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TableView Delegate

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = convertedTableView.dequeueReusableCell(withIdentifier: "Audio Preview", for: indexPath) as! AudioPreviewTableViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
