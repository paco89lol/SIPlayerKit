//
//  AWSPlayer.swift
//  SIPlayerKit
//
//  Created by Paco on 17/1/2024.
//

import Foundation
import AmazonIVSPlayer

class AWSMedia {
    
    var url: URL?
    
    init(url: URL? = nil) {
        self.url = url
    }
    
}

public class AWSPlayerView: UIView {
    
    var playerLayer: IVSPlayerLayer? // layoutSubviews need to change it at run time
    
    public func setAWSPlayerLayer(_ layer: IVSPlayerLayer?) {
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

public class AWSPlayerWrapper: NSObject, IPlayer, IVSPlayer.Delegate {
    
    lazy var player: IVSPlayer = {
        var p = IVSPlayer()
        p.delegate = self
        
        return p
    }()
    
    public var mediaUrlString: String? {
        get {
            return source?.url?.absoluteString
        }
    }
    
    var source: AWSMedia?
    
    public var isSetSource: Bool {
        return source != nil
    }
    
    var isAddedPlayerLayer = false
    
    var timerToUpdatePlayerBar: Timer?
    
    weak public var dataSource: IPlayerDataSource?
    weak public var delegate: IPlayerDelegate?
    
    public func setSource(url: String?) {
        
        if let url = url, let _url = URL(string: url) {
            source = AWSMedia(url: _url)
        } else {
            source = nil
        }
        
    }
    
    /// IVSPlayer.Delegate
    
    public func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
        
        guard let playerContext = dataSource?.getPlayerContext() else {
            return
        }
        
        switch state {
        case .idle: break
        case .ready:
            playerContext.isReadyToPlay = true //*
            delegate?.onPlayerEvent(self, playState: .playing)
        case .buffering:
            print("IVSPlayer.Delegate: BUFFERING")
            delegate?.onPlayerEvent(self, playState: .stalling)
        case .playing:
            print("IVSPlayer.Delegate: PLAYING")
            delegate?.onPlayerEvent(self, playState: .playing)
        case .ended:
            print("IVSPlayer.Delegate: ENDED")
            delegate?.onPlayerEvent(self, playState: .end)
        @unknown default: break
            
        }
    }
    
    public func player(_ player: IVSPlayer, didSeekTo time: CMTime) {
        delegate?.player(onUpdateVideoCurrentTime: Int64(time.seconds))
    }
    
    public func player(_ player: IVSPlayer, didChangeDuration duration: CMTime) {
        if duration.seconds.isNormal {
            delegate?.player(onUpdateVideoTotalTime: Int64(duration.seconds))
        }
        
//        if !(player.duration.seconds.isNaN || player.duration.seconds.isFinite) {
//            delegate?.player(onUpdateVideoTotalTime: Int64(player.duration.seconds))
//        }
    }
    
    public func player(_ player: IVSPlayer, didFailWithError error: Error) {
        delegate?.player(onError: NSError(domain: error.localizedDescription, code: 0))
    }
    
    /// VLCMediaPlayerDelegate
    
//    public func mediaPlayerStateChanged(_ aNotification: Notification) {
//        guard let videoPlayer = aNotification.object as? VLCMediaPlayer else {return}
//        switch videoPlayer.state{
//        case .playing:
//            print("VLCMediaPlayerDelegate: PLAYING")
//            delegate?.onPlayerEvent(self, playState: .playing)
//        case .opening:
//            // 首帧显示
//            print("VLCMediaPlayerDelegate: OPENING")
//            
//            guard let playerContext = dataSource?.getPlayerContext() else {
//                return
//            }
//            
//            playerContext.isReadyToPlay = true //*
//            delegate?.onPlayerEvent(self, playState: .playing)
//            
//        case .error:
//            print("VLCMediaPlayerDelegate: ERROR")
//        case .buffering:
//            print("VLCMediaPlayerDelegate: BUFFERING")
//            delegate?.onPlayerEvent(self, playState: .stalling)
//        case .stopped:
//            print("VLCMediaPlayerDelegate: STOPPED")
//            delegate?.onPlayerEvent(self, playState: .end)
//        case .paused:
//            print("VLCMediaPlayerDelegate: PAUSED")
//            delegate?.onPlayerEvent(self, playState: .pause)
//        case .ended:
//            print("VLCMediaPlayerDelegate: ENDED")
//            delegate?.onPlayerEvent(self, playState: .end)
//        case .esAdded:
//            print("VLCMediaPlayerDelegate: ELEMENTARY STREAM ADDED")
//        default:
//            break
//        }
//    }
//    
//    public func mediaPlayerTimeChanged(_ aNotification: Notification) {
//        guard let videoPlayer = aNotification.object as? VLCMediaPlayer else {return}
//        let second = videoPlayer.time.intValue / 1000
//        delegate?.player(onUpdateVideoCurrentTime: Int64(second))
//        
//        if let intValue = videoPlayer.media?.length.intValue {
//            let second = intValue / 1000
//            delegate?.player(onUpdateVideoTotalTime: Int64(second))
//        }
//    }
    
    ///
    
    /// IPlayer

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
            let awsPlayerView = AWSPlayerView()
            awsPlayerView.setAWSPlayerLayer(IVSPlayerLayer(player: player))
            dataSource.getPlayerContentView().videoView.addSubview(awsPlayerView)
            awsPlayerView.snp.makeConstraints { make in
                make.left.top.right.bottom.equalToSuperview()
            }
        }
        

        guard let source = source else { return }
        
        repeat {
            player.load(source.url)
            break
            isError = true
        } while false
        
        guard !isError else {
            return
        }
        
        
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
        player.pause()
    }
    
    public func seek(second: Int64) {
        let time = CMTime(seconds: Double(second), preferredTimescale: 1)
        player.seek(to: time)
    }
    
    ///
    public func setMute(_ isMute: Bool) {
        player.muted = isMute
    }
    
    @objc public func createTimerToUpdatePlayerBarHandler() {
        
//        if player.timeControlStatus == .paused {
//            delegate?.onPlayerEvent(self, playState: .pause)
//        }
//        
//        if let currentTime = player.currentItem?.currentTime(), let duration = player.currentItem?.duration {
//            let currentSecond = Int64(CMTimeGetSeconds(currentTime))
//            delegate?.player(onUpdateVideoCurrentTime: currentSecond)
//            let totalSecond = CMTimeGetSeconds(duration)
//            
//            if totalSecond.isNaN {
//                delegate?.player(onUpdateVideoTotalTime: 0)
//            } else {
//                delegate?.player(onUpdateVideoTotalTime: Int64(totalSecond))
//            }
//        } else {
//            delegate?.player(onUpdateVideoCurrentTime: 0)
//            delegate?.player(onUpdateVideoTotalTime: 0)
//        }
        
        delegate?.player(onUpdateVideoCurrentTime: Int64(player.position.seconds))
        
        delegate?.player(onUpdateVideoBufferedTime: Int64(player.buffered.seconds))
        
    }
}
