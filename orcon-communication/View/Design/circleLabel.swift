//
//  circleLabel.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/09.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class circleLabel: UILabel {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.width / 2
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
}
