//
//  VLCPlayerController.swift
//  CustomPlayer
//
//  Created by Paco on 19/1/2023.
//

import Foundation
import MobileVLCKit

public class VLCPlayerWrapper: NSObject, IPlayer, VLCMediaPlayerDelegate {
    
    lazy var player: VLCMediaPlayer = {
        var p = VLCMediaPlayer()
        p.delegate = self
        return p
    }()
    
    public var mediaUrlString: String? {
        get {
            return source?.url?.absoluteString
        }
    }
    
    var source: VLCMedia?
    
    public var isSetSource: Bool {
        return source != nil
    }
    
    weak public var dataSource: IPlayerDataSource?
    weak public var delegate: IPlayerDelegate?
    
    public func setSource(url: String?) {
        
        if let url = url, let _url = URL(string: url) {
            source = VLCMedia(url: _url)
        } else {
            source = nil
        }
        
    }
    
    /// VLCMediaPlayerDelegate
    
    public func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let videoPlayer = aNotification.object as? VLCMediaPlayer else {return}
        switch videoPlayer.state{
        case .playing:
            print("VLCMediaPlayerDelegate: PLAYING")
            delegate?.onPlayerEvent(self, playState: .playing)
        case .opening:
            // 首帧显示
            print("VLCMediaPlayerDelegate: OPENING")
            
            guard let playerContext = dataSource?.getPlayerContext() else {
                return
            }
            
            playerContext.isReadyToPlay = true //*
            delegate?.onPlayerEvent(self, playState: .playing)
            
        case .error:
            print("VLCMediaPlayerDelegate: ERROR")
        case .buffering:
            print("VLCMediaPlayerDelegate: BUFFERING")
            delegate?.onPlayerEvent(self, playState: .stalling)
        case .stopped:
            print("VLCMediaPlayerDelegate: STOPPED")
            delegate?.onPlayerEvent(self, playState: .end)
        case .paused:
            print("VLCMediaPlayerDelegate: PAUSED")
            delegate?.onPlayerEvent(self, playState: .pause)
        case .ended:
            print("VLCMediaPlayerDelegate: ENDED")
            delegate?.onPlayerEvent(self, playState: .end)
        case .esAdded:
            print("VLCMediaPlayerDelegate: ELEMENTARY STREAM ADDED")
        default:
            break
        }
    }
    
    public func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let videoPlayer = aNotification.object as? VLCMediaPlayer else {return}
        let second = videoPlayer.time.intValue / 1000
        delegate?.player(onUpdateVideoCurrentTime: Int64(second))
        
        if let intValue = videoPlayer.media?.length.intValue {
            let second = intValue / 1000
            delegate?.player(onUpdateVideoTotalTime: Int64(second))
        }
        
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
        
        player.drawable = dataSource.getPlayerContentView().videoView
        
        guard let source = source else { return }
        
        repeat {
            player.media = source
            break
            isError = true
        } while false
        
        guard !isError else {
            return
        }
        
        player.play()
    }
    
    public func play() {
        player.play()
    }
    
    public func pause() {
        player.pause()
    }
    
    public func end() {
        player.stop()
    }
    
    public func seek(second: Int64) {
        let time = VLCTime(int: Int32(second) * 1000)
        player.time = time
    }
    
    ///
    public func setMute(_ isMute: Bool) {
        player.audio?.isMuted = isMute
    }
}
