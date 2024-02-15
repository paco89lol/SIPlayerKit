//
//  GoogleMobileAdsBannerController.swift
//  CustomPlayer
//
//  Created by Paco on 8/2/2023.
//

import Foundation
import UIKit
import GoogleMobileAds


public class GoogleMobileAdsBnnnerContext {
    var adUnitID: String = ""
    weak var parentViewController: UIViewController?
}

public enum GoogleMobileAdsBnnnerSize {
    /* Reference -> https://developers.google.com/ad-manager/mobile-ads-sdk/ios/banner?hl=zh-cn */
    case GADAdSizeBanner //手机和平板电脑 横幅广告, 320x50
    case GADAdSizeLargeBanner //手机和平板电脑 大型横幅广告, 320x100
    case GADAdSizeMediumRectangle //手机和平板电脑 IAB 中矩形, 300x250
    case GADAdSizeFullBanner //平板电脑 IAB 全尺寸横幅广告, 468x60
    case GADAdSizeLeaderboard //平板电脑 IAB 页首横幅广告, 728x90
    case customSize(_ size: CGSize)
    
    func toSize() -> CGSize {
        switch self {
        case .GADAdSizeBanner:
            return GoogleMobileAds.GADAdSizeBanner.size
        case .GADAdSizeLargeBanner:
            return GoogleMobileAds.GADAdSizeLargeBanner.size
        case .GADAdSizeMediumRectangle:
            return GoogleMobileAds.GADAdSizeMediumRectangle.size
        case .GADAdSizeFullBanner:
            return GoogleMobileAds.GADAdSizeFullBanner.size
        case .GADAdSizeLeaderboard:
            return GoogleMobileAds.GADAdSizeLeaderboard.size
        case .customSize(let size):
            return size
        }
    }
}

public class GoogleMobileAdsBnnnerController: NSObject, IAdsController, GADBannerViewDelegate {
    
    lazy var bannerView: GAMBannerView = {
        var s = GADAdSize()
        
        s.size = CGSize(width: GADAdSizeLargeBanner.size.width, height: GADAdSizeLargeBanner.size.height)
        let v = GAMBannerView(adSize: s)
        v.delegate = self
        return v
    }()
    
    lazy var closeButton: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "multiply.circle.fill"), for: .normal)
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 12), forImageIn: .normal)
        return b
    }()
    
    lazy var contentView: AdsContentView = {
       let v = AdsContentView()
        return v
    }()
    
    lazy var context: GoogleMobileAdsBnnnerContext = {
        return GoogleMobileAdsBnnnerContext()
    }()
    
    var defaultBannerSize: GoogleMobileAdsBnnnerSize = .GADAdSizeBanner
    
    lazy var bannerSize: GoogleMobileAdsBnnnerSize = {
       return defaultBannerSize
    }()
    
    var isShowCloseButton: Bool = true {
        didSet {
            closeButton.isHidden = !isShowCloseButton
        }
    }
    
    var bottomOffset: CGFloat = 0
    var topOffset: CGFloat = 0
    
    weak public var delegate: AdsControllerDelegate?
    
    private(set) weak var parentViewController: UIViewController?
    
    public var isValid: Bool {
        get {
            !context.adUnitID.isEmpty
        }
    }
    
    public override init() {
        super.init()
        setupUI()
    }
    
    private func setupUI() {
        
        contentView.innerView.addSubview(bannerView)
        bannerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(GADAdSizeBanner.size.width)
            make.height.equalTo(GADAdSizeBanner.size.height)
        }
        contentView.innerView.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalTo(bannerView.snp.right).offset(5)
            make.top.equalTo(bannerView.snp.top).offset(-8)
        }
        closeButton.addTarget(self, action: #selector(closeButtonBlock), for: .touchUpInside)
    }
    
    ///  AdsController
    
    public func getAdsContentView() -> UIView {
        return contentView
    }
    
    public func reloadAds() {
        bannerView.adUnitID = context.adUnitID
        bannerView.rootViewController = context.parentViewController
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "20988342a51a06d3baa3f3326e7f7956" ]
        bannerView.load(GAMRequest())
    }
    
    public func mute() {
        //Image banner have no media configuration
    }
    
    public func unmute() {
        //Image banner have no media configuration
    }
    
    public func resume() {
        //Image banner have no media configuration
    }
    
    public func pause() {
        //Image banner have no media configuration
    }
    
    public func destory() {
        //Image banner have no media configuration
    }
    
    ///
    public func setupGoogleMobileAds(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
        context.parentViewController = parentViewController
    }
    
    public func resetCurrentParentViewController(_ parentViewController: UIViewController) {
        setupGoogleMobileAds(parentViewController: parentViewController)
    }
    
    public func setAdUnitID(_ adUnitID: String) {
        context.adUnitID = adUnitID
    }
    
    public func setSize(_ size: GoogleMobileAdsBnnnerSize, topOffset: CGFloat = 0, bottomOffset: CGFloat = 0) {
        bannerSize = size
        self.bottomOffset = bottomOffset
        
        if bottomOffset != 0 {
            self.topOffset = 0
        } else {
            self.topOffset = topOffset
        }
        
        resizeBanner(size: bannerSize, topOffset: topOffset, bottomOffset: bottomOffset)
    }
    
    public func setBannerTopOffset(_ offset: CGFloat) {
        topOffset = offset
        bottomOffset = 0
        resizeBanner(size: bannerSize, topOffset: topOffset, bottomOffset: bottomOffset)
    }
    
    public func setBannerBottonOffset(_ offset: CGFloat) {
        bottomOffset = offset
        topOffset = 0
        resizeBanner(size: bannerSize, topOffset: topOffset, bottomOffset: bottomOffset)
    }
    
    private func resizeBanner(size: GoogleMobileAdsBnnnerSize, topOffset: CGFloat, bottomOffset: CGFloat) {
        var shouldSetTopOffset = false
        var shouldSetBottomOffset = false
        
        if topOffset != 0 {
            shouldSetTopOffset = true
        }
        
        if bottomOffset != 0 {
            shouldSetBottomOffset = true
        }
        
        
        bannerView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            
            if !shouldSetTopOffset && !shouldSetBottomOffset {
                make.centerY.equalToSuperview()
            } else if shouldSetBottomOffset {
                make.bottom.equalTo(bottomOffset)
            } else if shouldSetTopOffset {
                make.top.equalTo(topOffset)
            }
            
            make.width.equalTo(size.toSize().width)
            make.height.equalTo(size.toSize().height)
        }
        contentView.innerView.addSubview(closeButton)
        
        closeButton.snp.remakeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalTo(bannerView.snp.right).offset(5)
            make.top.equalTo(bannerView.snp.top).offset(-8)
        }
    }
    
    @objc func closeButtonBlock(_ sender: UIControl) {
        delegate?.adsViewShouldDisappear()
    }
    
    /// GADBannerViewDelegate
    
    public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("bannerViewDidReceiveAd")
        delegate?.adsViewShouldAppear()
      }

    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print(bannerView.bounds.size)
        print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
        delegate?.adsViewShouldDisappear()
    }

    public func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        print("bannerViewDidRecordImpression")
    }

    public func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillPresentScreen")
        delegate?.adsViewShouldAppear()
    }

    public func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewWillDIsmissScreen")
        delegate?.adsViewShouldDisappear()
    }

    public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("bannerViewDidDismissScreen")
    }
    
}
