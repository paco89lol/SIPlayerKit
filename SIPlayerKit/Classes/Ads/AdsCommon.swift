//
//  AdsCommon.swift
//  CustomPlayer
//
//  Created by Paco on 7/2/2023.
//

import Foundation
import UIKit

public protocol IAdsController: AnyObject {
    
    var delegate: AdsControllerDelegate? { get set }
    var isValid: Bool { get }
    func getAdsContentView() -> UIView
    func reloadAds()
    func resetCurrentParentViewController(_ parentViewController: UIViewController)
    
    
    /// Mdeia video ads only
    func mute()
    func unmute()
    func resume()
    func pause()
    func destory()
}

public protocol AdsControllerDelegate: AnyObject {
    
    func adsViewShouldDisappear()
    func adsViewShouldAppear()
    
    func adsController(_ adsController: IAdsController, muteDidPressed: UIControl)
    func adsController(_ adsController: IAdsController, unmuteDidPressed: UIControl)
}

protocol AdsContentViewDelegate: AnyObject {
    
    func adsContentView(_ adsContentView: AdsContentView, muteDidPressed: UIControl)
    func adsContentView(_ adsContentView: AdsContentView, unmuteDidPressed: UIControl)
    func adsContentView(_ adsController: AdsContentView, resumeDidPressed: UIControl)
}

public class AdsContentView: UIView {
    
    lazy var muteOrUnmuteButtons: UIView = {
        let v = UIView()
        return v
    }()
    
    lazy var muteButton: UIButton = {
        let b = UIButton()
        b.setImage(SIPlayerAssets.muteImage?.scale(with: CGSize(width: 20, height: 20))?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        b.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        b.layer.masksToBounds = true
        b.layer.cornerRadius = 30/2
        return b
    }()
    
    lazy var unmuteButton: UIButton = {
        let b = UIButton()
        b.setImage(SIPlayerAssets.volumeImage?.scale(with: CGSize(width: 20, height: 20))?.withRenderingMode(.alwaysTemplate), for: .normal)
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 10), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        b.layer.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        b.layer.masksToBounds = true
        b.layer.cornerRadius = 30/2
        return b
    }()
    
    var resumeButton: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "play.fill"), for: .normal)
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 30), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        return b
    }()
    
    weak var delegate: AdsContentViewDelegate?
    
    // incase reference retain cycle
    lazy var innerView: UIView = {
       return UIView()
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(innerView)
        innerView.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        addSubview(resumeButton)
        resumeButton.snp.makeConstraints { [weak self] make in
            guard let self = self else { return }
            make.width.height.equalTo(45)
            make.centerX.centerY.equalToSuperview()
        }
        
        addSubview(muteOrUnmuteButtons)
        muteOrUnmuteButtons.snp.makeConstraints { [weak self] make in
            guard let self = self else { return }
            make.height.width.equalTo(30)
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(self.snp.left).offset(10)
        }
        
        muteOrUnmuteButtons.addSubview(unmuteButton)
        unmuteButton.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        muteOrUnmuteButtons.addSubview(muteButton)
        muteButton.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        
        muteOrUnmuteButtons.isHidden = true
        resumeButton.isHidden = true
        
        if SIPlayerPreference.sound.value {
            muteButton.isHidden = true
            unmuteButton.isHidden = false
        } else {
            muteButton.isHidden = false
            unmuteButton.isHidden = true
        }
        
        muteButton.addTarget(self, action: #selector(muteButtonBlock), for: .touchUpInside)
        unmuteButton.addTarget(self, action: #selector(unmuteButtonBlock), for: .touchUpInside)
        resumeButton.addTarget(self, action: #selector(resumeBlock), for: .touchUpInside)
    }
    
    @objc func resumeBlock(_ sender: UIControl) {
        resumeButton.isHidden = true
        delegate?.adsContentView(self, resumeDidPressed: sender)
    }
    
    @objc func muteButtonBlock(_ sender: UIControl) {
        muteButton.isHidden = true
        unmuteButton.isHidden = false
        delegate?.adsContentView(self, muteDidPressed: sender)
    }
    
    @objc func unmuteButtonBlock(_ sender: UIControl) {
        muteButton.isHidden = false
        unmuteButton.isHidden = true
        delegate?.adsContentView(self, unmuteDidPressed: sender)
    }
}



