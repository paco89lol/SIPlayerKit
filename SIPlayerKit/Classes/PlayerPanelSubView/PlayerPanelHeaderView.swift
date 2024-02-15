//
//  PlayerPanelHeaderView.swift
//  CustomPlayer
//
//  Created by Paco on 27/1/2023.
//

import Foundation
import UIKit
import SnapKit

protocol PlayerPanelHeaderViewDelegate: AnyObject {
    
    func playerPanelHeaderView(_ view: PlayerPanelHeaderView, backDidPressed button: UIControl)
}

public class PlayerPanelHeaderView: UIView {
    
    lazy var backButton: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        return b
    }()
    
    lazy var titleView: UILabel = {
        let v = UILabel()
        v.textColor = .white
        v.font = v.font.withSize(13)
        v.text = "title title title title title title title title title"
        v.textColor = SIPlayerTheme.mainTextColor()
        return v
    }()
    
    public lazy var shareButton: UIButton = {
        let b = UIButton()
        b.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        b.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        b.tintColor = SIPlayerTheme.mainTintColor()
        return b
    }()
    
    /* Hot fix - space issue */
    lazy var box: UIView = {
       return UIView()
    }()
    /* ... */
    
    weak var delegate: PlayerPanelHeaderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        
        let stackView = UIStackView(arrangedSubviews: [backButton, box, titleView])
        
        stackView.axis = .horizontal
        stackView.spacing = 1
        stackView.alignment = .center
        stackView.distribution = .fill
        
        addSubview(shareButton)
        shareButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview()
            make.height.width.equalTo(30)
        }
        
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(shareButton.snp.left)
        }
        
        backButton.snp.makeConstraints { make in
            make.height.width.equalTo(30)
            make.centerY.equalToSuperview()
            make.left.equalTo(self.snp.left).offset(10)
            make.right.equalTo(titleView.snp.left)
        }
        
        box.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.width.equalTo(15)
            make.centerY.equalToSuperview()
            make.left.equalTo(backButton.snp.right)
            make.right.equalTo(titleView.snp.left)
        }
        
        titleView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(box.snp.right)
            make.right.equalTo(shareButton.snp.left)
            make.height.equalTo(30)
        }
        
//        shareButton.snp.makeConstraints { make in
//            make.height.width.equalTo(30)
//            make.left.equalTo(titleView.snp.right)
//            make.centerY.equalToSuperview()
//            make.right.equalTo(self.snp.right).offset(-10)
//        }
        
        backButton.addTarget(self, action: #selector(backButtonBlock), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonBlock), for: .touchUpInside)
        
        backButton.isHidden = true
        shareButton.isHidden = true
    }
    
    @objc func backButtonBlock(_ sender: UIControl) {
        delegate?.playerPanelHeaderView(self, backDidPressed: sender)
    }
    
    @objc func shareButtonBlock(_ sender: UIControl) {
        delegate?.playerPanelHeaderView(self, backDidPressed: sender)
    }
    
}
