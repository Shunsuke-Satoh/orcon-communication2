//
//  verticalLineV.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/11.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class verticalLineV: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override func draw(_ rect: CGRect) {
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
    }

}
