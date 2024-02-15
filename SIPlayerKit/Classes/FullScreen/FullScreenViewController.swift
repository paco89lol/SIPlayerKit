//
//  FullScreenViewController.swift
//  CustomPlayer
//
//  Created by Paco on 30/1/2023.
//

import Foundation
import UIKit
import Combine

public class PlayerFullScreen {
    
    public static var currentVC: CurrentValueSubject<FullScreenViewController?, Never> = CurrentValueSubject(nil)
    
    public static func dismissIfPresented() {
        currentVC.value?.playerController?.backFromFullScreen()
    }
    
    public static func dismissAndPauseIfPresented() {
        currentVC.value?.playerController?.pause()
        dismissIfPresented()
    }
}

extension FullScreenViewController {
    
    enum ScreenState {
        case portrait
        case upsideDown
        case landscapeLeft
        case landscapeRight
    }
}

public class FullScreenViewController: UIViewController {
    
    weak var playerController: PlayerController?
    
    var cancellable = Set<AnyCancellable>()
    
    // observe Device Motion
    lazy var deviceOrientationManager: DeviceOrientationManager = {
       return DeviceOrientationManager()
    }()
    
    var currentScreenState: UIDeviceOrientation {
        get {
            return deviceOrientationManager.deviceOrientation.value
        }
    }
    
    var lastScreenState: UIDeviceOrientation?
    
    // if false, change orientation manually by device motion
    // if true, change orientation automatically by ios system (development setting)
    var isSystemOrientationEnabled: Bool = true
    
    // hide statusBar
//    public override var prefersStatusBarHidden: Bool {
//        return true
//    }
    
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .portrait
//    }
    
    var videoSourceScreenType: VideoSourceScreenType? {
        get {
            return playerController?.playerContext.videoSourceScreenType
        }
    }
    
    deinit {
        deviceOrientationManager.stopObserveDeviceMotion()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let playerContentView = playerController?.playerContentView else { return }
//        playerController.viewController = self // Important: require to set back to original one when back to original screen
        view.backgroundColor = .black
        view.addSubview(playerContentView)
        
        var topOffset = 0
        if UIScreen.main.bounds.height <= 700 {
            topOffset = 0
        } else {
            topOffset = 44
        }
        
        var bottomOffset = 0
        if UIScreen.main.bounds.height <= 700 {
            bottomOffset = 0
        } else {
            bottomOffset = -30
        }
        
        playerContentView.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(topOffset)
            make.bottom.equalToSuperview().offset(bottomOffset)
        }
        
        deviceOrientationManager.deviceOrientation.receive(on: DispatchQueue.main).sink { [weak self] deviceOrientation in
            guard let self = self else { return }
            defer {
                self.lastScreenState = deviceOrientation
            }
            
            guard self.isSystemOrientationEnabled != true else {
                return
            }

            if self.lastScreenState == nil {
                switchToOrientation(deviceOrientation)
                return
            }

            if let lastScreenState = self.lastScreenState, lastScreenState != deviceOrientation {
                switchToOrientation(deviceOrientation)
                return
            }
        }.store(in: &cancellable)
        
        deviceOrientationManager.startObserveDeviceMotion()
        
    }
    
    private func expectedAnimateDuration() -> TimeInterval {
        return 0.25
    }
    
    func switchToOrientation(_ orientation: UIDeviceOrientation) {
        switch orientation {
        case .unknown:
            break
        case .portrait:
            moveToPortrait()
        case .portraitUpsideDown:
            moveToUpsideDown()
        case .landscapeLeft:
            moveToLandscapeLeft()
        case .landscapeRight:
            moveToLandscapeRight()
        case .faceUp:
            break
        case .faceDown:
            break
        @unknown default:
            break
        }
    }
    
    func moveToPortrait() {
        guard let playerContentView = playerController?.playerContentView else { return }
        
        UIView.animate(withDuration: expectedAnimateDuration()) {
            playerContentView.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview().offset(44)
                make.bottom.equalToSuperview().offset(-30)
            }
            
            playerContentView.layer.setAffineTransform(.identity)
            playerContentView.setNeedsLayout()
        }
    }
    
    func moveToUpsideDown() {
        guard let playerContentView = playerController?.playerContentView else { return }
        
        UIView.animate(withDuration: expectedAnimateDuration()) {
            playerContentView.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview().offset(44)
                make.bottom.equalToSuperview().offset(-30)
            }
            
            let affineTransform = CGAffineTransform(rotationAngle: (CGFloat.pi * 180.0 / 180.0))
            playerContentView.layer.setAffineTransform(affineTransform)
            playerContentView.setNeedsLayout()
        }
    }
    
    func moveToLandscapeLeft() {
        guard let playerContentView = playerController?.playerContentView else { return }
        
        UIView.animate(withDuration: expectedAnimateDuration()) { [weak self] in
            guard let self = self else { return }
            playerContentView.snp.remakeConstraints { [weak self] make in
                guard let self = self else { return }
                make.centerY.centerX.equalToSuperview()
                var offset = 0
                if UIScreen.main.bounds.height <= 700 {
                    offset = 0//-35
                } else {
                    offset = -130
                }
                make.width.equalTo(self.view.snp.height).offset(offset)
                make.height.equalTo(self.view.snp.width)
            }
            
            let affineTransform = CGAffineTransform(rotationAngle: (CGFloat.pi * 90.0 / 180.0))
            playerContentView.layer.setAffineTransform(affineTransform)
            playerContentView.setNeedsLayout()
        }
    }
    
    func moveToLandscapeRight() {
        guard let playerContentView = playerController?.playerContentView else { return }
        
        UIView.animate(withDuration: expectedAnimateDuration()) { [weak self] in
            guard let self = self else { return }
            playerContentView.snp.remakeConstraints { [weak self] make in
                guard let self = self else { return }
                make.centerY.centerX.equalToSuperview()
                var offset = 0
                if UIScreen.main.bounds.height <= 700 {
                    offset = -35
                } else {
                    offset = -130
                }
                make.width.equalTo(self.view.snp.height).offset(offset)
                make.height.equalTo(self.view.snp.width)
            }
            
            let affineTransform = CGAffineTransform(rotationAngle: -(CGFloat.pi * 90.0 / 180.0))
            playerContentView.layer.setAffineTransform(affineTransform)
            playerContentView.setNeedsLayout()
        }
    }
    
}
