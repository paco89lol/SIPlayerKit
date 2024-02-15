//
//  SIPlayerTheme.swift
//  SIPlayerKit
//
//  Created by Paco on 21/2/2023.
//

import Foundation

public class SIPlayerTheme {
  
    public static func mainTintColor() -> UIColor {
        return SIPlayerColor(rgb: 0xFFFFFF)
    }
    
    public static func progressBarTintColor() -> UIColor {
        return SIPlayerColor(rgb: 0x1989FA)
    }
    
    public static func mainTextColor() -> UIColor {
        return SIPlayerColor(rgb: 0xFFFFFF)
    }
    
}


class SIPlayerColor: UIColor {
    
    public convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }

    public convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            a: a
        )
    }
}
