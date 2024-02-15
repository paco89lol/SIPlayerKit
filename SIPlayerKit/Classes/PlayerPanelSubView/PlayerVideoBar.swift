//
//  VideoBar.swift
//  CustomPlayer
//
//  Created by Paco on 27/1/2023.
//

import Foundation
import UIKit
import SnapKit
import AVKit

protocol PlayerVideoBarDelegate: AnyObject {
    
    func playerVideoBar(_ view: PlayerVideoBar, playDidPressed button: UIControl)
    func playerVideoBar(_ view: PlayerVideoBar, pauseDidPressed button: UIControl)
    
    func playerVideoBar(_ view: PlayerVideoBar, fullScreenDidPressed button: UIControl)
    func playerVideoBar(_ view: PlayerVideoBar, originalScreenDidPressed button: UIControl)
    
    func playerVideoBar(_ view: PlayerVideoBar, muteDidPressed button: UIControl)
    func playerVideoBar(_ view: PlayerVideoBar, unmuteDidPressed button: UIControl)
    
    func playerVideoBar(_ view: PlayerVideoBar, onPanValueChange value: Float)
    func playerVideoBar(_ view: PlayerVideoBar, onTocuhUp value: Float)
    func playerVideoBar(_ view: PlayerVideoBar, onTocuhDown value: Float)
}

class PlayerVideoBar: UIView, PlayerSliderDelegate, UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        // prevent from scrolling to other tab page
        if let _ = otherGestureRecognizer.view as? UIScrollView {
            return false
        }
        return true
    }
    
    lazy var videoProgressBarWrapperView: UIView = {
        let v = UIView()
        return v
    }()
    
//    lazy var playButton: UIButton = {
//        let b = UIButton()
//        b.setImage(UIImage(systemName: "play.fill"), for: .normal)
//        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
//        b.tintColor = SIPlayerTheme.mainTintColor()
//        return b
//    }()
//
//    lazy var pauseButton: UIButton = {
//        let b = UIButton()
//        b.setImage(UIImage(systemName: "pause.fill"), for: .normal)
//        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
//        b.tintColor = SIPlayerTheme.mainTintColor()
//        return b
//    }()
    
    let fullScreenOrOrginalScreenButtons: UIView = {
        let v = UIView()
        return v
    }()
    
    lazy var muteButton: UIButton = {
        let b = UIButton()
        // the button image is reversed
        b.setImage(SIPlayerAssets.muteImage?.scale(with: CGSize(width: 20, height: 20))?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        b.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        b.layer.masksToBounds = true
        b.layer.cornerRadius = 30/2
        return b
    }()
    
    lazy var unmuteButton: UIButton = {
        let b = UIButton()
        // the button image is reversed
        b.setImage(SIPlayerAssets.volumeImage?.scale(with: CGSize(width: 20, height: 20))?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 10), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        b.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        b.layer.masksToBounds = true
        b.layer.cornerRadius = 30/2
        return b
    }()
    
    lazy var videoProgressBar: PlayerSlider = {
        let p = PlayerSlider()
        p.delegate = self
        p.setThumbImage(UIImage(), for: .normal)
        let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))?.scale(with: CGSize(width: 25, height: 25))?.withRenderingMode(.alwaysTemplate)
        let c = PlayerSlider.Configuration(minimumTrackTintColor: SIPlayerTheme.progressBarTintColor(), maximumTrackTintColor: SIPlayerTheme.mainTintColor().withAlphaComponent(0.5), progressTintColor: SIPlayerTheme.mainTintColor().withAlphaComponent(0.8), backgroundColor: .clear, thumbImage: thumbImage)
        p.setView(with: c)
        return p
    }()
    
    lazy var videoProgressBackgroundBar: PlayerSlider = {
        let p = PlayerSlider()
        p.clipsToBounds = true
        p.setThumbImage(UIImage(), for: .normal)
        p.isUserInteractionEnabled = false
        let thumbImage = UIImage(named: "icon_slider_thumb")?.scale(with: CGSize(width: 20, height: 20))?.withRenderingMode(.alwaysTemplate)
        let c = PlayerSlider.Configuration(minimumTrackTintColor: SIPlayerTheme.progressBarTintColor(), maximumTrackTintColor: SIPlayerTheme.mainTintColor().withAlphaComponent(0.5), progressTintColor: SIPlayerTheme.mainTintColor().withAlphaComponent(0.8), backgroundColor: .clear, thumbImage: UIImage())
        p.setView(with: c)
        return p
    }()
    
    lazy var playTimeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = l.font.withSize(11)
        l.textAlignment = .center
        l.text = "00:00"
        l.minimumScaleFactor = 0.8
        l.textColor = SIPlayerTheme.mainTextColor()
        return l
    }()
    
    lazy var playTotalTimeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = l.font.withSize(11)
        l.textAlignment = .center
        l.text = "00:00"
        l.minimumScaleFactor = 0.8
        l.textColor = SIPlayerTheme.mainTextColor()
        return l
    }()
    
    lazy var originalScreenButton: UIButton = {
        let b = UIButton()
        b.setImage(SIPlayerAssets.exitFullScreenImage ,for: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        return b
    }()
    
    lazy var fullScreenButton: UIButton = {
        let b = UIButton()
        b.setImage(SIPlayerAssets.fullScreenImage, for: .normal)
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        return b
    }()
    
    weak var delegate: PlayerVideoBarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        let pan = UIPanGestureRecognizer()
        pan.delegate = self
        addGestureRecognizer(pan)
        
        let muteOrUnmuteButtons = UIView()
//        muteOrUnmuteButtons.addSubview(unmuteButton)
//        unmuteButton.snp.makeConstraints { make in
//            make.left.top.right.bottom.equalToSuperview()
//        }
//        muteOrUnmuteButtons.addSubview(muteButton)
//        muteButton.snp.makeConstraints { make in
//            make.left.top.right.bottom.equalToSuperview()
//        }
        
        fullScreenOrOrginalScreenButtons.addSubview(originalScreenButton)
        originalScreenButton.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        fullScreenOrOrginalScreenButtons.addSubview(fullScreenButton)
        fullScreenButton.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        
        
        addSubview(muteOrUnmuteButtons)
        muteOrUnmuteButtons.snp.makeConstraints { [weak self] make in
            guard let self = self else { return }
            make.height.width.equalTo(30)
            make.top.equalToSuperview()
            make.left.equalTo(self.snp.left).offset(10)
        }
        
        addSubview(videoProgressBarWrapperView)
        videoProgressBarWrapperView.snp.makeConstraints { make in
            make.left.equalTo(muteOrUnmuteButtons.snp.right).offset(3)
            make.top.equalToSuperview()
            make.height.equalTo(30)
        }
        
        addSubview(fullScreenOrOrginalScreenButtons)
        fullScreenOrOrginalScreenButtons.snp.makeConstraints { make in
            make.height.width.equalTo(30)
            make.top.equalToSuperview()
            make.left.equalTo(fullScreenOrOrginalScreenButtons.snp.right)
            make.right.equalTo(self.snp.right).offset(-10)
        }
        
        let stackView = UIStackView(arrangedSubviews: [playTimeLabel, videoProgressBar, playTotalTimeLabel])
        
        stackView.axis = .horizontal
        stackView.spacing = 3
        stackView.alignment = .center
        stackView.distribution = .fill
        
        videoProgressBarWrapperView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        playTimeLabel.snp.makeConstraints { make in
//            make.left.equalTo(playOrPauseButtons.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalTo(25)
            make.width.greaterThanOrEqualTo(35)
        }
        
        videoProgressBar.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(playTimeLabel.snp.right).offset(5)
            make.height.equalTo(30)
        }
        
        playTotalTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(videoProgressBar.snp.right).offset(5)
            make.right.equalTo(fullScreenOrOrginalScreenButtons.snp.left)
            make.centerY.equalToSuperview()
            make.height.equalTo(25)
            make.width.greaterThanOrEqualTo(35)
        }
        
        
        
//        playButton.addTarget(self, action: #selector(playButtonBlock), for: .touchUpInside)
//        pauseButton.addTarget(self, action: #selector(pauseButtonBlock), for: .touchUpInside)
//        muteButton.addTarget(self, action: #selector(muteButtonBlock), for: .touchUpInside)
//        unmuteButton.addTarget(self, action: #selector(unmuteButtonBlock), for: .touchUpInside)
        fullScreenButton.addTarget(self, action: #selector(fullScreenButtonBlock), for: .touchUpInside)
        originalScreenButton.addTarget(self, action: #selector(originalScreenButtonBlock), for: .touchUpInside)
        
//        muteOrUnmuteButtons.isHidden = true
        if SIPlayerPreference.sound.value {
            muteButton.isHidden = true
            unmuteButton.isHidden = false
        } else {
            muteButton.isHidden = false
            unmuteButton.isHidden = true
        }
        
        addSubview(videoProgressBackgroundBar)
        videoProgressBackgroundBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-1)
            make.height.equalTo(1)
        }
        
        originalScreenButton.isHidden = true
        videoProgressBackgroundBar.isHidden = true
    }
    
//    @objc func playButtonBlock(_ sender: UIControl) {
//        playButton.isHidden = true
//        pauseButton.isHidden = false
//        delegate?.playerVideoBar(self, playDidPressed: sender)
//    }
//
//    @objc func pauseButtonBlock(_ sender: UIControl) {
//        pauseButton.isHidden = true
//        playButton.isHidden = false
//        delegate?.playerVideoBar(self, pauseDidPressed: sender)
//    }
    
//    @objc func muteButtonBlock(_ sender: UIControl) {
//        muteButton.isHidden = true
//        unmuteButton.isHidden = false
//        delegate?.playerVideoBar(self, muteDidPressed: sender)
//    }
//    
//    @objc func unmuteButtonBlock(_ sender: UIControl) {
//        muteButton.isHidden = false
//        unmuteButton.isHidden = true
//        delegate?.playerVideoBar(self, unmuteDidPressed: sender)
//    }
    
    @objc func fullScreenButtonBlock(_ sender: UIControl) {
        delegate?.playerVideoBar(self, fullScreenDidPressed: sender)
    }
    
    @objc func originalScreenButtonBlock(_ sender: UIControl) {
        delegate?.playerVideoBar(self, originalScreenDidPressed: sender)
    }
    
    //
    
    func setBuffer(totalSecond: Int64, buffered: Int64) {
        
        let _totalSecond = CMTimeGetSeconds(CMTime(seconds: Double(totalSecond), preferredTimescale: 1))
        let _buffered = CMTimeGetSeconds(CMTime(seconds: Double(buffered), preferredTimescale: 1))
     
        var bufferedValue = CMTimeGetSeconds(CMTime(seconds: 0.0, preferredTimescale: 1))
        if totalSecond != 0 && buffered != 0 {
            bufferedValue = Float64(_buffered) / Float64(_totalSecond)
        }
        
        videoProgressBar.playerSliderSet(bufferedValue: Float(bufferedValue))
        videoProgressBackgroundBar.playerSliderSet(bufferedValue: Float(bufferedValue))
    }
    
    func setCurrent(totalSecond: Int64, second: Int64) {
        
        let _totalSecond = CMTimeGetSeconds(CMTime(seconds: Double(totalSecond), preferredTimescale: 1))
        let _second = CMTimeGetSeconds(CMTime(seconds: Double(second), preferredTimescale: 1))
        
        var currentPlayValue = CMTimeGetSeconds(CMTime(seconds: 0.0, preferredTimescale: 1))
        if totalSecond != 0 && second != 0 {
            currentPlayValue =  Float64(_second) / Float64(_totalSecond)
        }
        
        videoProgressBar.playerSliderSet(currentPlayValue: Float(currentPlayValue))
        videoProgressBackgroundBar.playerSliderSet(currentPlayValue: Float(currentPlayValue))
    }
    
    func setCurrentTimeLabel(second: Int64) {
        playTimeLabel.text = timeToDisplayableString(second: second)
    }
    
    func setTotalTimeLabel(second: Int64) {
        playTotalTimeLabel.text = timeToDisplayableString(second: second)
    }
    
    private func timeToDisplayableString(second: Int64) -> String {
        let currentSeconds = second
        let seconds = (Int64(currentSeconds) % 3600) % 60
        let minutes = (Int64(currentSeconds) % 3600) / 60
        let hours = Int64(currentSeconds) / 3600
        
        let timeTextBlock = { (number: Int64) -> String in
            return number < 10 ? "0\(number)" : "\(number)"
        }
        
        if hours == 0 {
            return "\(timeTextBlock(minutes)):\(timeTextBlock(seconds))"
        }
        
        return "\(timeTextBlock(hours)):\(timeTextBlock(minutes)):\(timeTextBlock(seconds))"
        
    }
    
    /// PlayerSliderDelegate
    ///
    func playerSlider(onPanValueChange value: Float) {
        delegate?.playerVideoBar(self, onPanValueChange: value)
    }

    func playerSlider(onTouchUp value: Float) {
        delegate?.playerVideoBar(self, onTocuhUp: value)
    }

    func playerSlider(onTouchDown value: Float) {
        delegate?.playerVideoBar(self, onTocuhDown: value)
    }
}
