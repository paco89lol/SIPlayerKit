////
////  WebKitPlayerController.swift
////  CustomPlayer
////
////  Created by Paco on 18/1/2023.
////
//
//import Foundation
//import UIKit
//import WebKit
//
//
//
//class _WebKitPlayerContentView: UIView {
//    
//    weak var webView: WKWebView?
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        webView?.frame = self.bounds
//    }
//}
//
//class WebKitUrlSource {
//    
//    var url: String = ""
//    var embedHTML: String = ""
//    
//}
//
//class WebKitPlayerController: PlayerController {
//
//    weak var delegate: PlayerControllerDelegate?
//    
//    lazy var playerContentView: UIView = {
//        let w = WKWebView()
//        source?.embedHTML = "<!DOCTYPE html><head><style type=\"text/css\">body {background-color: transparent;color: black;}</style><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes\"/></head><body style=\"margin:0\"><div><iframe src=\"https://player.vimeo.com/video/139785390?autoplay=1&amp;title=1&amp;byline=1&amp;portrait=0\" width=\"640\" height=\"360\" frameborder=\"0\" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></div></body></html>"
//        let url = URL(string: "https://")!
//        w.contentMode = UIView.ContentMode.scaleAspectFit
//        return w
//    }()
//    
//    private var webView: WKWebView {
//        get {
//            return playerContentView as! WKWebView
//        }
//    }
//    
//    var source: WebKitUrlSource?
//    
//    init() {
//        source = WebKitUrlSource()
//    }
//    
//    public func setData(_ url: String) {
//        let s = WebKitUrlSource()
//        source = s
//    }
//    
//    func prepareAndPlay() throws {
//        try prepare()
//        play()
//    }
//    
//    func prepare() throws {
//        var isError = false
//        // set url to player
//        guard let source = source else { return }
//        
//        repeat {
//            webView.loadHTMLString(source.embedHTML, baseURL: URL(string: "https://")!)
//            break
//            isError = true
//        } while false
//        
//        guard !isError else {
//            return
//        }
//        
//    }
//    
//    func play() {
////        player.play()
//    }
//    
//    func pause() {
////        player.pause()
//    }
//    
//    func end() {
////        player.replaceCurrentItem(with: nil)
//    }
//    
//}
//
