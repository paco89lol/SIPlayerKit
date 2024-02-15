//
//  SIPlayerAssets.swift
//  SIPlayerKit
//
//  Created by Paco on 3/3/2023.
//

import Foundation
import UIKit

class SIPlayerAssets {
    
    static var bundleNameWithExtension: String = "SIPlayerKitResource.bundle"
    
    static var bundle: Bundle? {
        let bundle = Bundle(for: SIPlayerAssets.self)
        guard let resource = bundle.resourcePath else {
          return nil
        }
        
        guard let resourceBundle = Bundle(path: resource + "/\(bundleNameWithExtension)") else {
            return nil
        }
        
        return resourceBundle
    }
    
    static var fullScreenImage: UIImage? {
        return UIImage(named: "full-screen", in: bundle, with: nil)
    }
    
    static var exitFullScreenImage: UIImage? {
        return UIImage(named: "exit-full-screen", in: bundle, with: nil)
    }
    
    static var muteImage: UIImage? {
        return UIImage(named: "mute", in: bundle, with: nil)
    }
    
    static var volumeImage: UIImage? {
        return UIImage(named: "volume", in: bundle, with: nil)
    }
    
    static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: bundle, with: nil)
    }
}
