//
//  Constant.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/19.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

final class Constant {
    static let userType = "userType"
    static let userTypeDoctor = "doctor"
    static let userTypeCustomer = "customer"
    static let uerId = "userId"
    static let password = "password"
    static let clinicName = "clinicName"
    static let topImgName = "top.jpg"
    static let iconImgName = "icon.jpg"
    static let statusRequest = 0
    static let statusTreat = 1
    static let statusComp = 2
    static let token = "token"
    
    
    enum status: String {
        case statusRequest = "リクエスト中"
        case statusTreat = "治療中"
        case statusComp = "治療完了"
    }
    
    static let msgTypeText = "text"
    static let msgTypeImage = "image"
    static let baseDateFormat = "YYYY/MM/dd-HH:mm:ss"
    static let dateFormatYYYYMMdd = "YYYYMMdd"
    
    static let storageUserPath = "User"
    static let storageChatPath = "Chat"
    static let storageImgModeTOP = 1
    static let storageImgModeICON = 2
    
    
}
