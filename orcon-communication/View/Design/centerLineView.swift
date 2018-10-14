//
//  centerLineView.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/09.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class centerLineView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func draw(_ rect: CGRect) {
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: self.frame.width / 2, y: 0))
        path.addLine(to: CGPoint(x: self.frame.width / 2, y: self.frame.height))
        path.lineWidth = 2.0
        UIColor(red: 153/255 , green: 153/255, blue: 153/255, alpha: 1).setStroke()
        path.stroke()
    }

}
