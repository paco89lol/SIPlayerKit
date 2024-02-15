//
//  Mute.swift
//  SIPlayerKit
//
//  Created by Paco on 21/2/2023.
//

import Foundation
import Combine
import AVFAudio

public class SIPlayerPreference {
    
    public static let sound: CurrentValueSubject<Bool, Never> = {
        return CurrentValueSubject(_sound)
    }()
    
    private static var _sound: Bool {
        get {
            UserDefaults.standard.bool(forKey: "PlayerSound")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "PlayerSound")
        }
    }
    
    public static func setConfig() {
        SIPlayerPreference.sound.send(false)
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    }
    
}
