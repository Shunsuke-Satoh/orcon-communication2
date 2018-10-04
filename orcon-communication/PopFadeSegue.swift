//
//  PopFadeSegue.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/25.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class PopFadeSegue: UIStoryboardSegue {
    
    override func perform() {
        UIView.transition(
            with: (source.navigationController?.view)!,
            duration: 0.5,
            options: .transitionCrossDissolve,
            animations: {
                () -> Void in
                self.source.navigationController?.popViewController(animated: false)
        },
            completion: nil)
    }
    
}
