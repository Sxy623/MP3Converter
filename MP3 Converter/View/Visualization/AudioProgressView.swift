//
//  AudioProgressView.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/25.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

class AudioProgressView: UIView, CAAnimationDelegate {
    
    var lineMargin: CGFloat = 3.0
    var lineWidth: CGFloat = 3.0
    
    var backgroundLineColor = CGColor(srgbRed: 1.00, green: 0.37, blue: 0.34, alpha: 0.3)
    var foregroundLineColor = CGColor(srgbRed: 1.00, green: 0.37, blue: 0.34, alpha: 1.0)
    
    var backgroundLineLayer = CAShapeLayer()
    var foregroundLineLayer = CAShapeLayer()
    var maskLayer = CAShapeLayer()
    
    var percentage: CGFloat = 0
    var time: CGFloat = 10
    
    func initLayers() {
        
        backgroundColor = .clear
        
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
        maskLayer.strokeEnd = percentage
        addMask()
    }
    
    func setPercentageWithAnimation(percentage: CGFloat) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        let from = self.percentage
        let to = percentage
        animation.duration = CFTimeInterval(time * (to - from))
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fromValue = from
        animation.toValue = to
        animation.autoreverses = false
        animation.delegate = self
        maskLayer.add(animation, forKey: nil)
    }
    
    func initLineLayer() {
        let path = UIBezierPath()
        let maxWidth = self.frame.size.width
        let height = self.frame.size.height
        var x: CGFloat = 0.0
        while x + lineWidth <= maxWidth {
            let random = CGFloat.random(in: 0...0.5) * height
            path.move(to: CGPoint(x: x - lineWidth / 2, y: random))
            path.addLine(to: CGPoint(x: x - lineWidth / 2, y: height - random))
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
    
    func play() {
        setPercentageWithAnimation(percentage: 1.0)
    }
    
    func pause() {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func resume(){
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    func reset(){
        maskLayer.removeAllAnimations()
    }
}
