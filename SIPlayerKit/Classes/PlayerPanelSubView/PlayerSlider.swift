//
//  PlayerSlider.swift
//  CustomPlayer
//
//  Created by Paco on 27/1/2023.
//

import Foundation
import UIKit

public protocol PlayerSliderInput {
    func playerSliderSet(bufferedValue value: Float)
    func playerSliderSet(currentPlayValue value: Float)
}


public protocol PlayerSliderDelegate: AnyObject {
    func playerSlider(onPanValueChange value: Float)
    func playerSlider(onTouchUp value: Float)
    func playerSlider(onTouchDown value: Float)
}

class PlayerSlider: UISlider, PlayerSliderInput {
    
    public struct Configuration {
        var minimumTrackTintColor: UIColor
        var maximumTrackTintColor: UIColor
        var progressTintColor: UIColor
        var backgroundColor: UIColor
        var thumbImage: UIImage?
        
        public static let `default`: Configuration = Configuration(minimumTrackTintColor: UIColor(red: 255.0/255.0, green: 105.0/255.0, blue: 180.0/255.0, alpha: 1), maximumTrackTintColor: UIColor.gray.withAlphaComponent(0.5), progressTintColor: UIColor.lightGray.withAlphaComponent(0.8), backgroundColor: UIColor.clear, thumbImage: nil)
    }
    
    var configuration: PlayerSlider.Configuration?
    
    lazy var progressView: UIProgressView = {
        var p = UIProgressView()
        p.isUserInteractionEnabled = false
        p.backgroundColor = .clear
        p.progressTintColor = PlayerSlider.Configuration.default.progressTintColor
        p.trackTintColor = PlayerSlider.Configuration.default.maximumTrackTintColor
        return p
    }()
    
    var lastSliderValue: Float?
    var debounceTimer: Timer?
    
    weak var delegate: PlayerSliderDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.left.equalTo(1.5)
            make.right.equalTo(0)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(5)
        }
        sendSubviewToBack(progressView)
        
//        self.clipsToBounds = true
        
        self.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        
        addTarget(self, action: #selector(handlePlayerSliderValueChange(_:)), for: .valueChanged)
        addTarget(self, action: #selector(handlePlayerSliderOnTouchUp(_:)), for: .touchUpInside)
        addTarget(self, action: #selector(handlePlayerSliderOnTouchUp(_:)), for: .touchUpOutside)
        addTarget(self, action: #selector(handlePlayerSliderOnTouchDown(_:)), for: .touchDown)
        
        isUserInteractionEnabled = true
        minimumTrackTintColor = PlayerSlider.Configuration.default.minimumTrackTintColor
        maximumTrackTintColor = .clear
        tintColor = PlayerSlider.Configuration.default.minimumTrackTintColor
    }
    
    public func setView(with configuration: PlayerSlider.Configuration) {
        self.configuration = configuration
        minimumTrackTintColor = self.configuration?.minimumTrackTintColor
        tintColor = self.configuration?.minimumTrackTintColor
        progressView.progressTintColor = self.configuration?.progressTintColor
        progressView.trackTintColor = self.configuration?.maximumTrackTintColor
        self.backgroundColor = self.configuration?.backgroundColor
        setThumbImage(self.configuration?.thumbImage, for: .normal)
        setThumbImage(self.configuration?.thumbImage, for: .highlighted)
    }
    
    @objc func handlePlayerSliderValueChange(_ sender: UISlider) {
        /* debounce is optional */
//        debounce(seconds: 0.1, function: { [unowned self] in
            let _value = Float(Int64(sender.value * 100)) / 100
            print("Slider value: \(sender.value), rounded value: \(_value)")
            repeat {
                if let lastSliderValue = self.lastSliderValue, lastSliderValue == _value {
                    break
                }
                self.delegate?.playerSlider(onPanValueChange: _value)
            } while false
            self.lastSliderValue = _value
//        })
    }
    
    @objc func handlePlayerSliderOnTouchUp(_ sender: UISlider) {
        lastSliderValue = nil
        delegate?.playerSlider(onTouchUp: sender.value)
    }
    
    @objc func handlePlayerSliderOnTouchDown(_ sender: UISlider) {
        delegate?.playerSlider(onTouchDown: sender.value)
    }
    
    private func debounce(seconds: TimeInterval, function: @escaping () -> Swift.Void ) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            function()
        })
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.size.height = 6
        return newBounds
    }
    
    // Interface: - PlayerSliderInput
    
    func playerSliderSet(bufferedValue value: Float) {
        progressView.setProgress(value, animated: false)
    }
    
    func playerSliderSet(currentPlayValue value: Float) {
        self.value = value
    }
}

extension UIImage {
    
    func scale(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
