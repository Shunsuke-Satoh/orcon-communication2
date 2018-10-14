//
//  viewAsBtn.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/11.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class viewAsBtn: UIView {
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if touches.first?.location(in: self) != nil {
            
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundColor = .white
            }) { finished in
            }
        }
    }
}
