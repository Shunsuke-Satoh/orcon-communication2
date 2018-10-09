//
//  TableViewCell.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/30.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class ChatReserveCell: UITableViewCell {

    @IBOutlet weak var amBtn: UIButton!
    @IBOutlet weak var pmBtn: UIButton!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    
    var date:Date!
    var selectedColor = UIColor(red: 0/255
    , green:140/255, blue: 255/255, alpha: 1)
    var nonSelectedColor = UIColor(red: 200/255
    , green:200/255, blue: 200/255, alpha: 1)
    
    var indexPath:IndexPath!
    
    var delegate:ChatReserveCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        amBtn.layer.cornerRadius = 10
        amBtn.layer.borderColor = selectedColor.cgColor
        amBtn.layer.borderWidth = 3
        pmBtn.layer.cornerRadius = 10
        pmBtn.layer.borderColor = selectedColor.cgColor
        pmBtn.layer.borderWidth = 3
        
        setColors()
    }
    
    @IBAction func tapAM(_ sender: UIButton) {
        amBtn.isSelected = !amBtn.isSelected
        setColorAM()
        delegate?.tapAM(amBtn.isSelected,indexPath)
    }
    
    @IBAction func tapPM(_ sender: UIButton) {
        pmBtn.isSelected = !pmBtn.isSelected
        setColorPM()
        delegate?.tapPM(pmBtn.isSelected,indexPath)
        
    }
    @IBAction func tapMinus(_ sender: UIButton) {
        delegate?.minus(indexPath)
    }
    
    func setColors(){
        setColorAM()
        setColorPM()
    }
    
    func setColorAM(){
        if amBtn.isSelected {
            amBtn.backgroundColor = selectedColor
        } else {
            amBtn.backgroundColor = nonSelectedColor
        }
    }
    
    func setColorPM(){
        if pmBtn.isSelected {
            pmBtn.backgroundColor = selectedColor
        } else {
            pmBtn.backgroundColor = nonSelectedColor
        }
    }
    
}

protocol ChatReserveCellDelegate {
    func minus(_ indexPath:IndexPath)
    func tapAM(_ isSelected:Bool, _ indexPath:IndexPath)
    func tapPM(_ isSelected:Bool, _ indexPath:IndexPath)
}
