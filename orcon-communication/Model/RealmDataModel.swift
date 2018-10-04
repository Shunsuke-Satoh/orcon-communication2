//
//  ChatRoomModel.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/20.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import RealmSwift

class ChatRoomModel: Object {
    @objc dynamic var roomId = ""
    @objc dynamic var otherUser: UserModel?
    let messages = List<MessageModel>()
    @objc dynamic var lastDate: Date?
    
    override static func primaryKey() -> String? {
        return "roomId"
    }
}

class UserModel: Object {
    let chatRoom = LinkingObjects(fromType: ChatRoomModel.self, property:"otherUser")
    @objc dynamic var userId = ""
    @objc dynamic var userType = ""
    @objc dynamic var name = ""
    @objc dynamic var tel = ""
    @objc dynamic var email = ""
    @objc dynamic var clinicName = ""
    @objc dynamic var clinicAddress = ""
    @objc dynamic var topImgUpdate: Date?
    @objc dynamic var iconImgUpdate: Date?
    @objc dynamic var entryDate: Date?
    @objc dynamic var status = 0
    @objc dynamic var token = ""
    let chatRooms = List<String>()
    
    override static func primaryKey() -> String? {
        return "userId"
    }
}

class MessageModel: Object{
    let chatRoom = LinkingObjects(fromType: ChatRoomModel.self, property:"messages")
    @objc dynamic var messageType = ""
    @objc dynamic var contents = ""
    @objc dynamic var senderId = ""
    @objc dynamic var entryDate = Date()
    @objc dynamic var messageNum = 0
    @objc dynamic var messageId = ""
    @objc dynamic var read = false
    
    override static func primaryKey() -> String? {
        return "messageId"
    }
}

class RequestModel: Object{
    @objc dynamic var customerId = ""
    @objc dynamic var doctorId = ""
    @objc dynamic var requestConfirm = false
    @objc dynamic var requestDate: Date?
    @objc dynamic var requestConfirmDate: Date?
    
    override static func primaryKey() -> String? {
        return "customerId"
    }
    
    func copyModel() -> RequestModel {
        let mdl = RequestModel()
        mdl.customerId = customerId
        mdl.doctorId = doctorId
        mdl.requestConfirm = requestConfirm
        mdl.requestDate = requestDate
        mdl.requestConfirmDate = requestConfirmDate
        
        return mdl
    }
}

class CalKindModel: Object{
    @objc dynamic var doctorId = ""
    @objc dynamic var kindId = ""
    @objc dynamic var kindNum = 0
    
    @objc dynamic var color_r = CGFloat(0)
    @objc dynamic var color_g = CGFloat(0)
    @objc dynamic var color_b = CGFloat(0)
    @objc dynamic var allCloseFlg = false
    @objc dynamic var closeFlg = false
    let open = List<CalKindOpenCloseModel>() // kindId + "_" + open + "_" + num
    let close = List<CalKindOpenCloseModel>() // kindId + "_" + close + "_" + num
    
    override static func primaryKey() -> String? {
        return "kindId"
    }
    
    func getTitle()->String{
        if allCloseFlg {
            return "休診日"
        }
        return "診療日" + kindNum.description
    }
    
    func getAllTitle()->String{
        
        var kindDesc = getTitle()
        
        if allCloseFlg {
            return kindDesc
        }
        
        let kindSub1 = CommonUtils.hh_mm(open[0].StartHHmm) + "〜" + CommonUtils.hh_mm(open[0].EndHHmm)
        
        kindDesc += "\n" + kindSub1
        
        if closeFlg {
            let kindSub2 = CommonUtils.hh_mm(close[0].StartHHmm) + "〜" + CommonUtils.hh_mm(close[0].EndHHmm)
            kindDesc += "\n休診時間\n" + kindSub2
        } else {
            kindDesc += "\n\n\n"
        }
        
        return kindDesc
    }
}

class CalKindOpenCloseModel: Object{
    let calKindopen = LinkingObjects(fromType: CalKindModel.self, property:"open")
    let calKindclose = LinkingObjects(fromType: CalKindModel.self, property:"close")
    @objc dynamic var kindId_openclose_num = ""
    @objc dynamic var opencloseType = "open"
    @objc dynamic var num = 0
    @objc dynamic var StartHHmm = "09:00"
    @objc dynamic var EndHHmm = "17:00"
    
    override static func primaryKey() -> String? {
        return "kindId_openclose_num"
    }
}

class ScheduledDateModel: Object{
    @objc dynamic var id_yyyymmdd = ""
    @objc dynamic var doctorId = ""
    @objc dynamic var date = Date()
    @objc dynamic var kind: CalKindModel?
    @objc dynamic var kindId = ""
    
    override static func primaryKey() -> String? {
        return "id_yyyymmdd"
    }
    
}


