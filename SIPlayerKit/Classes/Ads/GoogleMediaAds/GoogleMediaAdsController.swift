//
//  GoogleMediaAdsController.swift
//  CustomPlayer
//
//  Created by Paco on 7/2/2023.
//

import Foundation
import GoogleInteractiveMediaAds
import AdSupport
import Combine

public class GoogleMediaAdsController: IAdsController, GoogleMeidaAdsDelegate, AdsContentViewDelegate {
    
    var cancellable = Set<AnyCancellable>()
    
    weak public var delegate: AdsControllerDelegate?
    
    weak var parentViewController: UIViewController?
    
    lazy var contentView: AdsContentView = {
        let v = AdsContentView()
        v.muteOrUnmuteButtons.isHidden = false
        v.delegate = self
        return v
    }()
    
    lazy var googleMeidaAdsHelper: GoogleMeidaAdsHelper = {
        let h = GoogleMeidaAdsHelper()
        h.delegate = self
       return h
    }()
    
    public lazy var context: GoogleMeidaAdsContext = {
        return GoogleMeidaAdsContext()
    }()
 
    public var isPlaying: Bool? {
        get {
            return googleMeidaAdsHelper.isPlaying
        }
    }
    
    public var isValid: Bool {
        get {
            !context.adTagUrl.isEmpty
        }
    }
    
    public init() {
//        SIPlayerPreference.sound.receive(on: DispatchQueue.main).sink { [unowned self] sound in
//            if sound {
//                unmute()
//            } else {
//                mute()
//            }
//        }.store(in: &cancellable)
    }
    
    public func setAdTagUrl(_ adTagUrl: String, ppid: String? = nil) {
        context.adTagUrl = adTagUrl
        context.ppid = ppid
    }
    
    public func setupGoogleMediaAds(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
        context.adDisplayContainer = IMAAdDisplayContainer(adContainer: contentView.innerView, viewController: parentViewController)
    }
    
    public func resetCurrentParentViewController(_ parentViewController: UIViewController) {
        setupGoogleMediaAds(parentViewController: parentViewController)
    }
    
    /// AdsController
    
    public func getAdsContentView() -> UIView {
        return contentView
    }
    
    public func reloadAds() {
        googleMeidaAdsHelper.loadAds(with: context)
    }
    
    public func mute() {
        googleMeidaAdsHelper.adsManager?.volume = 0
        contentView.muteButton.isHidden = false
        contentView.unmuteButton.isHidden = true
    }
    
    public func unmute() {
        googleMeidaAdsHelper.adsManager?.volume = 1
        contentView.muteButton.isHidden = true
        contentView.unmuteButton.isHidden = false
    }
    
    public func resume() {
        contentView.resumeButton.isHidden = true
        context.mediaAdsPlayState.send(.resume)
        googleMeidaAdsHelper.adsManager?.resume()
        if googleMeidaAdsHelper.isAdsLoaderLoaded == false && (googleMeidaAdsHelper.isPlaying == nil || googleMeidaAdsHelper.isPlaying! == false) {
            reloadAds()
        }
    }
    
    public func pause() {
        context.mediaAdsPlayState.send(.pause)
        googleMeidaAdsHelper.adsManager?.pause()
        contentView.resumeButton.isHidden = false
    }
    
    public func destory() {
        googleMeidaAdsHelper.adsManager?.destroy()
    }
    
    ///
    
    /// CustomPlayer - GoogleMeidaAdsDelegate
    
    func googleMeidaAdsHelper(_ googleMeidaAdsHelper: GoogleMeidaAdsHelper, onEvent event: GoogleMeidaAdsHelper.GoogleMeidaAdsState) {
        
        if let _ = event as? GoogleMeidaAdsHelper.GoogleMeidaAdsLoading {
            context.mediaAdsState.send(.loading)
            /* It can skip call adsViewShouldAppear() */
//            delegate?.adsViewShouldAppear()
        }
        
        if let _ = event as? GoogleMeidaAdsHelper.GoogleMeidaAdsloadedError {
            context.mediaAdsState.send(.loadedError)
            /* It can skip call adsViewShouldDisappear() */
            delegate?.adsViewShouldDisappear()
        }
        
//        if let _ = event as? GoogleMeidaAdsHelper.GoogleMeidaAdsPause {
//            context.mediaAdsState.send(.pause)
//        }
        
        if let _ = event as? GoogleMeidaAdsHelper.GoogleMeidaAdsPlaying {
            contentView.resumeButton.isHidden = true
            context.mediaAdsState.send(.playing)
            if SIPlayerPreference.sound.value {
                unmute()
            } else {
                mute()
            }
            delegate?.adsViewShouldAppear()
        }
        
        if let _ = event as? GoogleMeidaAdsHelper.GoogleMeidaAdsPlayed {
            context.mediaAdsPlayState.send(.none)
            context.mediaAdsState.send(.skipOrFinished)
            delegate?.adsViewShouldDisappear()
        }
        
        if let _ = event as? GoogleMeidaAdsHelper.GoogleMeidaAdsSkipped {
            context.mediaAdsPlayState.send(.none)
            context.mediaAdsState.send(.skipOrFinished)
            delegate?.adsViewShouldDisappear()
        }
    }
    
    /// AdsContentView - AdsContentViewDelegate
    
    func adsContentView(_ adsController: AdsContentView, resumeDidPressed: UIControl) {
        resume()
//        delegate?.adsController(self, resumeDidPressed: contentView.muteButton)
    }
    
    func adsContentView(_ adsContentView: AdsContentView, muteDidPressed: UIControl) {
        unmute()
        SIPlayerPreference.sound.send(true)
        delegate?.adsController(self, muteDidPressed: contentView.muteButton)
    }
    
    func adsContentView(_ adsContentView: AdsContentView, unmuteDidPressed: UIControl) {
        mute()
        SIPlayerPreference.sound.send(false)
        delegate?.adsController(self, unmuteDidPressed: contentView.unmuteButton)
    }
    ///
}
