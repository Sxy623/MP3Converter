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
    var rootView: UIView!
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
    var selectedAreaColor = UIColor(red: 1.00, green: 0.37, blue: 0.34, alpha: 0.1).cgColor
    
    var backgroundLineLayer = CAShapeLayer()
    var foregroundLineLayer = CAShapeLayer()
    var selectedAreaLayer = CAShapeLayer()
    var maskLayer = CAShapeLayer()
    var clipLayer = CAShapeLayer()
    var playerLayer = CAShapeLayer()
    
    var startPercentage: CGFloat = 0.0
    var currentPercentage: CGFloat = 0.0
    var endPercentage: CGFloat = 1.0
    var selectableArea: CGFloat = 0.05
    var minDistance: CGFloat = 0.05
    var minLabelDistance: CGFloat = 35.0
    
    var touches: Set<UITouch>!
    var event: UIEvent?
    
    enum Direction { case empty, left, right }
    var timer = Timer()
    let interval = 0.02
    var currentXPosition: CGFloat = 0
    var scrollDirection: Direction = .empty
    let scrollMargin: CGFloat = 20
    let scrollSpeed: CGFloat = 5
    
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
        
        selectedAreaLayer.lineWidth = clipHeight
        selectedAreaLayer.fillColor = UIColor.clear.cgColor
        selectedAreaLayer.lineCap = CAShapeLayerLineCap.round
        selectedAreaLayer.strokeColor = selectedAreaColor
        layer.addSublayer(selectedAreaLayer)
        
        initSelectedAreaLayer()
        
        maskLayer.strokeColor = UIColor.black.cgColor
        maskLayer.strokeStart = startPercentage
        maskLayer.strokeEnd = endPercentage
        addMask()
        
        clipLayer.lineWidth = 1
        clipLayer.fillColor = UIColor.clear.cgColor
        clipLayer.lineCap = CAShapeLayerLineCap.round
        clipLayer.strokeColor = foregroundLineColor
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
    
    func initSelectedAreaLayer() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: leadingSpace, y: self.frame.size.height / 2))
        path.addLine(to: CGPoint(x: self.frame.size.width - trailingSpace, y: self.frame.size.height / 2))
        self.selectedAreaLayer.path = path.cgPath
    }
    
    func addMask() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: leadingSpace, y: self.frame.size.height / 2))
        path.addLine(to: CGPoint(x: self.frame.size.width - trailingSpace, y: self.frame.size.height / 2))
        
        self.maskLayer.frame = self.bounds
        self.maskLayer.lineWidth = self.frame.size.width
        self.maskLayer.path = path.cgPath
        self.foregroundLineLayer.mask = self.maskLayer
        self.selectedAreaLayer.mask = self.maskLayer
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
        
        var startX = leadingSpace + waveWidth * startPercentage
        var endX = leadingSpace + waveWidth * endPercentage
        
        // 处理距离过近的情况
        if endX - startX < minLabelDistance {
            let midX = (startX + endX) / 2
            startX = midX - minLabelDistance / 2
            endX = midX + minLabelDistance / 2
        }
        
        startLabel?.center = CGPoint(x:  startX, y: centerY)
        endLabel?.center = CGPoint(x: endX, y: centerY)
    }
    
    func startScroll() {
        timer = Timer(timeInterval: interval, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
    }
    
    func endScroll() {
        timer.invalidate()
    }
    
    @objc func updateTimer() {
        
        if scrollDirection == .left {
            currentXPosition = currentXPosition - scrollSpeed
            touchesMoved(touches, with: event)
        } else if scrollDirection == .right {
            currentXPosition = currentXPosition + scrollSpeed
            touchesMoved(touches, with: event)
        }
        parentScrollView?.scrollRectToVisible(CGRect(x: currentXPosition, y: 0, width: 1, height: 1), animated: false)
        updateProgressLabel()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let xPosition = touches.first?.location(in: self).x else { return }
        let percentage = (xPosition - leadingSpace) / waveWidth
        if percentage > startPercentage - selectableArea && percentage < startPercentage + selectableArea {
            choice = .start
//            parentScrollView?.isScrollEnabled = false
            delegate?.touchBegan(self)
        } else if percentage > endPercentage - selectableArea && percentage < endPercentage + selectableArea {
            choice = .end
//            parentScrollView?.isScrollEnabled = false
            delegate?.touchBegan(self)
        } else {
//            parentScrollView?.isScrollEnabled = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touches = touches
        self.event = event
        
        guard let touch = touches.first else { return }
        let xPosition = touch.location(in: self).x
//        let xInRootView = touch.location(in: rootView).x
        
        // 屏幕滚动
//        if xInRootView < scrollMargin {
//            if scrollDirection == .empty {
//                currentXPosition = xPosition
//                scrollDirection = .left
//                startScroll()
//            }
//        } else if xInRootView > rootView.frame.width - scrollMargin {
//            if scrollDirection == .empty {
//                currentXPosition = xPosition
//                scrollDirection = .right
//                startScroll()
//            }
//        } else {
//            if scrollDirection != .empty {
//                scrollDirection = .empty
//                endScroll()
//            }
//        }
        
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
//        if scrollDirection != .empty {
//            scrollDirection = .empty
//            endScroll()
//        }
        
        if choice == .empty { return }
        choice = .empty
//        parentScrollView?.isScrollEnabled = false
        delegate?.touchEnd(self, startPercentage: startPercentage, endPercentage: endPercentage)
    }
}
