//
//  File.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/20.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import Foundation
import UIKit


struct ChatRoomInfo {
    var roomId:String = "" // 部屋ID
    var uid:String = "" // 相手のユーザID
    var name:String = "" // 相手の名前
    var mockMessages:[MockMessage] = []
    var iconPath:String = ""
    var iconImg:UIImage = UIImage() // 相手のアイコン画像
}
