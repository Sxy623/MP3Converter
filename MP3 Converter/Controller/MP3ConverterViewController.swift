//
//  MP3ConverterViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/19.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import AVFoundation
import CoreServices

class MP3ConverterViewController: UIViewController {
    
    @IBOutlet weak var originalCollectionView: UICollectionView!
    @IBOutlet weak var nothingConvertedView: UIView!
    @IBOutlet weak var originalButton: UIButton!
    @IBOutlet weak var originalIndicator: UIImageView!
    @IBOutlet weak var convertedButton: UIButton!
    @IBOutlet weak var convertedIndicator: UIImageView!
    
    let videoManager = VideoManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalCollectionView.delegate = self
        originalCollectionView.dataSource = self
    }
    
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
}

/* UICollectionView Delegate */

extension MP3ConverterViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
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
            cell.previewImageView.image = videoManager.getPreviewImage(at: index - 1)
            cell.durationTimeLabel.text = videoManager.getDurationTime(at: index - 1)
            return cell
            
        }
    }
}

/* UIImagePickerController Delegate */

extension MP3ConverterViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let videoURL = info[.mediaURL] as! URL
        videoManager.addVideo(url: videoURL)
        originalCollectionView.reloadData()
        picker.dismiss(animated: true, completion: nil)
    }
}

/* UIDocumentPicker Delegate */

extension MP3ConverterViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            videoManager.addVideo(url: url)
        }
        originalCollectionView.reloadData()
        controller.dismiss(animated: true, completion: nil)
    }
}
