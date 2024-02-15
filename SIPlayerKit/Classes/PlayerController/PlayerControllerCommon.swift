//
//  PlayerCommon.swift
//  CustomPlayer
//
//  Created by Paco on 17/1/2023.
//

import Foundation
import UIKit
import Combine

public protocol IPlayerController: AnyObject {

    var id: String { get }
    
    var originalScreenParentView: UIView? { get set }
    
    var originalScreenVC: UIViewController? { get set }
    
    var fullScreenVC: FullScreenViewController? { get set }
    
    var player: IPlayer { get }
    
    var playerContentView: PlayerContentView { get }
    
    var adsController: IAdsController? { get set }
    
    func prepareAndPlay() throws
    
    func prepare() throws //load video source to buffer
    
    func play() //it will start play source when buffering enough to play smoothly
    
    func pause() //pause video source from playing but still buffering
    
    func end()
    
    func setAds(controller: IAdsController?)
    
    func reloadAds()
    
    func reloadPlayerPanelAds()
    
    func setData(_ mediaUrl: String, screenType: VideoSourceScreenType, coverImageUrl: String?, defaultImage: UIImage?, title: String?, duration: Int64?)
    
    func showError(_ type: PlayerErrorViewType)
}

public enum PlayerErrorViewType {
    case noPlayButton
    case retry
    case endOfStream
}

public enum PlayerState {
    case playStateInit
    case playing
    case stalling
    case pause
    case end
    case error
}

public enum PlayState {
    case none
    case resume
    case pause
}

public enum AdsState {
    case adsStateInit
    case loading
    case playing
    case skippedOrFinishedOrError
}

public enum VideoSourceScreenType {
    case horizontal
    case vertical
}

public class PlayerControllerContext {
    
    /* 現時 Player 播放狀態 */
    public let playerState = CurrentValueSubject<PlayerState, Never>(.playStateInit)
    
    public let playState = CurrentValueSubject<PlayState, Never>(.none)
    
    /* 在首次播放時, 控制 Cover View 演示 (顯示/隱藏)*/
    var isReadyToPlay: Bool = false
    
    /* 用戶拖動進度條時, 需優先選用 用戶現時點擊位置 而非現時播放位置 */
    var isSeekingTimeByUser: Bool = false
    
    /// Foreground  和 Background 影響 auto play 和邏輯 Cover View 演示
    /// 獲得焦點 和 退出焦點 影響 auto play 邏輯和 Cover View 演示
    
    var isPausedByUser: Bool = false
    
    var shouldLoadAdsAtStart: Bool = true
    
    var adsState = CurrentValueSubject<AdsState, Never>(.adsStateInit)
    
    var started: Bool = false
    var prepared: Bool = false
    
    ///
    
    /// 現時 Video Info
    
    var isLive: Bool = false
    
    /* 現時 Video 總長度 */
    var videoTotalTime: Int64 = 0
    /* 現時播放位置 */
    var videoCurrentTime: Int64 = 0
    /* 上一次播放位置 */
    var lastVideoCurrentTime: Int64 = 0
    /* 現時播放已Buffered位置 */
    var videoBufferedTime: Int64 = 0
    
    ///
    
    
    /* 現時 system 音量 */
    //var soundValueBeforeMute: Float?
    
    /* 現時 Video 直片 / 橫片 */
    var videoSourceScreenType: VideoSourceScreenType = .horizontal
    
    func reset() {
        started = false
        prepared = false
        isSeekingTimeByUser = false
        playerState.send(.playStateInit)
    }
    
    func resetIsPausedByUser() {
        isPausedByUser = false
    }
    
    func resetIsSeekingTimeByUser() {
        isSeekingTimeByUser = false
    }
}

