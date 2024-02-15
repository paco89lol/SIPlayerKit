//
//  GoogleMeidaAdsHelper.swift
//  CustomPlayer
//
//  Created by Paco on 7/2/2023.
//

import Foundation
import UIKit
import GoogleInteractiveMediaAds
import AdSupport
import Combine

extension GoogleMeidaAdsHelper {
    
    class GoogleMeidaAdsState {}

    class GoogleMeidaAdsInit: GoogleMeidaAdsState {}
    class GoogleMeidaAdsLoading: GoogleMeidaAdsState {}
    class GoogleMeidaAdsloadedError: GoogleMeidaAdsState {}
//    class GoogleMeidaAdsPause: GoogleMeidaAdsState {}
    class GoogleMeidaAdsPlaying: GoogleMeidaAdsState {}
    class GoogleMeidaAdsPlayed: GoogleMeidaAdsState {}
    class GoogleMeidaAdsSkipped: GoogleMeidaAdsState {}
}

public enum MediaAdsState {

    case mediaAdsStateInit
    case loading
    case loadedError
    case playing
    case skipOrFinished
}

public enum MediaAdsPlayState {
    case none
    case resume
    case pause
}

public class GoogleMeidaAdsContext {
    public var adTagUrl: String = ""
    public var adDisplayContainer: IMAAdDisplayContainer?
    public var ppid: String?
    public var mediaAdsState = CurrentValueSubject<MediaAdsState, Never>(.mediaAdsStateInit)
    public var mediaAdsPlayState = CurrentValueSubject<MediaAdsPlayState, Never>(.resume)
}

protocol GoogleMeidaAdsDelegate: AnyObject {
    
    func googleMeidaAdsHelper(_ googleMeidaAdsHelper: GoogleMeidaAdsHelper, onEvent event: GoogleMeidaAdsHelper.GoogleMeidaAdsState)
}


class GoogleMeidaAdsHelper: NSObject, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    
    weak var delegate: GoogleMeidaAdsDelegate?
    
    weak var context: GoogleMeidaAdsContext?
    
    lazy var settings: IMASettings = {
       return IMASettings()
    }()
    
    lazy var adsLoader: IMAAdsLoader = {
        let l = IMAAdsLoader(settings: settings)
        delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsInit())
        l.delegate = self
        return l
    }()
    
    var adsManager: IMAAdsManager?
    
    var isPlaying: Bool? {
        get {
            adsManager?.adPlaybackInfo.isPlaying
        }
    }
    
    // only fire once, the first time adsLoader load
    var isAdsLoaderLoaded: Bool = false
    
    func loadAds(with context: GoogleMeidaAdsContext) {
        guard let adDisplayContainer = context.adDisplayContainer else { return }
        let request = IMAAdsRequest(adTagUrl: context.adTagUrl, adDisplayContainer: adDisplayContainer, contentPlayhead: nil
                                    , userContext: nil)
        settings = IMASettings()
        settings.ppid = context.ppid
        let loader = IMAAdsLoader(settings: settings)
        delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsLoading())
        loader.delegate = self
        adsLoader = loader
        adsLoader.requestAds(with: request)
    }
    
    // GoogleInteractiveMediaAds - IMAAdsLoaderDelegate
    
    // request media ads from google server
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        guard let adsManager = adsManager else {
            delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsloadedError())
            return
        }
        isAdsLoaderLoaded = true
        adsManager.delegate = self
        adsManager.initialize(with: nil)
        adsManager.start()
    }

    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        print(adErrorData.adError.message)
        adsManager?.delegate = nil
        adsManager?.destroy()
        adsManager = nil
        delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsloadedError())
    }
    
    // GoogleInteractiveMediaAds - IMAAdsManagerDelegate
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        if event.type == .STARTED {
            if context?.mediaAdsPlayState.value == .pause {
                adsManager.pause()
            } else {
                adsManager.resume()
                delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsPlaying())
            }
        }
        
//        if event.type == .LOADED {
//            delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsPlaying())
//        }
        
//        if event.type == .PAUSE {
//            delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsPause())
//        }
//
//        if event.type == .RESUME {
//            delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsPlaying())
//        }
        
        if event.type == .SKIPPED {
            delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsSkipped())
        }
        
        if event.type == .COMPLETE {
            delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsPlayed())
        }
        
    }

    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        self.adsManager?.delegate = nil
        self.adsManager?.destroy()
        self.adsManager = nil
        delegate?.googleMeidaAdsHelper(self, onEvent: GoogleMeidaAdsloadedError())
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        
    }
}


