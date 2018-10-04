//
//  ChatBarCell.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/24.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class ChatBarCell: UITableViewCell {
    @IBOutlet weak var midokuNum: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var detail: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
