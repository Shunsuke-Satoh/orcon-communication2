//
//  DoctorCell.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/25.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class DoctorCell: UITableViewCell {
    @IBOutlet weak var clinicName: UILabel!
    @IBOutlet weak var topImg: UIImageView!
    @IBOutlet weak var iconImg: UIImageView!
    var userId: String!
    @IBOutlet weak var myView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
        
    }

    
}
