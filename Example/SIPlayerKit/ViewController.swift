//
//  ViewController.swift
//  SIPlayerKit
//
//  Created by paco.yeung on 02/14/2023.
//  Copyright (c) 2023 paco.yeung. All rights reserved.
//

import UIKit
import SIPlayerKit
import Combine

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var cancellables = Set<AnyCancellable>()
    
    public override var prefersStatusBarHidden: Bool {
        if PlayerFullScreen.currentVC.value != nil {
            return true
        }
        return false
    }
    
    lazy var tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.delegate = self
        t.dataSource = self
        t.register(MyTableViewCell.self, forCellReuseIdentifier: "MyTableViewCell")
        t.rowHeight = UIScreen.main.bounds.width * 9 / 16
        return t
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PlayerFullScreen.currentVC.receive(on: DispatchQueue.main).sink { [weak self] fullScreenVC in
            self?.setNeedsStatusBarAppearanceUpdate()
        }.store(in: &cancellables)
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyTableViewCell") as? MyTableViewCell else { return UITableViewCell()
        }
        cell.setData(viewController: self, url: "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8")
//        cell.setData(viewController: self, url: "http://sample.vodobox.net/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8")
//        cell.setData(viewController: self, url: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
//        cell.setData(viewController: self, url: "https://video.hkhl.hk/d01d7fd029f371eebfcc97c6360c0102/117b8ad3cb484f4abb2bda7aa9f467ef-80697fb9c3ffd11f0bdd20b0706287bf-ld.mp4")
//        cell.setData(viewController: self, url: "https://video.hkhl.hk/817e49d0c15d71ed8f2187c7371d0102/fa334949b2634650b892079b4aea4a71-369a0a00356180ff352e6cdb1b80530e-ld.mp4")
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
}

class MyTableViewCell: UITableViewCell {
    
    
    lazy var adsController: GoogleMediaAdsController = {
        return GoogleMediaAdsController()
    }()
    
    lazy var adsBannerController: GoogleMobileAdsBnnnerController = {
        return GoogleMobileAdsBnnnerController()
    }()
    
    lazy var playerPanelAdsBannerController: GoogleMobileAdsBnnnerController = {
        return GoogleMobileAdsBnnnerController()
    }()
    
    lazy var playerContorller: PlayerController = {
        let ac = PlayerController(player: /*VLCPlayerWrapper()*/ AliPlayerWrapper() /*AVPlayerWrapper()*/ /*AWSPlayerWrapper()*/ )
        ac.setAds(controller: adsController)
        ac.setAds(controller: adsBannerController)
        ac.setPlayerPanelAds(controller: playerPanelAdsBannerController)
        return ac
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    func setupUI() {
        let playerContentView = playerContorller.playerContentView
        contentView.addSubview(playerContentView)
        playerContentView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(viewController: UIViewController, url: String) {
        playerContorller.originalScreenParentView = contentView
        playerContorller.originalScreenVC = viewController
        
        playerContorller.setData(url, screenType: .horizontal, coverImageUrl: "https://picsum.photos/200/300", defaultImage: nil, title: "", duration: 0)
//        playerContorller.setData(url, screenType: .vertical, coverImageUrl: "https://picsum.photos/200/300", defaultImage: nil, title: "", duration: 0)
        adsController.setupGoogleMediaAds(parentViewController: viewController)
//        adsBannerController.setupGoogleMobileAds(parentViewController: viewController)
        playerPanelAdsBannerController.setupGoogleMobileAds(parentViewController: viewController)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [unowned self] in
            
            try? self.playerContorller.prepareAndPlay()
            
//            self.adsBannerController.setAdUnitID("/6499/example/banner")
//            self.adsBannerController.setSize(.GADAdSizeLargeBanner)
//            self.playerContorller.reloadAds()
            
            DispatchQueue.main.asyncAfter(deadline: .now()+4) { [unowned self] in
                self.playerPanelAdsBannerController.setAdUnitID("/6499/example/banner")
                self.playerPanelAdsBannerController.setSize(.GADAdSizeBanner)
                self.playerContorller.reloadPlayerPanelAds()
                
                self.adsController.setAdTagUrl("https://pubads.g.doubleclick.net/gampad/ads?sz=1024x576|640x360&iu=/64888526/DEV.STHL_iOS_recom_list/vod_ad&rdid=00000000-0000-0000-0000-000000000000&is_lat=0&description_url=https%3A%2F%2Fwww.stheadline.com%2F%E6%B8%AF%E8%81%9E%2F3191800%2F&idtype=idfa&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=&correlator=1674725569")
                self.playerContorller.reloadAds()
            }

        }
    }

}



