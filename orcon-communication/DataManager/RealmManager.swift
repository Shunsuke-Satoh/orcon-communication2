//
//  RealmManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/21.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import RealmSwift

class RealmManager {
    static var own: RealmManager?
    static var config = Realm.Configuration(schemaVersion: 14)
    
    var userDM: UserDefaultManager?
    static let INSERT = 0
    static let UPDATE = 1
    
    init(){
        userDM = UserDefaultManager()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    
    static func getInstance() -> RealmManager {
        if own == nil {
            own = RealmManager()
        }
        return own!
    }
    
    // roomIdを元にチャットルームの相手ユーザ情報を取得する
    func getUserModelByRoomId(roomId:String) -> UserModel? {
        var ret :UserModel?
        
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            ret = realm.objects(ChatRoomModel.self).filter("roomId == '" + roomId + "'").first?.otherUser
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    
    
    // userIdを元にユーザ情報を取得する
    func getUserModelByUserId(userId:String) -> UserModel? {
        var ret :UserModel?
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            ret = realm.objects(UserModel.self).filter("userId == '" + userId + "'").first
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    // 自分以外のユーザ情報を全て取得する
    func getUserModelsExceptOwn() -> [UserModel] {
        var ret :[UserModel] = []
        
        do {
            let ownId = UserDefaultManager().getOwnUserId()
            let realm = try Realm(configuration:RealmManager.config)
            let mdls = realm.objects(UserModel.self)
            for mdl in mdls {
                if mdl.userId != ownId {
                    ret.append(mdl)
                }
            }
            
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    // ユーザ情報を保存する
    func updateUser(_ newMdl:UserModel) -> Void{
        do {
            let realm = try Realm(configuration:RealmManager.config)
            
            try! realm.write {
                realm.add(newMdl, update:true)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func insertUpdateUser(userId:String, userType:String, name:String, hira:String, tel:String, email:String,  clinicName:String, clinicAddress:String, rooms:[String], requestDoctorId:String, entryDate:Date, status:Int, deleteDate:Date?, purchaseLimitDate:Date?) {
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let userModel = UserModel()
            userModel.userId = userId
            userModel.userType = userType
            userModel.name = name
            userModel.hira = hira
            userModel.tel = tel
            userModel.email = email
            userModel.clinicName = clinicName
            userModel.clinicAddress = clinicAddress
            userModel.topImgUpdate = Date()
            userModel.iconImgUpdate = Date()
            userModel.entryDate = entryDate
            userModel.status = status
            userModel.requestDoctorId = requestDoctorId
            userModel.deleteDate = deleteDate
            userModel.purchaseLimitDate = purchaseLimitDate
            
            for room in rooms {
                userModel.chatRooms.append(room)
            }
            
            try! realm.write {
                realm.add(userModel, update:true)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func insertUserTemp(_ userId:String) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let userModel = UserModel()
            userModel.userId = userId
            
            try! realm.write {
                realm.add(userModel)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func deleteUserModel(_ userId:String) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            if let ret = getUserModelByUserId(userId: userId) {
                try! realm.write {
                    // realm削除
                    realm.delete(ret)
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func getChatRoomModels() -> Results<ChatRoomModel>?{
        var results:Results<ChatRoomModel>?
        do {
            let realm = try Realm(configuration:RealmManager.config)
            
            let rooms = realm.objects(ChatRoomModel.self)
            for room in rooms {
                if let last = getMessagesByRoomId(roomId: room.roomId).last{
                    try? realm.write {
                        room.lastDate = last.entryDate
                    }
                }
            }
            
            results = realm.objects(ChatRoomModel.self).sorted(byKeyPath: "lastDate", ascending: false)
            
            
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return results
        
    }
    
    // roomIdを元にチャットルーム情報を取得する
    func getChatRoomModelByRoomId(roomId:String) -> ChatRoomModel? {
        var ret :ChatRoomModel?
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            ret = realm.objects(ChatRoomModel.self).filter("roomId == '" + roomId + "'").first
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    func insertChatRoom(roomId:String, userId:String) -> Void {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let chatRoomModel = ChatRoomModel()
            chatRoomModel.roomId = roomId
            let user = getUserModelByUserId(userId: userId)
            chatRoomModel.otherUser = user
            
            try! realm.write {
                realm.add(chatRoomModel, update:true)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func insertUpdateChatRoom(roomId:String, userId:String) -> ChatRoomModel {
        var mdl = getChatRoomModelByRoomId(roomId: roomId)
        do {
            let realm = try Realm(configuration:RealmManager.config)
            // 無かったら新規作成
            if mdl == nil {
                mdl = ChatRoomModel()
                mdl!.roomId = roomId
            }
            
            try! realm.write {
                realm.add(mdl!, update:true)
                let user = getUserModelByUserId(userId: userId)
                mdl!.otherUser = user
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return mdl!
    }
    
    // ユーザ情報を保存する
    func insertUpdateChatRoom(_ newMdl:ChatRoomModel) -> Void{
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let oldMdl = getChatRoomModelByRoomId(roomId: newMdl.roomId)!
            try! realm.write {
                if oldMdl.otherUser == nil {
                    oldMdl.otherUser = newMdl.otherUser
                }
                oldMdl.lastDate = newMdl.lastDate
                for msg in newMdl.messages {
                    var flag = false
                    for msgold in oldMdl.messages {
                        if msg.messageId == msgold.messageId {
                            flag = true
                        }
                    }
                    if flag {
                        continue
                    }
                    oldMdl.messages.append(msg)
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func getMessagesAllNoRead() -> [MessageModel] {
        var ret :[MessageModel] = []
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let results = realm.objects(MessageModel.self).filter("read  == false")
            
            var it = results.makeIterator()
            while let msgModel = it.next(){
                ret.append(msgModel)
                
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    // roomIdを元にメッセージを取得する（挿入順でソート)
    func getMessagesByRoomId(roomId:String) -> [MessageModel] {
        var ret :[MessageModel] = []
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let results = realm.objects(MessageModel.self).filter("messageId BEGINSWITH '" + roomId + "_'").sorted(byKeyPath:"entryDate", ascending: true)
            
            var it = results.makeIterator()
            while let msgModel = it.next(){
                ret.append(msgModel)
                
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    // messageIdを元にメッセージを取得する（挿入順でソート)
    func getMessage(msgId:String) -> MessageModel? {
        var ret :MessageModel?
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            ret = realm.objects(MessageModel.self).filter("messageId = '" + msgId + "'").first
            
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    // メッセージを保存する
    func insertMessage(chatRoomModel:ChatRoomModel, mockMsg:MockMessage, msgType:String) -> MessageModel{
        let messageModel = MessageModel()
        messageModel.contents = mockMsg.innertext
        messageModel.entryDate = mockMsg.sentDate
        messageModel.messageId = mockMsg.messageId
        messageModel.messageType = msgType
        messageModel.senderId = mockMsg.sender.id
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                chatRoomModel.messages.append(messageModel)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        return messageModel
    }
    // メッセージを保存する
    func insertMessage(msgId:String, roomId:String, msg: NSDictionary) -> MessageModel{
        let chatRoomModel = getChatRoomModelByRoomId(roomId: roomId)
        let messageModel = MessageModel()
        messageModel.messageId = msgId
        messageModel.contents = msg[ChatDataManager.dbMessageContents] as! String
        messageModel.entryDate = DateUtils.dateFromString( msg[ChatDataManager.dbMessageEntryDate] as! String)
        messageModel.messageType = msg[ChatDataManager.dbMessageMsgType] as! String
        messageModel.senderId = msg[ChatDataManager.dbMessageSenderUid] as! String
        if msg[ChatDataManager.dbMessageRead] != nil {
            messageModel.read = true
        } else {
            messageModel.read = false
        }
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                if chatRoomModel?.messages.filter("messageId == '" + msgId + "'").count == 0 {
                chatRoomModel?.messages.append(messageModel)
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        return messageModel
    }
    // メッセージを保存する
    func insertMessage(msgId:String, messageType:String, contents:String, senderId:String, entryDate:Date, read:Bool){
        let messageModel = MessageModel()
        messageModel.messageId = msgId
        messageModel.messageType = messageType
        messageModel.contents = contents
        messageModel.senderId = senderId
        messageModel.entryDate = entryDate
        messageModel.read = read
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                realm.add(messageModel,update: true)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func insertUpdateMessage(_ mdl:MessageModel) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                realm.add(mdl, update: true)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    // メッセージを保存する
    func appendMessage(roomMdl:ChatRoomModel, msg: MessageModel) -> Void{
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                if roomMdl.messages.filter("messageId == '" + msg.messageId + "'").count == 0 {
                    roomMdl.messages.append(msg)
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    // メッセージの既読情報を更新する
    func updateMessageRead(msg: MessageModel) -> Void {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                msg.read = true
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func deleteMessage(msgId:String) {
        if let mdl = getMessage(msgId: msgId) {
            do{
                let realm = try Realm(configuration:RealmManager.config)
                try! realm.write {
                    realm.delete(mdl)
                }
                
            } catch {
                print("ERROR at")
                print(#file)
                print(#line)
                print(#function)
                print(error.localizedDescription)
            }
        }
    }
    
    func isExistMessage(msgId: String) -> Bool {
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let ret = realm.objects(MessageModel.self).filter("messageId == '" + msgId + "'")
            if ret.count > 0 {
                return true
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        return false
    }
    
    // 0:insert, 1:update
    func insertUpdateRequest(_ requestMdl:RequestModel) -> Int{
        var ret = -1
        
        // 既存データがあればアップデート
        if let reqMdl = getRequestByCustomerId(customerId: requestMdl.customerId){
            updateRequest(oldMdl: reqMdl, newMdl: requestMdl)
            ret = RealmManager.UPDATE
        } else {
            insertRequest(customerId: requestMdl.customerId, doctorId: requestMdl.doctorId, requestDate: requestMdl.requestDate, isConfirm: requestMdl.requestConfirm, confirmDate: requestMdl.requestConfirmDate)
            ret = RealmManager.INSERT
        }
        
        return ret
    }
    
    func updateRequest(oldMdl:RequestModel, newMdl:RequestModel) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            
            try! realm.write {
//                oldMdl.customerId = newMdl.customerId
                oldMdl.doctorId = newMdl.doctorId
                oldMdl.requestDate = newMdl.requestDate
                oldMdl.requestConfirm = newMdl.requestConfirm
                oldMdl.requestConfirmDate = newMdl.requestConfirmDate
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func insertRequest(customerId:String, doctorId:String, requestDate:Date?, isConfirm:Bool, confirmDate:Date?){
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let requestModel = RequestModel()
            requestModel.customerId = customerId
            requestModel.doctorId = doctorId
            requestModel.requestDate = requestDate
            requestModel.requestConfirm = isConfirm
            requestModel.requestConfirmDate = confirmDate
            
            try! realm.write {
                realm.add(requestModel, update:true)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func deleteRequest(customerId:String){
        if let req = getRequestByCustomerId(customerId: customerId) {
            do{
                let realm = try Realm(configuration:RealmManager.config)
                try! realm.write {
                    realm.delete(req)
                }
                
            } catch {
                print("ERROR at")
                print(#file)
                print(#line)
                print(#function)
                print(error.localizedDescription)
            }
        }
    }
    
    //
    func getRequestByCustomerId(customerId:String) -> RequestModel? {
        var ret :RequestModel?
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            ret = realm.objects(RequestModel.self).filter("customerId == '" + customerId + "'").first
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    func getRequestsByDoctorId(doctorId:String) -> [RequestModel] {
        var ret:[RequestModel] = []
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let temp = realm.objects(RequestModel.self).filter("doctorId == '" + doctorId + "'")
            for reqMdl in temp {
                ret.append(reqMdl)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    // ユーザの初回リクエスト用に医者情報を全て取得する
    func getDoctors() -> [UserModel] {
        var ret :[UserModel] = []
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let results = realm.objects(UserModel.self).filter(Constant.userType + " = '" + Constant.userTypeDoctor + "'").sorted(byKeyPath:Constant.clinicName, ascending: true)
            
            var it = results.makeIterator()
            while let userModel = it.next(){
                ret.append(userModel)
                
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
        
    }
    
    func clearDoctorData() {
        let doctors = getDoctors()
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                realm.delete(doctors)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func clearAllData() {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                realm.deleteAll()
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func getKindModelsOrderByKindNum() -> [CalKindModel]{
        var ret :[CalKindModel] = []
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let results = realm.objects(CalKindModel.self).sorted(byKeyPath:"kindNum", ascending: true)
            
            var it = results.makeIterator()
            while let calKindModel = it.next(){
                ret.append(calKindModel)
                
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    func updateKindModelKindNum(mdl:CalKindModel, newKindNum:Int) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                // Realm更新
                mdl.kindNum = newKindNum
                // FireBase登録
                FBRealTimeDataBaseManager.getInstance().updateKind(mdl)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    // 種別の登録
    func insertUpdateKind(_ newmdl:CalKindModel){
        if let oldMdl = getKind(kindId: newmdl.kindId){
            updateKind(newmdl, oldMdl: oldMdl)
        } else {
            insertKind(newmdl)
        }
    }
    
    func insertKind(_ newMdl:CalKindModel) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let fbM = FBRealTimeDataBaseManager.getInstance()
            try! realm.write {
                // Realm更新
                realm.add(newMdl, update:true)
                
                // ユーザ側はFireBaseには通知しない
                if CommonUtils.isUserTypeUser() {
                    return
                }
                // FireBase登録
                fbM.updateKind(newMdl)
                
                if newMdl.allCloseFlg == false {
                    // 営業時間
                    for op in newMdl.open {
                        // FireBase登録
                        fbM.updateKindDetail(op)
                    }
                    
                    // 休診時間
                    if newMdl.closeFlg {
                        for cl in newMdl.close {
                            // FireBase登録
                            fbM.updateKindDetail(cl)
                        }
                    }
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func updateKind(_ newMdl:CalKindModel, oldMdl:CalKindModel) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let fbM = FBRealTimeDataBaseManager.getInstance()
            try! realm.write {
                // 営業時間の削除対象を探す
                var delOpCl:[CalKindOpenCloseModel] = []
                
                // 営業時間の削除対象を探す
                for opOld in oldMdl.open {
                    var hit = false
                    for opNew in newMdl.open {
                        if opOld.kindId_openclose_num == opNew.kindId_openclose_num {
                            hit = true
                            break
                        }
                    }
                    if hit == false {
                        // 削除対象に入れる
                        delOpCl.append(opOld)
                    }
                }
                
                // 休診時間の削除対象を探す
                for clOld in oldMdl.close {
                    var hit = false
                    for clNew in newMdl.close {
                        if clOld.kindId_openclose_num == clNew.kindId_openclose_num {
                            hit = true
                            break
                        }
                    }
                    if hit == false {
                        // 削除対象に入れる
                        delOpCl.append(clOld)
                    }
                }
                
                // 削除する
                for opcl in delOpCl {
                    // FireBase削除
                    fbM.deleteKindDetail(id: opcl.kindId_openclose_num)
                    // realm削除
                    realm.delete(opcl)
                }
                
                // Realm更新
                realm.add(newMdl, update:true)
                // FireBase登録
                fbM.updateKind(newMdl)
                
                if newMdl.allCloseFlg == false {
                    // 営業時間
                    for op in newMdl.open {
                        // FireBase登録
                        fbM.updateKindDetail(op)
                    }
                    
                    // 休診時間
                    if newMdl.closeFlg {
                        for cl in newMdl.close {
                            // FireBase登録
                            fbM.updateKindDetail(cl)
                        }
                    }
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    // 種別の削除
    func deleteKind(kindId:String){
        if let kind = getKind(kindId:kindId) {
            do{
                let realm = try Realm(configuration:RealmManager.config)
                try! realm.write {
                    if CommonUtils.isUserTypeDoctor() {
                        let fbM = FBRealTimeDataBaseManager.getInstance()
                        // 子もとも連れで削除
                        for op in kind.open {
                            // FireBase登録
                            fbM.deleteKindDetail(id: op.kindId_openclose_num)
                            // Realm削除
                            realm.delete(op)
                        }
                        for cl in kind.close {
                            // FireBase登録
                            fbM.deleteKindDetail(id: cl.kindId_openclose_num)
                            // Realm削除
                            realm.delete(cl)
                        }
                    
                        // スケジュールの紐つけ情報も削除
                        let scheMdls = getScheduleModels(kind)
                        for mdl in scheMdls {
                            // Realm更新
                            mdl.kind = nil
                            mdl.kindId = ""
                            
                            // FireBase登録
                            fbM.updateSchedule(mdl)
                        }
                    
                    // 自身を削除
                        // FireBase登録
                        fbM.deleteKind(kind)
                    }
                    // Realm更新
                    realm.delete(kind)
                }
                
            } catch {
                print("ERROR at")
                print(#file)
                print(#line)
                print(#function)
                print(error.localizedDescription)
            }
        }
    }
    
    //
    func getKind(kindId:String) -> CalKindModel? {
        var ret :CalKindModel?
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            ret = realm.objects(CalKindModel.self).filter("kindId == '" + kindId + "'").first
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    func getKindsByDoctorId(doctorId:String) -> [CalKindModel] {
        var ret:[CalKindModel] = []
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let temp = realm.objects(CalKindModel.self).filter("doctorId == '" + doctorId + "'").sorted(byKeyPath: "kindNum", ascending: true)
            for mdl in temp {
                ret.append(mdl)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    // ユーザからしか呼ばれない
    func getKindDetail(_ id:String) -> CalKindOpenCloseModel?{
        var ret:CalKindOpenCloseModel?
        do {
            let realm = try Realm(configuration:RealmManager.config)
            ret = realm.objects(CalKindOpenCloseModel.self).filter("kindId_openclose_num == '" + id + "'").first
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    // ユーザからしか呼ばれない
    func insertUpdateKindDetail(_ mdl:CalKindOpenCloseModel) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                realm.add(mdl, update:true)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    // ユーザからしか呼ばれない
    func deleteKindDetail(_ id:String) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            if let ret = getKindDetail(id) {
                try! realm.write {
                    // realm削除
                    realm.delete(ret)
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func getScheduleModelsOrderByDate(yyyymm yearMonth:String) -> [ScheduledDateModel]{
        var ret :[ScheduledDateModel] = []
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let results = realm.objects(ScheduledDateModel.self).filter("id_yyyymmdd BEGINSWITH '" + yearMonth + "'").sorted(byKeyPath:"id_yyyymmdd", ascending: true)
            var it = results.makeIterator()
            while let mdl = it.next(){
                ret.append(mdl)
                
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    
    // kind削除時にkindに紐つくスケジュール情報を取得したい
    func getScheduleModels(_ kindMdl :CalKindModel) -> [ScheduledDateModel]{
        var ret :[ScheduledDateModel] = []

        do {
            let realm = try Realm(configuration:RealmManager.config)
            let results = realm.objects(ScheduledDateModel.self).filter("kindId == '" + kindMdl.kindId + "'")
            var it = results.makeIterator()
            while let mdl = it.next(){
                ret.append(mdl)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }

        return ret
    }
    
    func updateInsertScheduleModel(_ mdl:ScheduledDateModel) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            try! realm.write {
                realm.add(mdl, update:true)
                // FireBase登録
                if CommonUtils.isUserTypeDoctor() {
                    FBRealTimeDataBaseManager.getInstance().updateSchedule(mdl)
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func deleteScheduleModel(_ id_yyyymmdd:String) {
        do {
            let realm = try Realm(configuration:RealmManager.config)
            if let ret = getSchedule(id_yyyymmdd) {
                try! realm.write {
                    // FireBase登録
                    if CommonUtils.isUserTypeDoctor() {
                        FBRealTimeDataBaseManager.getInstance().deleteSchedule(ret)
                    }
                    // realm削除
                    realm.delete(ret)
                }
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
    }
    
    func getSchedulesByDoctorId(doctorId:String) -> [ScheduledDateModel] {
        var ret:[ScheduledDateModel] = []
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            let temp = realm.objects(ScheduledDateModel.self).filter("doctorId == '" + doctorId + "'").sorted(byKeyPath: "id_yyyymmdd", ascending: true)
            for mdl in temp {
                ret.append(mdl)
            }
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
    func getSchedule(_ id_yyyymmdd:String) -> ScheduledDateModel? {
        var ret:ScheduledDateModel?
        
        do {
            let realm = try Realm(configuration:RealmManager.config)
            ret = realm.objects(ScheduledDateModel.self).filter("id_yyyymmdd == '" + id_yyyymmdd + "'").first
        } catch {
            print("ERROR at")
            print(#file)
            print(#line)
            print(#function)
            print(error.localizedDescription)
        }
        
        return ret
    }
}
