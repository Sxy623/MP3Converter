//
//  SettingsTableViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/20.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit
import StoreKit
import MessageUI

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var videoTypeLabel: UILabel!
    @IBOutlet weak var audioTypeLabel: UILabel!
    
    let headerTitles = ["", "关于MP3转换器"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.968627451, alpha: 1)
        updateUI()
    }
    
    func changeVideoType() {
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        VideoType.allCases.forEach { type in
            let action = UIAlertAction(title: type.string, style: .default) { action in
                Configuration.sharedInstance.videoType = type
                self.updateUI()
            }
            optionMenu.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func changeAudioType() {
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        AudioType.allCases.forEach { type in
            let action = UIAlertAction(title: type.string, style: .default) { action in
                Configuration.sharedInstance.audioType = type
                self.updateUI()
            }
            optionMenu.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func rateApp() {
        SKStoreReviewController.requestReview()
    }
    
    func adviseApp() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["feedback@enjoymusic.ai"])
            mail.setSubject("MP3转换器 用户反馈")
            present(mail, animated: true)
        } else {
            print("Mail services are not available")
        }
    }
    
    func shareApp() {
//        let urlString = ""
//        let activityViewController = UIActivityViewController(activityItems: [URL(string: urlString)!], applicationActivities: [])
//        present(activityViewController, animated: true, completion: nil)
    }
    
    func updateUI() {
        videoTypeLabel.text = Configuration.sharedInstance.videoType.string
        audioTypeLabel.text = Configuration.sharedInstance.audioType.string
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 3
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 38))
        headerView.backgroundColor = tableView.backgroundColor
        
        let headerLabel = UILabel(frame: CGRect(x: 16, y: 14, width: view.frame.size.width, height: 18))
        headerLabel.text = headerTitles[section]
        headerLabel.font = .systemFont(ofSize: 13.0, weight: .regular)
        headerLabel.textColor = #colorLiteral(red: 0.2352941176, green: 0.2352941176, blue: 0.262745098, alpha: 0.6)
        headerView.addSubview(headerLabel)
        
        return headerView
    }
    
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 19))
        footerView.backgroundColor = tableView.backgroundColor
        
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                changeVideoType()
            case 1:
                changeAudioType()
            case 2:
                performSegue(withIdentifier: "Ringtone Tutorial", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                rateApp()
            case 1:
                adviseApp()
            case 2:
                shareApp()
            default:
                break
            }
        default:
            break
        }
    }
}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
