//
//  PlayerPanel.swift
//  CustomPlayer
//
//  Created by Paco on 19/1/2023.
//

import Foundation
import UIKit

protocol PlayerPanelDelegate: AnyObject {
    
    // invocate when user click play
    func playerPanel(_ playerPanelView: PlayerPanel, playDidPressed: UIControl)
    
    // invocate when user click pause
    func playerPanel(_ playerPanelView: PlayerPanel, pauseDidPressed: UIControl)
    
    // invocate when user click replay
    func playerPanel(_ playerPanelView: PlayerPanel, replayDidPressed: UIControl)
    
    // invocate when user click mute
    func playerPanel(_ playerPanelView: PlayerPanel, muteDidPressed: UIControl)
    
    // invocate when user click unmute
    func playerPanel(_ playerPanelView: PlayerPanel, unmuteDidPressed: UIControl)
    
    // invocate when user click back button in fullscreen
    func playerPanel(_ playerPanelView: PlayerPanel, backDidPressed: UIControl)
    
    // invocate when user toggle fullscreen
    func playerPanel(_ playerPanelView: PlayerPanel, fullScreenDidPressed: UIControl)
    func playerPanel(_ playerPanelView: PlayerPanel, originalScreenDidPressed: UIControl)
    
    // invocate when user change video time
    func playerPanelSeekToDate(_ playerPanelView: PlayerPanel, time: Int64)
    
    //
    func playerPanel(_ playerPanelView: PlayerPanel, onPanValueChange value: Float)
    func playerPanel(_ playerPanelView: PlayerPanel, onTocuhUp value: Float)
    func playerPanel(_ playerPanelView: PlayerPanel, onTocuhDown value: Float)
    
}


public class PlayerPanel: UIView, UIGestureRecognizerDelegate, PlayerPanelHeaderViewDelegate, PlayerPanelContentViewDelegate, PlayerVideoBarDelegate {
    
    var timerToHidePanel: Timer?
    
    var isShowPanel = false
    
    public var isLive = false
    
    weak var delegate: PlayerPanelDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public lazy var headerView: PlayerPanelHeaderView = {
        let h = PlayerPanelHeaderView()
        h.addGestureRecognizer(UITapGestureRecognizer())
        h.delegate = self
        return h
    }()
    
    lazy var contentView: PlayerPanelContentView = {
        let c = PlayerPanelContentView()
        c.delegate = self
        return c
    }()
    
    lazy var footerView: PlayerPanelFooterView = {
        let f = PlayerPanelFooterView()
        f.playerVideoBar.delegate = self
        return f
    }()
    
    lazy var muteOrUnmuteButtons: UIView = {
        let v = UIView()
        v.addSubview(unmuteButton)
        unmuteButton.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        v.addSubview(muteButton)
        muteButton.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
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
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [headerView, contentView, footerView])
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.distribution = .fill
        stackView.alignment = .fill
        
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        headerView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(40)
        }
        
//        contentView.snp.makeConstraints { make in
//            make.top.equalToSuperview()//.offset(40)
//            make.left.right.equalToSuperview()
//            make.bottom.equalToSuperview()//.offset(-40)
//        }
        
        footerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
        
        addSubview(muteOrUnmuteButtons)
        muteOrUnmuteButtons.snp.makeConstraints { [weak self] make in
            guard let self = self else { return }
            make.height.width.equalTo(30)
            make.left.equalTo(self.snp.left).offset(10)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
        }
        
        muteButton.addTarget(self, action: #selector(muteButtonBlock), for: .touchUpInside)
        unmuteButton.addTarget(self, action: #selector(unmuteButtonBlock), for: .touchUpInside)
    }
    
    @objc func muteButtonBlock(_ sender: UIControl) {
        muteButton.isHidden = true
        unmuteButton.isHidden = false
        delegate?.playerPanel(self, muteDidPressed: sender)
    }
    
    @objc func unmuteButtonBlock(_ sender: UIControl) {
        muteButton.isHidden = false
        unmuteButton.isHidden = true
        delegate?.playerPanel(self, unmuteDidPressed: sender)
    }
    
    func seekToTimeBlock(time: Int64) {
        delegate?.playerPanelSeekToDate(self, time: time)
    }
    
    // PlayerVideoBarDelegate
    
    func playerVideoBar(_ view: PlayerVideoBar, playDidPressed button: UIControl) {
        delegate?.playerPanel(self, playDidPressed: button)
    }
    
    func playerVideoBar(_ view: PlayerVideoBar, pauseDidPressed button: UIControl) {
        delegate?.playerPanel(self, pauseDidPressed: button)
    }
    
    func playerVideoBar(_ view: PlayerVideoBar, muteDidPressed button: UIControl) {
        delegate?.playerPanel(self, muteDidPressed: button)
    }
    
    func playerVideoBar(_ view: PlayerVideoBar, unmuteDidPressed button: UIControl) {
        delegate?.playerPanel(self, unmuteDidPressed: button)
    }
    
    func playerVideoBar(_ view: PlayerVideoBar, fullScreenDidPressed button: UIControl) {
        delegate?.playerPanel(self, fullScreenDidPressed: button)
    }
    
    func playerVideoBar(_ view: PlayerVideoBar, originalScreenDidPressed button: UIControl) {
        delegate?.playerPanel(self, originalScreenDidPressed: button)
    }
    
    func playerVideoBar(_ view: PlayerVideoBar, onPanValueChange value: Float) {
        delegate?.playerPanel(self, onPanValueChange: value)
    }
    
    func playerVideoBar(_ view: PlayerVideoBar, onTocuhUp value: Float) {
        countDownToHidePanel()
        delegate?.playerPanel(self, onTocuhUp: value)
    }
    
    func playerVideoBar(_ view: PlayerVideoBar, onTocuhDown value: Float) {
        timerToHidePanel?.invalidate()
        delegate?.playerPanel(self, onTocuhDown: value)
    }
    
    // PlayerPanelContentViewDelegate
    
    func playerPanelContentView(_ view: PlayerPanelContentView, playDidPressed button: UIControl) {
        delegate?.playerPanel(self, playDidPressed: button)
    }
    
    func playerPanelContentView(_ view: PlayerPanelContentView, pauseDidPressed button: UIControl) {
        delegate?.playerPanel(self, pauseDidPressed: button)
    }
    
    func playerPanelContentView(_ view: PlayerPanelContentView, replayDidPressed button: UIControl) {
        delegate?.playerPanel(self, replayDidPressed: button)
    }
    
//    func playerPanelContentView(_ view: PlayerPanelContentView, muteDidPressed button: UIControl) {
//        delegate?.playerPanel(self, muteDidPressed: button)
//    }
//
//    func playerPanelContentView(_ view: PlayerPanelContentView, unmuteDidPressed button: UIControl) {
//        delegate?.playerPanel(self, unmuteDidPressed: button)
//    }
    
    func playerPanelContentView(_ view: PlayerPanelContentView, receivedTapEvent recognizer: UITapGestureRecognizer) {
        if contentView.buttonWrapperView.isHidden {
            showPanel()
        } else {
            hidePanel()
        }
    }
    
    // PlayerPanelHeaderViewDelegate
    
    func playerPanelHeaderView(_ view: PlayerPanelHeaderView, backDidPressed button: UIControl) {
        delegate?.playerPanel(self, backDidPressed: button)
    }
    
    ///
    ///
    
    func hidePanel() {
        defer {
            isShowPanel = false
        }

        backgroundColor = .clear
        
        if !isLive {
            footerView.playerVideoBar.videoProgressBackgroundBar.isHidden = false
            footerView.playerVideoBar.videoProgressBarWrapperView.isHidden = true
        } else {
            footerView.playerVideoBar.videoProgressBackgroundBar.isHidden = true
            footerView.playerVideoBar.videoProgressBarWrapperView.isHidden = true
        }
        
        footerView.playerVideoBar.fullScreenOrOrginalScreenButtons.isHidden = true
        
        headerView.isHidden = true
        contentView.buttonWrapperView.isHidden = true
        footerView.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
        footerView.playerVideoBar.videoProgressBarWrapperView.isHidden = true
    }
    
    func showPanel(autoFadeOut: Bool = true) {
        defer {
            isShowPanel = true
        }
        
        backgroundColor = UIColor.darkText.withAlphaComponent(0.3)
        
        if !isLive {
            footerView.playerVideoBar.videoProgressBackgroundBar.isHidden = true
            footerView.playerVideoBar.videoProgressBarWrapperView.isHidden = false
        } else {
            footerView.playerVideoBar.videoProgressBackgroundBar.isHidden = true
            footerView.playerVideoBar.videoProgressBarWrapperView.isHidden = true
        }
        
        footerView.playerVideoBar.fullScreenOrOrginalScreenButtons.isHidden = false
        headerView.isHidden = false
        footerView.snp.remakeConstraints { make in
            make.height.equalTo(40)
        }
        contentView.buttonWrapperView.isHidden = false
        
        if autoFadeOut {
            countDownToHidePanel()
        }
        
    }
    
    func countDownToHidePanel() {
        timerToHidePanel?.invalidate()
        timerToHidePanel = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) {[weak self] timer in
            
            guard let self = self else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                
                guard let self = self else {
                    return
                }
                
                if isShowPanel == false {
                    return
                }
                hidePanel()
            }
            
            self.timerToHidePanel = nil
        }
    }
    
}
