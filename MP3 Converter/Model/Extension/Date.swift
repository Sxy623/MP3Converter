//
//  Date.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/3/10.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import Foundation

extension Date {
    
    static var currentDate: String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MMdd-HHmmss"
        return formatter.string(from: date)
    }
    
}
