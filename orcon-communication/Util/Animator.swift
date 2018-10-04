//
//  Animator.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/25.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//
import UIKit

class Animator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        // アニメーションの時間（duration）を返します。
        return 1.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        print(#function)
        // ここでアニメーションの具体的な内容を書きます。
        _ = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        _ = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: { () -> Void in
            // アニメーションの具体的な内容
        }) { (finished) -> Void in
            // 完了後の処理
            transitionContext.completeTransition(true)
        }
    }
}
