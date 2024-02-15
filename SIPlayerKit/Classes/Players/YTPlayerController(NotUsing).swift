//
//  YTPlayerController.swift
//  CustomPlayer
//
//  Created by Paco on 18/1/2023.
//

import Foundation

//class YTSource { }
//
//class YTUrlSource: YTSource {
//    var url: String
//
//    init(url: String) {
//        self.url = url
//    }
//}
//
//class YTVideoIdSource: YTSource {
//    var videoId: String
//
//    init(videoId: String) {
//        self.videoId = videoId
//    }
//}
//
//class YTPlayerController: PlayerController {
//
//    weak var delegate: PlayerControllerDelegate?
//
//    lazy var player: YTPlayerView = {
//        var p = YTPlayerView()
//        return p
//    }()
//
//    var playerContentView: UIView {
//        get { self.player }
//    }
//
//    var source: YTSource?
//
//    init() {}
//
//    public func setData(_ url: String) {
////        if url.contains("http") {
////            let s = YTUrlSource(url: url)
////            source = s
////        } else {
//            let s = YTVideoIdSource(videoId: url)
//            source = s
////        }
//
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
////            if let source = source as? YTUrlSource {
////                player.loadVideo(byURL: source.url, startSeconds: 0) // seen not work
////                break
////            }
//
//            if let source = source as? YTVideoIdSource {
//                player.load(withVideoId: source.videoId)
//                break
//            }
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
//        player.playVideo()
//    }
//
//    func pause() {
//        player.pauseVideo()
//    }
//
//    func end() {
//        player.stopVideo()
//    }
//
//}
