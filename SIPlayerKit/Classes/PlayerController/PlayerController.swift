//
//  AnyPlayerController.swift
//  CustomPlayer
//
//  Created by Paco on 7/2/2023.
//

import Foundation
import MediaPlayer
import Combine

public class AdsViewDelegateHandler: AdsControllerDelegate {
    
    weak var controller: PlayerController?
    
    var adsDisappearBlock: ((PlayerController) -> Void)?
    var adsAppearBlock: ((PlayerController) -> Void)?
    
    var adsMuteBlock: ((PlayerController) -> Void)?
    var adsUnmuteBlock: ((PlayerController) -> Void)?
    
    public func adsViewShouldDisappear() {
        guard let controller = controller else { return }
        adsDisappearBlock?(controller)
    }
    
    public func adsViewShouldAppear() {
        guard let controller = controller else { return }
        adsAppearBlock?(controller)
    }
    
    public func adsController(_ adsController: IAdsController, muteDidPressed: UIControl) {
        guard let controller = controller else { return }
        adsMuteBlock?(controller)
    }
    
    public func adsController(_ adsController: IAdsController, unmuteDidPressed: UIControl) {
        guard let controller = controller else { return }
        adsUnmuteBlock?(controller)
    }
    
    deinit {
        adsDisappearBlock = nil
        adsAppearBlock = nil
        adsMuteBlock = nil
        adsUnmuteBlock = nil
    }
}

public protocol PlayerControllerDelegate: AnyObject {
    
    func playerController(_ playerController: PlayerController, didClickCoverImage: UIControl, playerContext: PlayerControllerContext)
    func playerController(_ playerController: PlayerController, didClickPlay: UIControl, playerContext: PlayerControllerContext)
    func playerController(_ playerController: PlayerController, didClickReplay: UIControl, playerContext: PlayerControllerContext)
    func playerController(_ playerController: PlayerController, didClickPause: UIControl, playerContext: PlayerControllerContext)
    func playerController(_ playerController: PlayerController, didClickRetry: UIControl, playerContext: PlayerControllerContext)
    func playerController(_ playerController: PlayerController, didClickBack: UIControl, playerContext: PlayerControllerContext)
    func playerController(_ playerController: PlayerController, didHiddenPanelView: UIView)
    func playerController(_ playerController: PlayerController, didShowPanelView: UIView)
}

extension PlayerControllerDelegate {
    func playerController(_ playerController: PlayerController, didClickBack: UIControl, playerContext: PlayerControllerContext) {}
}

public class PlayerController: NSObject, IPlayerController, PlayerPanelDelegate, PlayerCoverViewDelegate {

    public let id: String = UUID().uuidString
    
    var cancellable = Set<AnyCancellable>()
    
    let playerContext = PlayerControllerContext()
    
    public var player: IPlayer
    
    lazy public var playerContentView: PlayerContentView = {
        let v = PlayerContentView()
        v.panelView.delegate = self
        v.coverView.delegate = self
        return v
    }()
    
    /// View configuration
    
    public var shouldShowBackButtonOnOriginalScreenSize: Bool = false {
        didSet {
            if shouldShowBackButtonOnOriginalScreenSize {
                playerContentView.panelView.headerView.backButton.isHidden = false
                playerContentView.coverView.backButton.isHidden = false
            } else {
                playerContentView.panelView.headerView.backButton.isHidden = true
                playerContentView.coverView.backButton.isHidden = true
            }
        }
    }
    
    /// Ads Related
    
    public var adsController: IAdsController?
    
    lazy var adsViewDelegateHandler: AdsViewDelegateHandler = {
        let handler = AdsViewDelegateHandler()
        handler.controller = self
        handler.adsDisappearBlock = { [weak self] playerController in
            guard let self = self else { return }
            playerController.playerContext.adsState.send(.skippedOrFinishedOrError)
            playerController.playerContentView.adsView.isHidden = true
//            if playerController.playerContext.playState.value == .pause { /* It might not be useful */
//                return
//            }
            playerController.resumePlayerByAds() /* It might call duplicated */
        }
        
        handler.adsAppearBlock = { [weak self] playerController in
            guard let self = self else { return }
            if playerController.playerContext.playState.value == .pause || playerController.playerContext.playState.value == .none {
                playerController.playerContext.adsState.send(.skippedOrFinishedOrError)
                adsController?.destory()
            } else {
                playerController.playerContext.adsState.send(.playing)
                playerController.pausePlayerByAds()
                playerController.playerContentView.adsView.isHidden = false
            }
        }
        

        handler.adsMuteBlock = { [weak self] playerController in
            guard let self = self else { return }
            playerController.unmute()
//            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [])
            SIPlayerPreference.sound.send(true)
        }
        
        handler.adsUnmuteBlock = { [weak self] playerController in
            guard let self = self else { return }
            playerController.mute()
//            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            SIPlayerPreference.sound.send(false)
        }
        return handler
    }()
    
    var playerPanelAdsController: IAdsController?
    
    lazy var playerPanelAdsViewDelegateHandler: AdsViewDelegateHandler = {
        let handler = AdsViewDelegateHandler()
        handler.controller = self
        handler.adsDisappearBlock = { [weak self] playerController in
            guard let self = self else { return }
            playerController.playerContentView.panelView.contentView.adsView.isHidden = true
        }
        
        handler.adsAppearBlock = { [weak self] playerController in
            guard let self = self else { return }
            playerController.playerContentView.panelView.contentView.adsView.isHidden = false
        }
        return handler
    }()
    
    ///
    weak public var fullScreenVC: FullScreenViewController?
    
    ///
    weak public var originalScreenVC: UIViewController? // Google Ads Require parent UIViewController
    ///
    
    
    ///
    weak public var originalScreenParentView: UIView?
    ///
    
    weak public var delegate: PlayerControllerDelegate?
    
    /// Log
    public var logProgessBlock: ((_ currentTime: Int64, _ totalTime: Int64) -> Void)?
    ///
    
    deinit {
        logProgessBlock = nil
        player.end()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    public init(player: IPlayer) {
        self.player = player
        super.init()
        setup()
    }
    
    private func setup() {
        
        player.delegate = self
        player.dataSource = self
        
        playerContentView.panelView.hidePanel()
        
        playerContext.playerState.sink { [weak self] playState in
            guard let self = self else { return }
            switch playState {
            case .error:
                playerContentView.panelView.contentView.playButton.isHidden = true
                playerContentView.coverView.isHidden = false
                playerContentView.coverView.showRetryView()
//                if !playerContentView.isLive {
//                    playerContentView.coverView.showRetryView()
//                } else {
//                    playerContentView.coverView.showEndOfLiveView()
//                }
                
            case .playStateInit:
                playerContentView.panelView.contentView.playButton.isHidden = true
                playerContentView.panelView.contentView.pauseButton.isHidden = true
                playerContentView.panelView.contentView.replayButton.isHidden = true
                playerContentView.panelView.contentView.loadingView.isHidden = true
                
            case .playing:
                /* Stalling might not be happen when network is fast enough */
                playerContentView.coverView.isHidden = true
                
                playerContentView.panelView.contentView.playButton.isHidden = true
                playerContentView.panelView.contentView.pauseButton.isHidden = false
                playerContentView.panelView.contentView.replayButton.isHidden = true
                playerContentView.panelView.contentView.loadingView.stopAnimating()
            case .stalling:
                
                if !playerContext.isReadyToPlay {
                    playerContentView.coverView.isHidden = false
                    playerContentView.coverView.showLoadingView()
                } else {
                    playerContentView.coverView.isHidden = true
                    playerContentView.coverView.loadingView.isHidden = true
                }
                
                playerContentView.panelView.contentView.playButton.isHidden = true
                playerContentView.panelView.contentView.pauseButton.isHidden = true
                playerContentView.panelView.contentView.replayButton.isHidden = true
                playerContentView.panelView.contentView.loadingView.isHidden = false
                playerContentView.panelView.contentView.loadingView.startAnimating()
            case .pause:
                playerContentView.panelView.contentView.playButton.isHidden = false
                playerContentView.panelView.contentView.pauseButton.isHidden = true
                playerContentView.panelView.contentView.replayButton.isHidden = true
                playerContentView.panelView.contentView.loadingView.isHidden = true
            case .end:
                playerContentView.panelView.contentView.playButton.isHidden = true
                playerContentView.panelView.contentView.pauseButton.isHidden = true
                playerContentView.panelView.contentView.replayButton.isHidden = false
                playerContentView.panelView.contentView.loadingView.isHidden = true
                
                playerContext.isPausedByUser = true
                
                if fullScreenVC != nil {
                    // show panel
                    playerContentView.panelView.showPanel(autoFadeOut: false)
                } else {
                    // show cover view
                    playerContentView.coverView.isHidden = false
                    playerContentView.coverView.imageView.isHidden = true
                    playerContentView.coverView.showReplayView()
                }
                
            }
            
        }.store(in: &cancellable)
        
        SIPlayerPreference.sound.receive(on: DispatchQueue.main).sink { [weak self] sound in
            guard let self = self else { return }
            
            if sound {
                unmute()
            } else {
                mute()
            }
            
        }.store(in: &cancellable)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChangeCallback), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(systemAudioSessionCallBack), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    /// Ads Setting
    
    public func setAds(controller: IAdsController?) {
        
        guard let controller = controller else {
            adsController = nil
            return
        }
        
        adsController = controller
        controller.delegate = adsViewDelegateHandler
        playerContentView.setAdsSubView(controller.getAdsContentView())
    }
    
    /// PlayerPanel Ads
    // Remark :-  if Google Ads only support GADAdSizeBanner because of the size limitation of presentation
    public func setPlayerPanelAds(controller: IAdsController?) {
        guard let controller = controller else {
            playerPanelAdsController = nil
            return
        }
        playerPanelAdsController = controller
        controller.delegate = playerPanelAdsViewDelegateHandler
        playerContentView.panelView.contentView.setAdsSubView(controller.getAdsContentView())
    }
    
    var reloadCount = 0
    public func reloadAds() {
        
        guard let adsController = adsController, adsController.isValid else {
            // It will lead to a player in a unknown status
            playerContext.adsState.send(.skippedOrFinishedOrError)
            resumePlayerByAds()
            return
        }
        playerContext.adsState.send(.loading)
        adsController.reloadAds()
        reloadCount += 1
        print("reloadCount: \(reloadCount)")
    }
    
    public func reloadPlayerPanelAds() {
        playerPanelAdsController?.reloadAds()
    }
    
    public func showError(_ type: PlayerErrorViewType) {
        playerContentView.coverView.isHidden = false
        switch type {
        case .retry:
            playerContentView.coverView.showRetryView()
        case .endOfStream:
            playerContentView.coverView.showEndOfLiveView()
        case .noPlayButton:
            playerContentView.coverView.showNothing()
        }
        
    }
    
    public func setData(_ mediaUrl: String, screenType: VideoSourceScreenType, coverImageUrl: String?, defaultImage: UIImage?, title: String?, duration: Int64?) {
        
        if !mediaUrl.isEmpty {
            let _mediaUrl = mediaUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            if player.mediaUrlString != mediaUrl {
                playerContext.reset()
                player.setSource(url: mediaUrl)
            }
        } else {
            playerContext.reset()
            player.setSource(url: nil)
            playerContentView.coverView.showNothing()
        }
        
        playerContext.videoSourceScreenType = screenType
        
        playerContentView.coverView.setCoverImage(url: coverImageUrl?.trimmingCharacters(in: .whitespacesAndNewlines), defaultImage: defaultImage)
        playerContentView.coverView.setDurationLabel(second: duration)
        playerContentView.panelView.headerView.titleView.text = title
        
//        if playerContentView.panelView.headerView.titleView.text == nil || playerContentView.panelView.headerView.titleView.text!.isEmpty {
//            playerContentView.panelView.headerView.titleView.isHidden = true
//        } else {
//            playerContentView.panelView.headerView.titleView.isHidden = false
//        }
    }
    
    // Not Using
    // e.g. foreground / player focus
    public func playerWillBecomeActive() {
        if !playerContext.started {
            return
        }
        
        if !playerContext.prepared {
            return
        }
        
        if playerContext.playerState.value != .pause {
            return
        }
        
        if playerContext.isPausedByUser {
            playerContentView.coverView.reset()
            playerContentView.coverView.isHidden = false
            return
        }
        
        play()
    }
    
    // Not Using
    // e.g. background / player not focus
    public func playerWillBecomeInactive() {
        if !playerContext.started {
            return
        }
        
        if !playerContext.prepared {
            return
        }
        
        if playerContext.playerState.value != .playing {
            return
        }
        
        pause()
    }
    
    public func prepareAndPlay() throws {
        try prepare()
        play()
    }
    
    public func prepare() throws {
        
        if !player.isSetSource {
             return
        }
        
        do {
            try player.prepare()
            playerContext.prepared = true
        } catch {
            playerContentView.coverView.showRetryView()
//            if !playerContentView.isLive {
//                playerContentView.coverView.showRetryView()
//            } else {
//                playerContentView.coverView.showEndOfLiveView()
//            }
            
        }
    }
    
    public func play() {
        playerContext.playState.send(.resume)
        
        if !player.isSetSource {
             return
        }
        
        if playerContext.prepared == false {
            try? prepare()
        }
        
        let playBlock = { [weak self] in
            
            guard let self = self else { return }
            
            self.playerContext.started = true
            /* 在首次載入 Video 仍然處於填充缓冲區(first loading)階段時, Cover View 要處於顯示狀態 */
            /* .stalling instread of .playing */
            if self.playerContext.playerState.value != .playing {
                self.playerContext.playerState.send(.stalling)
                self.player.play()
            }
        }
        
        if !playerContext.shouldLoadAdsAtStart {
            playBlock()
        } else {
            switch playerContext.adsState.value {
            case .loading: break
            case .playing:
                adsController?.resume()
            case .adsStateInit:
                if adsController == nil {
                    playBlock()
                } else {
                    reloadAds()
                }
                
            case .skippedOrFinishedOrError:
                playBlock()
            }
        }
        
        if SIPlayerPreference.sound.value == true {
            try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [])
        }
        
    }
    
    // only invoke by ads
    internal func resumePlayerByAds() {
        if !player.isSetSource {
             return
        }
        
        if playerContext.prepared == false {
            try? prepare()
        }
        
        self.playerContext.started = true
        /* 在首次載入 Video 仍然處於填充缓冲區(first loading)階段時, Cover View 要處於顯示狀態 */
        /* .stalling instread of .playing */
        if self.playerContext.playerState.value != .playing {
            self.playerContext.playerState.send(.stalling)
            self.player.play()
        }
    }
    
    public func backFromFullScreen() {
        if !shouldShowBackButtonOnOriginalScreenSize {
            playerContentView.panelView.headerView.backButton.isHidden = true
        } else {
            playerContentView.panelView.headerView.backButton.isHidden = false
        }
        
        playerContentView.panelView.footerView.playerVideoBar.fullScreenButton.isHidden = false
        playerContentView.panelView.footerView.playerVideoBar.originalScreenButton.isHidden = true
        guard let parentView = originalScreenParentView else { return }
        guard let originalScreenVC = originalScreenVC else { return }
        self.playerContentView.layer.setAffineTransform(.identity)
        parentView.addSubview(playerContentView)
        playerContentView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalToSuperview()
        }
        resetAdsParentViewControllerForOriginalScreen(viewController: originalScreenVC)
        fullScreenVC?.dismiss(animated: true)
        PlayerFullScreen.currentVC.send(nil)
        fullScreenVC = nil
    }
    
    func seek(second: Int64) {
        if (playerContext.videoTotalTime == 0) {
            return
        }
        
        player.seek(second: second)
    }
    
    public func pause() {
        playerContext.playState.send(.pause)
        if player.isSetSource {
            playerContext.playerState.send(.pause)
            player.pause()
        }
        
        if playerContext.adsState.value == .playing {
            adsController?.pause()
        }
    }
    // Extra pause function
    public func pauseWithCoverPage() {
        pause()
        playerContentView.coverView.isHidden = false
        playerContentView.coverView.showPlayView()
    }
    
    // only invoke by ads
    internal func pausePlayerByAds() {
        if player.isSetSource {
            playerContext.playerState.send(.pause)
            player.pause()
        }
    }
    
    // basically no use
    public func end() {
        playerContext.playState.send(.none)
        playerContext.playerState.send(.end)
        player.end()
    }
    
    public func mute() {
        playerContentView.panelView.muteButton.isHidden = false
        playerContentView.panelView.unmuteButton.isHidden = true
        player.setMute(true)
    }
    
    public func unmute() {
        player.setMute(false)
        playerContentView.panelView.muteButton.isHidden = true
        playerContentView.panelView.unmuteButton.isHidden = false
    }
    
    // PlayerPanelDelegate
    
    func playerPanel(_ playerPanelView: PlayerPanel, playDidPressed: UIControl) {
        delegate?.playerController(self, didClickPlay: playDidPressed, playerContext: playerContext)
        playerContext.resetIsPausedByUser()
        play()
        playerContentView.panelView.contentView.playButton.isHidden = true
        playerContentView.panelView.contentView.pauseButton.isHidden = false
        playerContentView.panelView.contentView.loadingView.stopAnimating()
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, pauseDidPressed: UIControl) {
        delegate?.playerController(self, didClickPause: pauseDidPressed, playerContext: playerContext)
        playerContentView.panelView.contentView.playButton.isHidden = false
        playerContentView.panelView.contentView.pauseButton.isHidden = true
        playerContentView.panelView.contentView.loadingView.stopAnimating()
        playerContext.isPausedByUser = true
        pause()
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, replayDidPressed: UIControl) {
        delegate?.playerController(self, didClickReplay: replayDidPressed, playerContext: playerContext)
        playerContext.resetIsPausedByUser()
        seek(second: 0)
        play()
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, muteDidPressed: UIControl) {
//        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [])
        unmute()
        SIPlayerPreference.sound.send(true)
        
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, unmuteDidPressed: UIControl) {
//        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
        mute()
//        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        SIPlayerPreference.sound.send(false)
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, backDidPressed: UIControl) {
        
        if fullScreenVC != nil {
            backFromFullScreen()
//            if !shouldShowBackButtonOnOriginalScreenSize {
//                playerContentView.panelView.headerView.backButton.isHidden = true
//            } else {
//                playerContentView.panelView.headerView.backButton.isHidden = false
//            }
//
//            playerContentView.panelView.footerView.playerVideoBar.fullScreenButton.isHidden = false
//            playerContentView.panelView.footerView.playerVideoBar.originalScreenButton.isHidden = true
//            guard let parentView = originalScreenParentView else { return }
//            guard let originalScreenVC = originalScreenVC else { return }
//            self.playerContentView.layer.setAffineTransform(.identity)
//            parentView.addSubview(playerContentView)
//            playerContentView.snp.makeConstraints { make in
//                make.left.top.right.equalToSuperview()
//                make.height.equalToSuperview()
//            }
//            resetAdsParentViewControllerForOriginalScreen(viewController: originalScreenVC)
//            fullScreenVC?.dismiss(animated: true)
//            fullScreenVC = nil
        } else {
            // Normal Back BLock
            delegate?.playerController(self, didClickBack: backDidPressed, playerContext: self.playerContext)
        }
    }
    
    var ftm: FullScreenTransitionManager!
    
    private func resetAdsParentViewControllerForFullScreen(viewController: FullScreenViewController) {
        adsController?.resetCurrentParentViewController(viewController)
        playerPanelAdsController?.resetCurrentParentViewController(viewController)
    }
    private func resetAdsParentViewControllerForOriginalScreen(viewController: UIViewController) {
        adsController?.resetCurrentParentViewController(viewController)
        playerPanelAdsController?.resetCurrentParentViewController(viewController)
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, fullScreenDidPressed: UIControl) {
        playerContentView.panelView.headerView.backButton.isHidden = false
        playerContentView.panelView.footerView.playerVideoBar.fullScreenButton.isHidden = true
        playerContentView.panelView.footerView.playerVideoBar.originalScreenButton.isHidden = false
        
        let fullScreenViewController = FullScreenViewController()
        fullScreenVC = fullScreenViewController
        ftm = FullScreenTransitionManager()
        ftm?.anchorView = playerContentView
        fullScreenViewController.modalPresentationStyle = .custom
        fullScreenViewController.transitioningDelegate = ftm
        fullScreenViewController.playerController = self
        resetAdsParentViewControllerForFullScreen(viewController: fullScreenViewController)
        originalScreenVC?.present(fullScreenViewController, animated: true, completion: { [weak fullScreenViewController, weak self] in
            // for global accessibility
            PlayerFullScreen.currentVC.send(fullScreenViewController)
            
            if self?.playerContext.videoSourceScreenType == .horizontal {
                // force to LandscapeLeft at fullscreen
                fullScreenViewController?.moveToLandscapeLeft()
            } else {
                
            }
            
        })
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, originalScreenDidPressed: UIControl) {
        backFromFullScreen()
//        if !shouldShowBackButtonOnOriginalScreenSize {
//            playerContentView.panelView.headerView.backButton.isHidden = true
//        } else {
//            playerContentView.panelView.headerView.backButton.isHidden = false
//        }
//
//        playerContentView.panelView.footerView.playerVideoBar.fullScreenButton.isHidden = false
//        playerContentView.panelView.footerView.playerVideoBar.originalScreenButton.isHidden = true
//        // exit from fullscreen
//        guard let parentView = originalScreenParentView else { return }
//        guard let originalScreenVC = originalScreenVC else { return }
//        self.playerContentView.layer.setAffineTransform(.identity)
//        parentView.addSubview(playerContentView)
//        playerContentView.snp.makeConstraints { make in
//            make.left.top.right.equalToSuperview()
//            make.height.equalToSuperview()
//        }
//        resetAdsParentViewControllerForOriginalScreen(viewController: originalScreenVC)
//        fullScreenVC?.dismiss(animated: true)
//        fullScreenVC = nil
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, onPanValueChange value: Float) {
        let second = playerContext.videoTotalTime * Int64(value * 100) / 100
        playerContentView.panelView.footerView.playerVideoBar.setCurrent(totalSecond: playerContext.videoTotalTime, second: second)
        playerContentView.panelView.footerView.playerVideoBar.setCurrentTimeLabel(second: second)
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, onTocuhUp value: Float) {
        playerContext.resetIsSeekingTimeByUser()
        let second = playerContext.videoTotalTime * Int64(value * 100) / 100
        seek(second: second)
    }
    
    func playerPanel(_ playerPanelView: PlayerPanel, onTocuhDown value: Float) {
        playerContext.isSeekingTimeByUser = true
    }
    
    func playerPanelSeekToDate(_ playerPanelView: PlayerPanel, time: Int64) {
        seek(second: time)
    }
    
    
    // PlayerCoverViewDelegate
    
    func playerCoverView(_ view: PlayerCoverView, coverImageDidPressed button: UIControl) {
        delegate?.playerController(self, didClickCoverImage: button, playerContext: playerContext)
    }
    
    func playerCoverView(_ view: PlayerCoverView, playDidPressed button: UIControl) {
        delegate?.playerController(self, didClickPlay: button, playerContext: playerContext)
        playerContext.resetIsPausedByUser()
        if !playerContext.started && !playerContext.prepared {
            try? prepareAndPlay()
        } else {
            play()
        }
    }
    
    func playerCoverView(_ view: PlayerCoverView, retryPlayDidPressed button: UIControl) {
        delegate?.playerController(self, didClickRetry: button, playerContext: playerContext)
        playerContext.resetIsPausedByUser()
        try? prepareAndPlay()
    }
    
    func playerCoverView(_ view: PlayerCoverView, replayDidPressed button: UIControl) {
        delegate?.playerController(self, didClickReplay: button, playerContext: playerContext)
        playerContext.resetIsPausedByUser()
        seek(second: 0)
        play()
    }
    
    func playerCoverView(_ view: PlayerCoverView, backDidPressed button: UIControl) {
        delegate?.playerController(self, didClickBack: button, playerContext: playerContext)
    }
    
    /// 監聽外部設備改變 Callback
    
    @objc func audioRouteChangeCallback(notification: Notification) {
        
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let routeChangeReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt else {
            return
        }
        
        guard let reason = AVAudioSession.RouteChangeReason(rawValue: routeChangeReason) else {
            return
        }
        
        switch reason {
        case AVAudioSession.RouteChangeReason.newDeviceAvailable:
            break
        case AVAudioSession.RouteChangeReason.oldDeviceUnavailable:
            
            if SIPlayerPreference.sound.value == true && playerContext.playerState.value == .playing && playerContentView.subviews != nil {
                self.playerPanel(playerContentView.panelView, pauseDidPressed: playerContentView.panelView.contentView.playButton)
            }
            
        case AVAudioSession.RouteChangeReason.categoryChange:
            break
        default:
            break
        }
        
    }
    
    /// 電話、鬧鈴等一般性中斷通知 Callback
    
    @objc func systemAudioSessionCallBack(notification: Notification) {
        
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let interruptType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else {
            return
        }
        
        guard let type = AVAudioSession.InterruptionType(rawValue: interruptType) else {
            return
        }
        
        switch type {
        case AVAudioSession.InterruptionType.began:
            if SIPlayerPreference.sound.value == true && playerContext.playerState.value == .playing && playerContentView.subviews != nil {
                self.playerPanel(playerContentView.panelView, pauseDidPressed: playerContentView.panelView.contentView.playButton)
            }
        case AVAudioSession.InterruptionType.ended:
            break
        default:
            break
        }
        
    }
    
}


extension PlayerController: IPlayerDelegate {

    public func onPlayerEvent(_ player: IPlayer, playState: PlayerState) {
        playerContext.playerState.send(playState)
    }
    
    public func player(onError error: Error) {
        playerContext.playerState.send(.error)
        playerContext.prepared = false
        print(error)
    }
    
    public func player(onUpdateVideoCurrentTime second: Int64) {
        defer {
            playerContext.lastVideoCurrentTime = second
        }
        
        if (playerContext.lastVideoCurrentTime != second) {
            
            if playerContext.playerState.value == .stalling {
                playerContext.playerState.send(.playing)
            }
        }
        
        if playerContext.isSeekingTimeByUser {
            return
        }
        
        playerContext.videoCurrentTime = second
        playerContentView.panelView.footerView.playerVideoBar.setCurrent(totalSecond: playerContext.videoTotalTime, second: playerContext.videoCurrentTime)
        playerContentView.panelView.footerView.playerVideoBar.setCurrentTimeLabel(second: playerContext.videoCurrentTime)
        
        /* reduce the call time if currentTime is same, calculated by a unit of second */
        if playerContext.lastVideoCurrentTime != playerContext.videoCurrentTime {
            logProgessBlock?(playerContext.videoCurrentTime, playerContext.videoTotalTime)
        }
    }
    
    public func player(onUpdateVideoTotalTime second: Int64) {
        if second == 0 {
            playerContext.isLive = true
            playerContentView.panelView.isLive = true
            playerContentView.panelView.footerView.playerVideoBar.videoProgressBar.isUserInteractionEnabled = false
        } else {
            playerContext.isLive = false
            playerContentView.panelView.isLive = false
            playerContentView.panelView.footerView.playerVideoBar.videoProgressBar.isUserInteractionEnabled = true
        }
        playerContext.videoTotalTime = second
        playerContentView.panelView.footerView.playerVideoBar.setTotalTimeLabel(second: playerContext.videoTotalTime)
    }
    
    public func player(onUpdateVideoBufferedTime second: Int64) {
        playerContext.videoBufferedTime = second
        playerContentView.panelView.footerView.playerVideoBar.setBuffer(totalSecond: playerContext.videoTotalTime, buffered: playerContext.videoBufferedTime)
    }
    
    
}

extension PlayerController: IPlayerDataSource {
    
    public func getPlayerContext() -> PlayerControllerContext {
        return playerContext
    }
    
    public func getPlayerContentView() -> PlayerContentView {
        return playerContentView
    }
    
}
