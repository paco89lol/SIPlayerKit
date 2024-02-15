//
//  CoverImageView.swift
//  CustomPlayer
//
//  Created by Paco on 2/2/2023.
//

import Foundation
import UIKit
import Kingfisher

protocol PlayerCoverViewDelegate: AnyObject {
    
    func playerCoverView(_ view: PlayerCoverView, playDidPressed button: UIControl)
    func playerCoverView(_ view: PlayerCoverView, retryPlayDidPressed button: UIControl)
    func playerCoverView(_ view: PlayerCoverView, replayDidPressed button: UIControl)
    func playerCoverView(_ view: PlayerCoverView, coverImageDidPressed button: UIControl)
    func playerCoverView(_ view: PlayerCoverView, backDidPressed button: UIControl)
}

public class PlayerCoverView: UIView {
    
    var imageView: UIImageView = {
        let v = UIImageView()
        return v
    }()
    
    var imageViewButton: UIButton = {
        let b = UIButton()
        return b
    }()
    
    var durationLabel: UILabel = {
        let l = UILabel()
        l.clipsToBounds = true
        l.layer.cornerRadius = 5
        l.font = l.font.withSize(12)
        l.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        l.textColor = SIPlayerTheme.mainTextColor()
        l.textAlignment = .center
        l.text = "00:00"
        return l
    }()
    
    var playButton: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "play.fill"), for: .normal)
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 30), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        return b
    }()
    
    lazy var retryView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let b = UIButton()
        b.backgroundColor = SIPlayerTheme.progressBarTintColor()
        b.tintColor = SIPlayerTheme.mainTintColor()
        b.layer.cornerRadius = 5
        b.clipsToBounds = true
        b.addTarget(self, action: #selector(retryPlayButtonBlock), for: .touchUpInside)
        b.setTitle("刷新", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        b.titleLabel?.minimumScaleFactor = 0.8
        
        let l = UILabel()
        l.font = l.font.withSize(13)
        l.textAlignment = .center
        l.minimumScaleFactor = 0.8
        l.textColor = SIPlayerTheme.mainTextColor()
        l.text = "視頻加載失敗"
        
        let s = UIStackView(arrangedSubviews: [l, b])
        s.axis = .vertical
        s.spacing = 5
        s.distribution = .fill
        s.alignment = .fill
        
        v.addSubview(s)
        
        l.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(80)
            make.height.equalTo(35)
        }
        
        b.snp.makeConstraints { make in
            make.width.equalTo(80)
            make.height.equalTo(25)
        }
        
        s.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(70)
        }
        return v
    }()
    
    var endOfLiveView: UIView = {
        let v = UIView()
        
        return v
    }()
    
    var replayView: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "goforward"), for: .normal)
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 35), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        return b
    }()
    
    var loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView()
        v.hidesWhenStopped = true
        v.isHidden = true
        v.tintColor = SIPlayerTheme.mainTintColor()
        return v
    }()
    
    var backButton: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        return b
    }()
    
    weak var delegate: PlayerCoverViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        imageView.addSubview(imageViewButton)
        imageViewButton.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(45)
            make.height.equalTo(20)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        addSubview(retryView)
        retryView.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
        }
        
        addSubview(playButton)
        playButton.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        addSubview(replayView)
        replayView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.height.width.equalTo(30)
            make.left.equalTo(self.snp.left).offset(10)
            make.top.equalTo(5)
        }
        
        imageViewButton.addTarget(self, action: #selector(imageViewButtonBlock), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playButtonBlock), for: .touchUpInside)
        replayView.addTarget(self, action: #selector(replayButtonBlock), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backButtonBlock), for: .touchUpInside)
        
        playButton.isHidden = false
        loadingView.isHidden = true
        retryView.isHidden = true
        replayView.isHidden = true
        endOfLiveView.isHidden = true
        backButton.isHidden = true
    }
    
    @objc func imageViewButtonBlock(_ sender: UIControl) {
        delegate?.playerCoverView(self, coverImageDidPressed: sender)
    }
    
    @objc func playButtonBlock(_ sender: UIControl) {
        delegate?.playerCoverView(self, playDidPressed: sender)
    }
    
    @objc func backButtonBlock(_ sender: UIControl) {
        delegate?.playerCoverView(self, backDidPressed: sender)
    }
    
    @objc func retryPlayButtonBlock(_ sender: UIControl) {
        showLoadingView()
        delegate?.playerCoverView(self, retryPlayDidPressed: sender)
    }
    
    @objc func replayButtonBlock(_ sender: UIControl) {
        showLoadingView()
        delegate?.playerCoverView(self, replayDidPressed: sender)
    }
    
    public func showPlayView() {
        loadingView.stopAnimating()
        playButton.isHidden = false
        loadingView.isHidden = true
        retryView.isHidden = true
        replayView.isHidden = true
        imageView.isHidden = false
        endOfLiveView.isHidden = true
    }
    
    public func showNothing() {
        loadingView.stopAnimating()
        playButton.isHidden = true
        loadingView.isHidden = true
        retryView.isHidden = true
        replayView.isHidden = true
        endOfLiveView.isHidden = true
    }
    
    public func showLoadingView() {
        loadingView.startAnimating()
        playButton.isHidden = true
        loadingView.isHidden = false
        retryView.isHidden = true
        replayView.isHidden = true
        endOfLiveView.isHidden = true
    }
    
    public func hideLoadingView() {
        loadingView.stopAnimating()
        playButton.isHidden = false
        loadingView.isHidden = true
        retryView.isHidden = true
        replayView.isHidden = true
        endOfLiveView.isHidden = true
    }
    
    public func showRetryView() {
        loadingView.stopAnimating()
        playButton.isHidden = true
        loadingView.isHidden = true
        retryView.isHidden = false
        replayView.isHidden = true
        endOfLiveView.isHidden = true
    }
    
    public func showEndOfLiveView() {
        loadingView.stopAnimating()
        playButton.isHidden = true
        loadingView.isHidden = true
        retryView.isHidden = true
        replayView.isHidden = true
        endOfLiveView.isHidden = false
    }
    
    public func showReplayView() {
        loadingView.stopAnimating()
        playButton.isHidden = true
        loadingView.isHidden = true
        retryView.isHidden = true
        replayView.isHidden = false
        imageView.isHidden = true
        endOfLiveView.isHidden = true
    }
    
    public func reset() {
        playButton.isHidden = false
        loadingView.isHidden = true
        retryView.isHidden = true
        replayView.isHidden = true
        imageView.isHidden = false
        endOfLiveView.isHidden = true
    }
    
    public func setCoverImage(url: String?, defaultImage: UIImage?) {
        if let url = url {
            imageView.kf.setImage(with: URL(string: url),placeholder: nil) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(_): break
                case .failure(_):
                    imageView.image = defaultImage
                }
            }
            return
        }
        imageView.image = defaultImage
    }
    
    public func setCoverImage(_ image: UIImage?) {
        imageView.image = image
    }
    
    public func setDurationLabel(second: Int64?) {
        
        if let second = second {
            durationLabel.text = timeToDisplayableString(second: second)
        } else {
            durationLabel.text = nil
        }
        
        if durationLabel.text == nil || durationLabel.text!.isEmpty {
            durationLabel.isHidden = true
        } else {
            durationLabel.isHidden = false
        }
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
    
}
