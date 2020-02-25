//
//  AudioClipView.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/25.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class AudioClipView: UIView {
    
    var lineMargin: CGFloat = 3.0
    var lineWidth: CGFloat = 3.0
    
    var backgroundLineColor = CGColor(srgbRed: 1.00, green: 0.37, blue: 0.34, alpha: 0.3)
    var foregroundLineColor = CGColor(srgbRed: 1.00, green: 0.37, blue: 0.34, alpha: 1.0)
    
    var backgroundLineLayer = CAShapeLayer()
    var foregroundLineLayer = CAShapeLayer()
    var maskLayer = CAShapeLayer()
    var clipLayer = CAShapeLayer()
    
    var startPercentage: CGFloat = 0.0
    var endPercentage: CGFloat = 1.0
    
    enum Choice { case empty, start, end }
    
    var choice: Choice = .end
    
    override func draw(_ rect: CGRect) {
        backgroundColor = .clear
        initLayers()
    }
    
    func initLayers() {
        backgroundLineLayer.lineWidth = lineWidth
        backgroundLineLayer.fillColor = UIColor.clear.cgColor
        backgroundLineLayer.lineCap = CAShapeLayerLineCap.round
        backgroundLineLayer.strokeColor = backgroundLineColor
        layer.addSublayer(backgroundLineLayer)
        
        foregroundLineLayer.lineWidth = lineWidth
        foregroundLineLayer.fillColor = UIColor.clear.cgColor
        foregroundLineLayer.lineCap = CAShapeLayerLineCap.round
        foregroundLineLayer.strokeColor = foregroundLineColor
        layer.addSublayer(foregroundLineLayer)
        
        initLineLayer()
        
        maskLayer.strokeColor = UIColor.black.cgColor
        maskLayer.strokeStart = startPercentage
        maskLayer.strokeEnd = endPercentage
        addMask()
        
        clipLayer.lineWidth = 1
        clipLayer.fillColor = UIColor.clear.cgColor
        clipLayer.lineCap = CAShapeLayerLineCap.round
        clipLayer.strokeColor = UIColor.gray.cgColor
        layer.addSublayer(clipLayer)
        updateClip()
    }
    
    func setStartPercentage(_ percentage: CGFloat) {
        startPercentage = percentage
        maskLayer.strokeStart = startPercentage
        updateClip()
    }
    
    func setEndPercentage(_ percentage: CGFloat) {
        endPercentage = percentage
        maskLayer.strokeEnd = endPercentage
        updateClip()
    }
    
    func initLineLayer() {
        let path = UIBezierPath()
        let maxWidth = self.frame.size.width
        let height = self.frame.size.height * 0.7
        var x: CGFloat = 0.0
        while x + lineWidth <= maxWidth {
            let random = CGFloat.random(in: 0...0.5) * height
            path.move(to: CGPoint(x: x - lineWidth / 2, y: self.frame.size.height / 2 - random))
            path.addLine(to: CGPoint(x: x - lineWidth / 2, y: self.frame.size.height / 2 + random))
            x += lineWidth
            x += lineMargin
        }
        self.backgroundLineLayer.path = path.cgPath
        self.foregroundLineLayer.path = path.cgPath
    }
    
    func addMask() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: self.frame.size.height / 2))
        path.addLine(to: CGPoint(x: self.frame.size.width, y: self.frame.size.height / 2))
        
        self.maskLayer.frame = self.bounds
        self.maskLayer.lineWidth = self.frame.size.width
        self.maskLayer.path = path.cgPath
        self.foregroundLineLayer.mask = self.maskLayer
    }
    
    func updateClip() {
        let startX = self.frame.size.width * startPercentage
        let endX = self.frame.size.width * endPercentage
        let path = UIBezierPath()
        path.move(to: CGPoint(x: startX, y: self.frame.size.height * 0.01))
        path.addLine(to: CGPoint(x: startX, y: self.frame.size.height * 0.99))
        path.move(to: CGPoint(x: endX, y: self.frame.size.height * 0.01))
        path.addLine(to: CGPoint(x: endX, y: self.frame.size.height * 0.99))
        self.clipLayer.path = path.cgPath
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let xPosition = touches.first?.location(in: self).x else { return }
        let percentage =  xPosition / self.frame.size.width
        let midPercentage = (startPercentage + endPercentage) / 2
        if percentage < midPercentage {
            choice = .start
        } else {
            choice = .end
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        choice = .empty
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let xPosition = touches.first?.location(in: self).x else { return }
        let percentage =  xPosition / self.frame.size.width
        switch choice {
        case .start:
            setStartPercentage(percentage)
        case .end:
            setEndPercentage(percentage)
        default:
            break
        }
    }
}
