//
//  ExtractAudioViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class ExtractAudioViewController: UIViewController {
    
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
            print(ranameAlert.textFields?[0].text)
            self.navigationController?.popViewController(animated: true)
        }
        ranameAlert.addAction(cancelAction)
        ranameAlert.addAction(confirmAction)
        ranameAlert.preferredAction = confirmAction
        
        present(ranameAlert, animated: true, completion: nil)
    }
}
