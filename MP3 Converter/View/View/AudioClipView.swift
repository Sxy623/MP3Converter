//
//  AudioClipView.swift
//  MP3 Converter
//
//  Created by 沈心逸 on 2020/2/25.
//  Copyright © 2020 Xinyi Shen. All rights reserved.
//

import UIKit

protocol AudioClipViewDelegate {
    func touchBegan(_ audioClipView: AudioClipView)
    func touchMove(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat)
    func touchEnd(_ audioClipView: AudioClipView, startPercentage: CGFloat, endPercentage: CGFloat)
}

class AudioClipView: UIView {
    
    var wave: [CGFloat] = []
    var delegate: AudioClipViewDelegate?
    var parentScrollView: UIScrollView?
    var startLabel: UILabel?
    var endLabel: UILabel?
    
    var lineMargin: CGFloat = 3.0
    var lineWidth: CGFloat = 3.0
    
    var leadingSpace: CGFloat = 16.0
    var trailingSpace: CGFloat = 16.0
    var waveHeight: CGFloat = 24.0
    var waveWidth: CGFloat {
        return self.frame.size.width - leadingSpace - trailingSpace
    }
    var clipHeight: CGFloat = 50.0
    var spaceToLabel: CGFloat = 11.0
    
    var backgroundLineColor = UIColor(red: 1.00, green: 0.37, blue: 0.34, alpha: 0.3).cgColor
    var foregroundLineColor = UIColor(red: 1.00, green: 0.37, blue: 0.34, alpha: 1.0).cgColor
    
    var backgroundLineLayer = CAShapeLayer()
    var foregroundLineLayer = CAShapeLayer()
    var maskLayer = CAShapeLayer()
    var clipLayer = CAShapeLayer()
    var playerLayer = CAShapeLayer()
    
    var startPercentage: CGFloat = 0.0
    var currentPercentage: CGFloat = 0.0
    var endPercentage: CGFloat = 1.0
    var selectableArea: CGFloat = 0.01
    var minDistance: CGFloat = 0.05
    
    enum Choice { case empty, start, end }
    
    var choice: Choice = .empty
    
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
        
        playerLayer.lineWidth = 2
        playerLayer.fillColor = UIColor.clear.cgColor
        playerLayer.lineCap = CAShapeLayerLineCap.round
        playerLayer.strokeColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor
        layer.addSublayer(playerLayer)
        updatePlayer()
        
        updateProgressLabel()
    }
    
    func setStartPercentage(_ percentage: CGFloat) {
        startPercentage = CGFloat.clamp(percentage, 0.0, endPercentage - minDistance)
        maskLayer.strokeStart = startPercentage
        updateClip()
    }
    
    func setEndPercentage(_ percentage: CGFloat) {
        endPercentage = CGFloat.clamp(percentage, startPercentage + minDistance, 1.0)
        maskLayer.strokeEnd = endPercentage
        updateClip()
    }
    
    func initLineLayer() {
        let path = UIBezierPath()
        let maxWidth = self.frame.size.width
        var x: CGFloat = leadingSpace + lineWidth / 2
        var pos = 0
        while x + lineWidth / 2 + trailingSpace <= maxWidth {
            let random = wave[pos] * waveHeight
            pos = (pos + 1) % wave.count
            path.move(to: CGPoint(x: x, y: self.frame.size.height / 2 - random))
            path.addLine(to: CGPoint(x: x, y: self.frame.size.height / 2 + random))
            x += lineWidth
            x += lineMargin
        }
        self.backgroundLineLayer.path = path.cgPath
        self.foregroundLineLayer.path = path.cgPath
    }
    
    func addMask() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: leadingSpace, y: self.frame.size.height / 2))
        path.addLine(to: CGPoint(x: self.frame.size.width - trailingSpace, y: self.frame.size.height / 2))
        
        self.maskLayer.frame = self.bounds
        self.maskLayer.lineWidth = self.frame.size.width
        self.maskLayer.path = path.cgPath
        self.foregroundLineLayer.mask = self.maskLayer
    }
    
    func updateClip() {
        let startX = leadingSpace + waveWidth * startPercentage
        let endX = leadingSpace + waveWidth * endPercentage
        let path = UIBezierPath()
        path.move(to: CGPoint(x: startX, y: self.frame.size.height / 2 - clipHeight / 2))
        path.addLine(to: CGPoint(x: startX, y: self.frame.size.height / 2 + clipHeight / 2))
        path.move(to: CGPoint(x: endX, y: self.frame.size.height / 2 - clipHeight / 2))
        path.addLine(to: CGPoint(x: endX, y: self.frame.size.height / 2 + clipHeight / 2))
        self.clipLayer.path = path.cgPath
    }
    
    func updatePlayer() {
        let x = leadingSpace + waveWidth * currentPercentage
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: self.frame.size.height / 2 - clipHeight / 2))
        path.addLine(to: CGPoint(x: x, y: self.frame.size.height / 2 + clipHeight / 2))
        self.playerLayer.path = path.cgPath
    }
    
    func updateProgressLabel() {
        
        let centerY = self.frame.size.height / 2 + clipHeight / 2 + spaceToLabel
        
        let startX = leadingSpace + waveWidth * startPercentage
        startLabel?.center = CGPoint(x:  startX, y: centerY)
        
        let endX = leadingSpace + waveWidth * endPercentage
        endLabel?.center = CGPoint(x: endX, y: centerY)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let xPosition = touches.first?.location(in: self).x else { return }
        let percentage = (xPosition - leadingSpace) / waveWidth
//        let midPercentage = (startPercentage + endPercentage) / 2
        if percentage > startPercentage - selectableArea && percentage < startPercentage + selectableArea {
            choice = .start
            parentScrollView?.isScrollEnabled = false
            delegate?.touchBegan(self)
        } else if percentage > endPercentage - selectableArea && percentage < endPercentage + selectableArea {
            choice = .end
            parentScrollView?.isScrollEnabled = false
            delegate?.touchBegan(self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let xPosition = touches.first?.location(in: self).x else { return }
        let percentage = (xPosition - leadingSpace) / waveWidth
        switch choice {
        case .start:
            setStartPercentage(percentage)
        case .end:
            setEndPercentage(percentage)
        default:
            break
        }
        updateProgressLabel()
        delegate?.touchMove(self, startPercentage: startPercentage, endPercentage: endPercentage)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if choice == .empty { return }
        choice = .empty
        parentScrollView?.isScrollEnabled = true
        delegate?.touchEnd(self, startPercentage: startPercentage, endPercentage: endPercentage)
    }
}
