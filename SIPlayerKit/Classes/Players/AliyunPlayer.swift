//
//  AliyunPlayerController.swift
//  CustomPlayer
//
//  Created by Paco on 17/1/2023.
//

import Foundation
import AliyunPlayer
import Combine

public class AliPlayerWrapper: NSObject, IPlayer, AVPDelegate, CicadaAudioSessionDelegate {
    
    lazy var player: AliPlayer = {
        var p = AliPlayer()!
        p.setConfig(playerConfig)
        p.delegate = self
        return p
    }()
    
    lazy var playerConfig: AVPConfig = {
        var c = AVPConfig()
        c.maxDelayTime = 1500
        c.highBufferDuration = 3000
        c.startBufferDuration = 1000
        c.networkRetryCount = 0
        c.networkTimeout = 15000
        return c
    }()
    
    public var mediaUrlString: String?
    
    var source: AVPSource?
    
    public var isSetSource: Bool {
        return source != nil
    }
    
    weak public var dataSource: IPlayerDataSource?
    weak public var delegate: IPlayerDelegate?
    
    public override init() {
        super.init()
        AliPlayer.setAudioSessionDelegate(self)
    }
    
    public func setSource(url: String?) {
        mediaUrlString = url
        if let url = url {
            source = AVPUrlSource().url(with: url)
        } else {
            source = nil
        }
    }
    
    /// AVPDelegate
    
    public func onPlayerEvent(_ player: AliPlayer!, eventType: AVPEventType) {
        
        guard let playerContext = dataSource?.getPlayerContext() else {
            return
        }
        
        switch eventType {
        case AVPEventPrepareDone:
            var duration: Int64 = 0
            if player.duration != 0 {
                duration = player.duration / 1000
            }
            delegate?.player(onUpdateVideoTotalTime: duration)
            // 准备完成
            break
        case AVPEventAutoPlayStart:
            // 自动播放开始事件
            break
        case AVPEventFirstRenderedStart:
            // 首帧显示
            playerContext.isReadyToPlay = true //*
            delegate?.onPlayerEvent(self, playState: .playing)
            break
        case AVPEventCompletion:
            // 播放完成
            delegate?.onPlayerEvent(self, playState: .end)
            break
        case AVPEventLoadingStart:
            // 缓冲开始
            delegate?.onPlayerEvent(self, playState: .stalling)
            break
        case AVPEventLoadingEnd:
            if !playerContext.isPausedByUser { //*
                delegate?.onPlayerEvent(self, playState: .playing)
            } else {
                delegate?.onPlayerEvent(self, playState: .pause)
            }
            
            // 缓冲完成
            break
        case AVPEventSeekEnd:
            // 跳转完成
            if !playerContext.isPausedByUser { //*
                delegate?.onPlayerEvent(self, playState: .playing)
            } else {
                delegate?.onPlayerEvent(self, playState: .pause)
            }
            break
        case AVPEventLoopingStart:
            // 循环播放开始
            break
        default:
            break
        }
    }
    
    public func onCurrentPositionUpdate(_ player: AliPlayer!, position: Int64) {
        let second = position / 1000
        delegate?.player(onUpdateVideoCurrentTime: second)
    }
    
    public func onBufferedPositionUpdate(_ player: AliPlayer!, position: Int64) {
        let second = position / 1000
        delegate?.player(onUpdateVideoBufferedTime: second)
    }
    
    public func onError(_ player: AliPlayer!, errorModel: AVPErrorModel!) {
        delegate?.player(onError: NSError(domain: errorModel.message, code: 0))
    }
    
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
        
        player.playerView = dataSource.getPlayerContentView().videoView
        
        guard let source = source else {
            throw NSError()
        }
        
        repeat {
            
            if let source = source as? AVPUrlSource {
                player.setUrlSource(source)
                break
            }
            
            if let source = source as? AVPVidStsSource {
                player.setStsSource(source)
                break
            }
            
            if let source = source as? AVPVidMpsSource {
                player.setMpsSource(source)
                break
            }
            
            if let source = source as? AVPVidAuthSource {
                player.setAuthSource(source)
                break
            }
            isError = true
        } while false
        
        guard !isError else {
            throw NSError()
        }
        player.prepare()
    }
    
    public func play() {
        player.start()
    }
    
    public func pause() {
        player.pause()
    }
    
    public func end() {
//        player.stop()
        player.destroy()
    }
    
    public func seek(second: Int64) {
        player.seek(toTime: second * 1000, seekMode: AVPSeekMode(AVP_SEEKMODE_ACCURATE.rawValue))
    }
    
    ///
    
    public func setMute(_ isMute: Bool) {
        player.isMuted = isMute
    }
    
    /// CicadaAudioSessionDelegate
    
    public func setActive(_ active: Bool) throws {
        // Set it in SIPlayerPreference, Do not set here.
    }
    
    public func setCategory(_ category: String!, with options: AVAudioSession.CategoryOptions = []) throws {
        // Set it in SIPlayerPreference, Do not set here.
    }
    
    public func setCategory(_ category: AVAudioSession.Category!, mode: AVAudioSession.Mode!, routeSharingPolicy policy: AVAudioSession.RouteSharingPolicy, options: AVAudioSession.CategoryOptions = []) throws {
        // Set it in SIPlayerPreference, Do not set here.
    }
    
}
