//
//  imageButton.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/09.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class imageButton: UIButton {
    private let tapEffectView = UIView(frame: CGRect(x: 0, y:0, width: 1, height: 1))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.imageView?.contentMode = .scaleToFill
        self.contentHorizontalAlignment = .fill
        self.contentVerticalAlignment = .fill
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let point = touches.first?.location(in: self) {
            tapEffectView.frame.origin = point
            
            tapEffectView.alpha = 0.3
            tapEffectView.isHidden = false
            tapEffectView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            UIView.animate(withDuration: 0.5, animations: {
                self.tapEffectView.alpha = 0
                self.tapEffectView.transform = CGAffineTransform(scaleX: 100.0, y: 100.0)
            }) { finished in
                self.tapEffectView.isHidden = true
                self.tapEffectView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.path = UIBezierPath(ovalIn: tapEffectView.bounds).cgPath
        tapEffectView.layer.addSublayer(shapeLayer)
        tapEffectView.isHidden = true
        
        addSubview(tapEffectView)
    }
}
