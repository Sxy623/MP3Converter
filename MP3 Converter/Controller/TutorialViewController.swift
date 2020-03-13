//
//  TutorialViewController.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/3/10.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {
    
    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var step2Label: UILabel!
    @IBOutlet weak var step3Label: UILabel!
    @IBOutlet weak var step4Label: UILabel!
    
    let tint = UIColor(red: 0.0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let step1String = NSMutableAttributedString(string: "1. 点击“制作铃声”图标后，在弹窗中找到并点击库乐队\n的图标。如果没有找到，可以点击“更多”并在应用列表\n中找到库乐队。", attributes: nil)
        step1String.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 6, length: 4))
        step1String.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 24, length: 3))
        step1String.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 44, length: 2))
        step1Label.attributedText = step1String
        
        let step2String = NSMutableAttributedString(string: "2. 将音乐分享到库乐队以后，在库乐队中长按项目文件\n调出菜单，并点击“分享”。", attributes: nil)
        step2String.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 20, length: 6))
        step2String.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 36, length: 2))
        step2Label.attributedText = step2String
        
        let step3String = NSMutableAttributedString(string: "3. 在分享歌曲页面中，选择“铃声”格式，并为新的铃声\n命名，点击“导出”即可完成。", attributes: nil)
        step3String.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 15, length: 2))
        step3String.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 34, length: 2))
        step3Label.attributedText = step3String
        
        let step4String = NSMutableAttributedString(string: "4. 最后一步，只要在“设置 > 声音与触感 > 铃声” 中\n设置自己喜欢的铃声即可。", attributes: nil)
        step4String.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 12, length: 15))
        step4Label.attributedText = step4String
    }
    
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func downloadButtonPressed(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/id408709785")!)
    }
    
}
