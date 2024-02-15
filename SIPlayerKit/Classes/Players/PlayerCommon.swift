//
//  playerCommon.swift
//  CustomPlayer
//
//  Created by Paco on 7/2/2023.
//

import Foundation

public protocol IPlayer: AnyObject {
    
    var delegate: IPlayerDelegate? { get set }
    var dataSource: IPlayerDataSource? { get set }
    
    var isSetSource: Bool { get }
    var mediaUrlString: String? { get }
    
    func prepareAndPlay() throws
    func prepare() throws
    func play()
    func pause()
    func end()
    func seek(second: Int64)
    func setSource(url: String?)
    func setMute(_ isMute: Bool)
    
}

public protocol IPlayerDelegate: AnyObject {
    
    func onPlayerEvent(_ player: IPlayer, playState: PlayerState)
    
    func player(onUpdateVideoCurrentTime second: Int64)
    func player(onUpdateVideoTotalTime second: Int64)
    func player(onUpdateVideoBufferedTime second: Int64)
    func player(onError error: Error)
}

public protocol IPlayerDataSource: AnyObject {
    
    func getPlayerContext() -> PlayerControllerContext
    func getPlayerContentView() -> PlayerContentView
}
