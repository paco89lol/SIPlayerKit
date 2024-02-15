//
//  PlayerPanelFooterView.swift
//  CustomPlayer
//
//  Created by Paco on 27/1/2023.
//

import Foundation
import UIKit
import AVKit

class PlayerPanelFooterView: UIView {
    
    lazy var playerVideoBar: PlayerVideoBar = {
        let pvb = PlayerVideoBar()
        return pvb
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addGestureRecognizer(UITapGestureRecognizer()) 
        addSubview(playerVideoBar)
        playerVideoBar.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
    }
    
}
