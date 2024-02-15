//
//  PlayerPanelContentView.swift
//  CustomPlayer
//
//  Created by Paco on 27/1/2023.
//

import Foundation
import UIKit

protocol PlayerPanelContentViewDelegate: AnyObject {
    
    func playerPanelContentView(_ view: PlayerPanelContentView, playDidPressed button: UIControl)
    func playerPanelContentView(_ view: PlayerPanelContentView, pauseDidPressed button: UIControl)
    func playerPanelContentView(_ view: PlayerPanelContentView, replayDidPressed button: UIControl)
//    func playerPanelContentView(_ view: PlayerPanelContentView, muteDidPressed button: UIControl)
//    func playerPanelContentView(_ view: PlayerPanelContentView, unmuteDidPressed button: UIControl)
//    func playerPanelContentView(_ view: PlayerPanelContentView, fastForward value: Float)
//    func playerPanelContentView(_ view: PlayerPanelContentView, fastBackward value: Float)
    func playerPanelContentView(_ view: PlayerPanelContentView, receivedTapEvent recognizer: UITapGestureRecognizer)
}

class PlayerPanelContentView: UIView, UIGestureRecognizerDelegate {
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandle(recognizer:)))
        pan.delegate = self
        return pan
    }()
    
    lazy var tapGesture: UITapGestureRecognizer = {
        let pan = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandle(recognizer:)))
        pan.delegate = self
        return pan
    }()
    
    lazy var buttonWrapperView: UIView = {
        var v = UIView()
        return v
    }()
    
    lazy var playButton: UIButton = {
        let v = UIButton()
        let image = UIImage(systemName: "play.fill")?.withTintColor(SIPlayerTheme.mainTintColor())
        v.setImage(image, for: .normal)
        v.imageView?.contentMode = .scaleAspectFit
        v.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 30), forImageIn: .normal)
        v.tintColor = SIPlayerTheme.mainTintColor()
        v.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 45/2
        return v
    }()
    
    lazy var loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView()
        v.hidesWhenStopped = true
        v.tintColor = SIPlayerTheme.mainTintColor()
        return v
    }()
    
    lazy var pauseButton: UIButton = {
        let v = UIButton()
        let image = UIImage(systemName: "pause.fill")?.withTintColor(SIPlayerTheme.mainTintColor())
        v.setImage(image, for: .normal)
        v.imageView?.contentMode = .scaleAspectFit
        v.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 30), forImageIn: .normal)
        v.tintColor = SIPlayerTheme.mainTintColor()
        v.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 45/2
        return v
    }()
    
    lazy var replayButton: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(systemName: "goforward")?.withTintColor(SIPlayerTheme.mainTintColor()), for: .normal)
        
        v.imageView?.contentMode = .scaleAspectFit
        v.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 30), forImageIn: .normal)
        v.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        v.tintColor = SIPlayerTheme.mainTintColor()
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 45/2
        return v
    }()
    
//    lazy var soundButtonWrapperView: UIView = {
//        var v = UIView()
//        return v
//    }()
//    
//    lazy var muteButton: UIButton = {
//        let b = UIButton()
//        b.setImage(UIImage(systemName: "speaker.slash"), for: .normal)
//        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
//        b.tintColor = SIPlayerTheme.mainTintColor()
//        b.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
//        b.layer.masksToBounds = true
//        b.layer.cornerRadius = 30/2
//        return b
//    }()
//    
//    lazy var unmuteButton: UIButton = {
//        let b = UIButton()
//        b.setImage(UIImage(systemName: "speaker"), for: .normal)
//        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
//        b.tintColor = SIPlayerTheme.mainTintColor()
//        b.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
//        b.layer.masksToBounds = true
//        b.layer.cornerRadius = 30/2
//        return b
//    }()
    
    lazy var adsView: UIView = {
        let v = UIView()
        return v
    }()
    
    weak var delegate: PlayerPanelContentViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
        }
        
        addSubview(buttonWrapperView)
        buttonWrapperView.snp.makeConstraints { make in
            make.width.height.equalTo(45)
            make.centerY.centerX.equalToSuperview()
        }
        
        buttonWrapperView.addSubview(playButton)
        playButton.snp.makeConstraints { make in
            make.width.height.equalTo(45)
            make.centerY.centerX.equalToSuperview()
        }
        
        buttonWrapperView.addSubview(pauseButton)
        pauseButton.snp.makeConstraints { make in
            make.width.height.equalTo(45)
            make.centerY.centerX.equalToSuperview()
        }
        
        buttonWrapperView.addSubview(replayButton)
        replayButton.snp.makeConstraints { make in
            make.width.height.equalTo(45)
            make.centerY.centerX.equalToSuperview()
        }
        
//        addSubview(soundButtonWrapperView)
//        soundButtonWrapperView.snp.makeConstraints { make in
//            make.width.height.equalTo(30)
//            make.left.equalToSuperview().offset(25)
//            make.bottom.equalToSuperview().offset(-20)
//        }
//
//        soundButtonWrapperView.addSubview(unmuteButton)
//        unmuteButton.snp.makeConstraints { make in
//            make.width.height.equalTo(30)
//            make.centerY.centerX.equalToSuperview()
//        }
//
//        soundButtonWrapperView.addSubview(muteButton)
//        muteButton.snp.makeConstraints { make in
//            make.width.height.equalTo(30)
//            make.centerY.centerX.equalToSuperview()
//        }
        
        addSubview(adsView)
        adsView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(60)
            make.width.equalTo(380)
        }
        
        playButton.addTarget(self, action: #selector(playButtonBlock), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(pauseButtonBlock), for: .touchUpInside)
        replayButton.addTarget(self, action: #selector(replayButtonBlock), for: .touchUpInside)
        
//        muteButton.addTarget(self, action: #selector(muteButtonBlock), for: .touchUpInside)
//        unmuteButton.addTarget(self, action: #selector(unmuteButtonBlock), for: .touchUpInside)
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
        
        loadingView.isHidden = true
        playButton.isHidden = true
        pauseButton.isHidden = true
        replayButton.isHidden = true

        adsView.isHidden = true
        
//        unmuteButton.isHidden = true
    }
    
    @objc func playButtonBlock(_ sender: UIControl) {
        delegate?.playerPanelContentView(self, playDidPressed: sender)
    }
    
    @objc func pauseButtonBlock(_ sender: UIControl) {
        delegate?.playerPanelContentView(self, pauseDidPressed: sender)
    }
    
    @objc func replayButtonBlock(_ sender: UIControl) {
        delegate?.playerPanelContentView(self, replayDidPressed: sender)
    }
    
//    @objc func muteButtonBlock(_ sender: UIControl) {
//        muteButton.isHidden = true
//        unmuteButton.isHidden = false
//        delegate?.playerPanelContentView(self, muteDidPressed: sender)
//    }
//
//    @objc func unmuteButtonBlock(_ sender: UIControl) {
//        muteButton.isHidden = false
//        unmuteButton.isHidden = true
//        delegate?.playerPanelContentView(self, unmuteDidPressed: sender)
//    }
    
    // Gestures
    
    @objc func panGestureHandle(recognizer: UIPanGestureRecognizer) {
        print("panGestureHandle(recognizer)")
    }
    
    @objc func tapGestureHandle(recognizer: UITapGestureRecognizer) {
        print("tapGestureHandle(recognizer)")
        delegate?.playerPanelContentView(self, receivedTapEvent: recognizer)
    }
    
    // UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func setAdsSubView(_ view: UIView) {
        
        adsView.subviews.forEach { subView in
            subView.removeFromSuperview()
        }
        
        adsView.addSubview(view)
        view.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
}
