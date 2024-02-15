//
//  AVPlayerController.swift
//  CustomPlayer
//
//  Created by Paco on 17/1/2023.
//

import Foundation
import AVKit

public class AVPlayerView: UIView {
    
    var playerLayer: CALayer? // layoutSubviews need to change it at run time
    
    public func setAVPlayerLayer(_ layer: CALayer?) {
        self.removeFromSuperview()
        playerLayer = layer
        guard let playerLayer = playerLayer else { return }
        self.layer.addSublayer(playerLayer)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
    }
}

public class AVPlayerWrapper: NSObject, IPlayer {
    
    lazy var player: AVPlayer = {
        var p = AVPlayer()
        return p
    }()
    
    public var mediaUrlString: String? {
        get {
            return (source?.asset as? AVURLAsset)?.url.absoluteString
        }
    }
    
    var source: AVPlayerItem?
    
    public var isSetSource: Bool {
        return source != nil
    }
    
    var isAddedPlayerLayer = false
    
    var timerToUpdatePlayerBar: Timer?
    
    
    //    var playerStopObserver: NSKeyValueObservation?
    var playerStallingObserver: NSKeyValueObservation?
    var readyToPlayObserver: NSKeyValueObservation?
    
    
    weak public var dataSource: IPlayerDataSource?
    weak public var delegate: IPlayerDelegate?
    
    public func setSource(url: String?) {
        
        if let url = url, let _url = URL(string: url) {
            source = AVPlayerItem(url: _url)
        } else {
            source = nil
        }
        
    }
    
    public func prepareAndPlay() throws {
        try prepare()
        play()
    }
    
    public func prepare() throws {
        var isError = false
        
        guard let dataSource = dataSource else {
            throw NSError()
        }
        
        guard let _ = delegate else {
            throw NSError()
        }
        
        if !isAddedPlayerLayer {
            isAddedPlayerLayer = true
            let avPlayerView = AVPlayerView()
            avPlayerView.setAVPlayerLayer(AVPlayerLayer(player: player))
            dataSource.getPlayerContentView().videoView.addSubview(avPlayerView)
            avPlayerView.snp.makeConstraints { make in
                make.left.top.right.bottom.equalToSuperview()
            }
        }
        
        guard let source = source else { return }
        
        repeat {
            player.replaceCurrentItem(with: source)
            break
            isError = true
        } while false
        
        guard !isError else {
            return
        }
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerDidFinishPlaying),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: player.currentItem
            )
        
        readyToPlayObserver = player.currentItem?.observe(\.status, options: [.new, .old], changeHandler: { [weak self] (observedCurrentItem, change) in
            guard let self = self else { return }
            print("\(player.currentItem?.status.rawValue)")
            if observedCurrentItem.status == AVPlayerItem.Status.readyToPlay {
                // 首帧显示
                print("readyToPlay")
                
                guard let playerContext = self.dataSource?.getPlayerContext() else {
                    return
                }
                
                playerContext.isReadyToPlay = true //*
                delegate?.onPlayerEvent(self, playState: .playing)
            } else if observedCurrentItem.status == AVPlayerItem.Status.failed {
                print("failed")
            }
        })
        
        playerStallingObserver = player.currentItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old], changeHandler: { [weak self] (observedCurrentItem, change) in
            guard let self = self else { return }
            if observedCurrentItem.isPlaybackLikelyToKeepUp {
                delegate?.onPlayerEvent(self, playState: .playing)
            } else {
                delegate?.onPlayerEvent(self, playState: .stalling)
            }
        })
        
        if let timerToUpdatePlayerBar = timerToUpdatePlayerBar {
            timerToUpdatePlayerBar.invalidate()
        }
        timerToUpdatePlayerBar = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(createTimerToUpdatePlayerBarHandler), userInfo: nil, repeats: true)
        player.play()
    }
    
    public func play() {
        player.play()
    }
    
    public func pause() {
        player.pause()
    }
    
    public func end() {
        player.replaceCurrentItem(with: nil)
    }
    
    public func seek(second: Int64) {
        let time = CMTime(seconds: Double(second), preferredTimescale: 1)
        player.seek(to: time)
    }
    
    @objc public func createTimerToUpdatePlayerBarHandler() {
        
        if player.timeControlStatus == .paused {
            delegate?.onPlayerEvent(self, playState: .pause)
        }
        
        if let currentTime = player.currentItem?.currentTime(), let duration = player.currentItem?.duration {
            let currentSecond = Int64(CMTimeGetSeconds(currentTime))
            delegate?.player(onUpdateVideoCurrentTime: currentSecond)
            let totalSecond = CMTimeGetSeconds(duration)
            
            if totalSecond.isNaN {
                delegate?.player(onUpdateVideoTotalTime: 0)
            } else {
                delegate?.player(onUpdateVideoTotalTime: Int64(totalSecond))
            }
        } else {
            delegate?.player(onUpdateVideoCurrentTime: 0)
            delegate?.player(onUpdateVideoTotalTime: 0)
        }
        
        if let firstTimeRange = player.currentItem?.loadedTimeRanges.first {
            let timeRange = firstTimeRange.timeRangeValue
            let startSeconds = Int64(CMTimeGetSeconds(timeRange.start))
            let durationSeconds = Int64(CMTimeGetSeconds(timeRange.duration))
            let totalLoadedSeconds = startSeconds + durationSeconds
            delegate?.player(onUpdateVideoBufferedTime: totalLoadedSeconds)
        } else {
            delegate?.player(onUpdateVideoBufferedTime: 0)
        }
    }
    
    @objc public func playerDidFinishPlaying(_ aNotification: Notification) {
        delegate?.onPlayerEvent(self, playState: .end)
    }
    
    public func setMute(_ isMute: Bool) {
        player.isMuted = isMute
    }
}
