//
//  FullScreenTransitionManager.swift
//  CustomPlayer
//
//  Created by Paco on 1/2/2023.
//

import Foundation
import UIKit

class FullScreenTransitionManager: NSObject, UIViewControllerTransitioningDelegate {
    weak var anchorView: UIView?
    
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        return FullScreenPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        FullScreenAnimationController(animationType: .present, anchorView: anchorView)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        FullScreenAnimationController(animationType: .dismiss, anchorView: anchorView)
    }
}
