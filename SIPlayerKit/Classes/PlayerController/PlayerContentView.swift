//
//  PlayerContentView.swift
//  CustomPlayer
//
//  Created by Paco on 7/2/2023.
//

import Foundation
import UIKit

public class PlayerContentView: UIView {
    
    lazy var videoView: UIView = {
        return UIView()
    }()
    
    public lazy var panelView: PlayerPanel = {
        let p = PlayerPanel()
        return p
    }()
    
    public lazy var coverView: PlayerCoverView = {
       let c = PlayerCoverView()
        return c
    }()
    
    lazy var adsView: UIView = {
        return UIView()
    }()
    
    public var isLive: Bool {
        get {
            return panelView.isLive
        }
        set {
            panelView.isLive = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(videoView)
        videoView.snp.makeConstraints { make in
            make.left.top.bottom.right.equalToSuperview()
        }
        
        addSubview(panelView)
        panelView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        addSubview(coverView)
        coverView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        addSubview(adsView)
        adsView.snp.makeConstraints { make in
            make.left.top.bottom.right.equalToSuperview()
        }
        
        adsView.isHidden = true
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    public func setAdsSubView(_ view: UIView) {
        
        adsView.subviews.forEach { subView in
            subView.removeFromSuperview()
        }
        
        adsView.addSubview(view)
        view.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
}
