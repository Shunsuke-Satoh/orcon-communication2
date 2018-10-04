//
//  ChatDataManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/19.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import Firebase
import MessageKit
import RealmSwift

// チャットのメッセージや相手のアイコン画像などを取得してローカルに保存する
// 保存したデータの呼び出しも行う

class ChatDataManager: NSObject{
    
    var ref: DatabaseReference!
    var reqObs = Dictionary<UIViewController, Dictionary<String,String>>()
    
    var delegateMsg:MessageLoadDelegate?
    var delegateReq:RequestDelegate?
    var isAddObsMessage = false
    var obsChatRoomIds: [String] = [] // 監視しているチャットルームIDs
    
    static var own: ChatDataManager?
    
    override init() {
        super.init()
        // チャットデータの取得
        ref = Database.database().reference()
    }
    static func getInstance() -> ChatDataManager{
        if own == nil {
            own = ChatDataManager()
        }
        return own!
    }
    
    func getDataFromDB() -> Void{
        
        let userDM = UserDefaultManager()
        
        // 初回登録時はやらない
        if userDM.getOwnUserId() == "" {
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        let uid = userDM.getOwnUserId()

        ref.child(Constant.dbUser + "/" + uid).observeSingleEvent(of: .value, with: { snapshot in
            let user = snapshot.value as? NSDictionary
            
            let rooms = user?[Constant.dbUserRooms] as? NSDictionary
            // チャットルームが存在しなかったら終了
            if rooms == nil {
                return
            }
            // チャットルーム毎に
            for (roomIdtemp, otherUid) in rooms! {
                let roomId = roomIdtemp as! String
                let otherUid = otherUid as! String
                
                // チャットルームをRealmに保存
                let realmDM = RealmManager.getInstance()
                let roomMdl = realmDM.insertUpdateChatRoom(roomId: roomId, userId: otherUid)
                
                // Realmに保持している情報があるか
                let msgModels = realmDM.getMessagesByRoomId(roomId: roomId)
                
                // 画像の取得に前回失敗している場合があるのでローカルにない場合は取得
                for msg in msgModels {
                    if msg.messageType == Constant.msgTypeImage {
                        self.getMessageImg(roomId: roomId, msgModel: msg, callback: {})
                    }
                }
                
                var lastMessageDate = "" // 最新メッセージの日時
                if (msgModels.count) > 0 {
                    lastMessageDate = DateUtils.stringFromDate((msgModels.last?.entryDate)!)
                }
                
                // チャットメッセージの取り出し(非同期なので全て完了後に
                dispatchGroup.enter()
                DispatchQueue.global().async(group: dispatchGroup) {
                    // メッセージのと取得・登録
                    self.getChatMessage(roomId: roomId,lastMessageDate: lastMessageDate ,callback: {(messageModels)->Void in
                        let realmDM = RealmManager.getInstance()
                        
                        // roomのメッセージ配列参照に登録
                        for messageMdl in messageModels{
                            realmDM.appendMessage(roomMdl:roomMdl, msg: messageMdl)
                        }
                        
                        dispatchGroup.leave()
                        
                    })
                }
                
                // ユーザ情報の取り出し
                dispatchGroup.enter()
                DispatchQueue.global().async(group: dispatchGroup) {
                    //[weak self] in
                    self.getUserInfo(userId:otherUid, callback: {(userName,iconPath,uiImage,iconImgUpdate)->Void in
                        
                        let userDM = UserDefaultManager()
                        
                        // チャットルームをRealmに保存
                        _ = realmDM.insertUpdateChatRoom(roomId: roomId, userId: otherUid)
                        
                        realmDM.updateUser(roomId: roomId, name: userName, iconImgPathWeb: iconPath, iconImgUpdate: iconImgUpdate)
                        
                        // ローカルに画像保存
                        userDM.saveImageIcon(userId: otherUid, uiImage: uiImage)
                        
                        dispatchGroup.leave()
                    })
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // トピックにトークンを登録
                CommonUtils.signInTockenToChat()
                CommonUtils.signInTockenToRequest()
                print("ALL LOAD")
            }
            
        }) { error in
            print("ERROR at")
            print(#file)
            print(#function)
            print(#line)
            print(error.localizedDescription)
        }
    }
    
    
    func getChatMessage(roomId:String, lastMessageDate:String, callback: @escaping ([MessageModel])->Void) -> Void{
        var ret :[MessageModel] = []
        let ref = self.ref.child(Constant.dbMessage).child(roomId)

        // 初期化処理のため必ず問い合わせにいく
        // ローカルに全く保存されていない場合は空文字になり、全取得する
        if lastMessageDate != "" {
            ref.queryStarting(atValue: lastMessageDate, childKey: Constant.dbMessageEntryDate).queryOrdered(byChild: Constant.dbMessageEntryDate).observeSingleEvent(of: .value, with: { snapshot in
                for child in snapshot.children {
                    
                    let item = child as! DataSnapshot
                    let msg = item.value as? NSDictionary
                    
                    let msgModel = MessageModel()
                    let msgDate = msg?[Constant.dbMessageEntryDate] as! String
                    
                    msgModel.contents = msg?[Constant.dbMessageContents] as! String
                    msgModel.entryDate = DateUtils.dateFromString(msgDate)
                    msgModel.messageType = msg?[Constant.dbMessageMsgType] as! String
                    msgModel.senderId = msg?[Constant.dbMessageSenderUid] as! String
                    msgModel.messageId = item.key
                    if let isRead = msg?[Constant.dbMessageRead] as? Bool{
                        msgModel.read = isRead
                    }
                    
                    RealmManager.getInstance().insertUpdateMessage(msgModel)
                    
                    ret.append(msgModel)
                    
                    // メッセージが画像だったら画像を取得（非同期）
                    if msgModel.messageType == Constant.msgTypeImage {
                        self.getMessageImg(roomId: roomId, msgModel: msgModel, callback: {})
                    }
                }
                callback(ret)
            }) { error in
                print("ERROR at")
                print(#file)
                print(#function)
                print(#line)
                print(error.localizedDescription)
            }
        } else {
            ref.queryOrdered(byChild: Constant.dbMessageEntryDate).observeSingleEvent(of: .value, with: { snapshot in
                for child in snapshot.children {
                    
                    let item = child as! DataSnapshot
                    let msg = item.value as? NSDictionary
                    
                    let msgModel = MessageModel()
                    let msgDate = msg?[Constant.dbMessageEntryDate] as! String
                    
                    msgModel.contents = msg?[Constant.dbMessageContents] as! String
                    msgModel.entryDate = DateUtils.dateFromString(msgDate)
                    msgModel.messageType = msg?[Constant.dbMessageMsgType] as! String
                    msgModel.senderId = msg?[Constant.dbMessageSenderUid] as! String
                    msgModel.messageId =  item.key
                    
                    ret.append(msgModel)
                    
                    // メッセージが画像だったら画像を取得（非同期）
                    if msgModel.messageType == Constant.msgTypeImage {
                        self.getMessageImg(roomId: roomId, msgModel: msgModel, callback: {})
                    }
                }
                callback(ret)
            }) { error in
                print("ERROR at")
                print(#file)
                print(#function)
                print(#line)
                print(error.localizedDescription)
            }
        }
        
        
        // オブザーバ
        let exist = obsChatRoomIds.filter({obsRoomId in
            return obsRoomId == roomId
        }).count
        if exist == 0 {
            // メッセージが追加されるたびに検知するメソッドを追加
            ref.queryStarting(atValue: lastMessageDate, childKey: Constant.dbMessageEntryDate).queryOrdered(byChild: Constant.dbMessageEntryDate).observe(.childAdded, with: {snapshot in
                
                let msgId = snapshot.key
                let msg = snapshot.value as? NSDictionary
                let realmDM = RealmManager.getInstance()
                if !realmDM.isExistMessage(msgId: msgId) {
                    let msgModel = realmDM.insertMessage(msgId:msgId, roomId:roomId, msg:msg!)
                    
                    // メッセージが画像だったら画像を取得
                    if msgModel.messageType == Constant.msgTypeImage {
                        
                        self.getMessageImg(roomId: roomId, msgModel: msgModel, callback: {
                            // メッセージ追加の通知
                            self.delegateMsg?.messageUpdated(msgModel: msgModel)
                        })
                    } else {
                        // メッセージ追加の通知
                        self.delegateMsg?.messageUpdated(msgModel: msgModel)
                    }
                }
            })
            
            // メッセージが既読になるたびに検知するメソッドを追加
            ref.queryStarting(atValue: lastMessageDate, childKey: Constant.dbMessageEntryDate).queryOrdered(byChild: Constant.dbMessageEntryDate).observe(.childChanged, with: {snapshot in
                
                let userDM = UserDefaultManager()
                let msgId = snapshot.key
                let realmDM = RealmManager.getInstance()
                if realmDM.isExistMessage(msgId: msgId) {
                    let msgModel = realmDM.getMessage(msgId: msgId)!
                    // 自分のメッセージが読まれたら更新する
                    if msgModel.senderId == userDM.getOwnUserId() {
                        realmDM.updateMessageRead(msg: msgModel)
                    }
                    // メッセージ追加の通知
                    self.delegateMsg?.messageReaded(msgModel: msgModel)
                }
            })
            
            obsChatRoomIds.append(roomId)
        }
        
        
    }
    
    // 相手のユーザ情報を取得して変更があればアイコン画像なども更新する
    func getUserInfo(userId:String, callback: @escaping (String, String, UIImage,Date)->Void) -> Void{
        self.ref.child(Constant.dbUser + "/" + userId).observeSingleEvent(of: .value, with: { snapshot in
            let realmDM = RealmManager.getInstance()
            let profile = snapshot.value as? NSDictionary
            
            let userName = profile?[Constant.dbUserName] as! String
            
            let userModel = realmDM.getUserModelByUserId(userId: userId)
            
            let iconUpdate = profile?[Constant.dbUserIconimgupdate] as! String
            let iconUpdateDate = DateUtils.dateFromString(iconUpdate)
            
            if let userIconUpdate = userModel?.iconImgUpdate {
                // アイコン情報が更新されていなければ画像は取らない
                if userIconUpdate >= iconUpdateDate && UserDefaultManager().loadImageIcon(userId: userId) != nil{
                    callback(userName, "", UserDefaultManager().loadImageIcon(userId: userId)!,iconUpdateDate)
                    return
                }
            }
            
            let imgMG = FBStorageManager()
            imgMG.downLoadImage(fullPath: imgMG.getUserIconImgPath(userId: userId),callback: {(uiImage)->Void in
                callback(userName, imgMG.getUserIconImgPath(userId: userId), uiImage,iconUpdateDate)
            })
            
        }) { error in
            print("ERROR at")
            print(#file)
            print(#function)
            print(#line)
            print(error.localizedDescription)
        }
    }
    
    func getMessageImg(roomId:String, msgModel:MessageModel, callback:@escaping ()->Void) {
        let imgM = FBStorageManager()
        let imgPath = imgM.getMessagePath(roomId: roomId, message: msgModel)
        
        imgM.downLoadImage(fullPath: imgPath, callback: { (img) in
            // ローカルに保存
            UserDefaultManager().saveImageForMessage(messageId: msgModel.messageId, uiImage: img)
            
            callback()
        })
    }
    
    
    func setRequestObserver() {
        if ((delegateReq as? UIViewController) == nil) {
            return
        }
        
        let deleReq = delegateReq as! UIViewController
        // 登録ずみなら何もしない
        if reqObs[deleReq] != nil {
            return
        }
        
        var obs = Dictionary<String,String>()
        if CommonUtils.isUserTypeDoctor() {
            let doctorId = UserDefaultManager().getOwnUserId()
            // リクエストが追加されるたびに検知するメソッドを追加
            let addPath = Constant.dbRequest + "/" + doctorId
            self.ref.child(addPath).observe(.childAdded, with: {snapshot in
                
                let (ret,reqMdl) = self.setReqModelAndInsUpdate(snapshot,doctorId: doctorId)
                
                // 新規リクエストの場合はユーザ情報がないので取得
                if RealmManager.getInstance().getUserModelByUserId(userId: reqMdl.customerId) == nil {
                    FBRealTimeDataBaseManager.getInstance().getUserByUserId(userId: reqMdl.customerId, callback: {userMdl,_,error in
                        // ユーザ取得に失敗した場合、とりあえずユーザ情報を作っておく、そのうち再起動でもう一度呼ばれる
                        if userMdl.userId == "" {
                            RealmManager.getInstance().insertUpdateUser(userId: reqMdl.customerId, userType: Constant.userTypeCustomer, name: "", tel: "", email: "", clinicName: "", clinicAddress: "", rooms: [], requestDoctorId: doctorId, entryDate: Date(), status: 0)
                        }
                    })
                }
                
                if ret == RealmManager.INSERT{
                    // デリゲート
                    self.delegateReq?.requestInserted(reqModel: reqMdl)
                }
                
                // バッジ更新
                CommonUtils.setBadge()
            })
            obs["add"] = addPath
            
            // リクエストが変更されるたびに検知するメソッドを追加
            let changePath = Constant.dbRequest + "/" + doctorId
            self.ref.child(changePath).observe(.childChanged, with: {snapshot in
                
                let (ret,reqMdl) = self.setReqModelAndInsUpdate(snapshot,doctorId: doctorId)
                
                if ret == RealmManager.UPDATE{
                    // デリゲート
                    self.delegateReq?.requestUpdated(reqModel: reqMdl)
                }
                
                // バッジ更新
                CommonUtils.setBadge()
            })
            obs["change"] = changePath
            
            // リクエストが削除されるたびに検知するメソッドを追加
            let removePath = Constant.dbRequest + "/" + doctorId
            self.ref.child(removePath).observe(.childRemoved, with: {snapshot in
                
                let customerId = snapshot.key
                
                let realmDM = RealmManager.getInstance()
                realmDM.deleteRequest(customerId: customerId)
                realmDM.deleteUserModel(customerId)
                
                // デリゲート
                self.delegateReq?.requestDeleted(doctorId: doctorId, customerId: customerId)
                
                // バッジ更新
                CommonUtils.setBadge()
            })
            obs["remove"] = removePath
            reqObs[deleReq] = obs
        }
        // カスタマーの時
        else {
            let ownId = UserDefaultManager().getOwnUserId()
            let ownReqMdl = RealmManager.getInstance().getRequestByCustomerId(customerId: ownId)
            if ownReqMdl == nil {
                return
            }
            let doctorId = ownReqMdl!.doctorId
            
            // リクエストが追加されるたびに検知するメソッドを追加
            let addPath = Constant.dbRequest + "/" + doctorId + "/" + ownId
            self.ref.child(addPath).observe(.childAdded, with: {snapshot in
                
                let attr = snapshot.key
                if attr == Constant.dbRequestConfirmDate {
                    
                    let realmDM = RealmManager.getInstance()
                    
                    let confDate = snapshot.value as! String
                    let base = realmDM.getRequestByCustomerId(customerId: ownId)!
                    let req = base.copyModel()
                    req.requestConfirmDate = DateUtils.dateFromString(confDate)
                    _ = realmDM.insertUpdateRequest(req)
                    // デリゲート
                    self.delegateReq?.requestInserted(reqModel:req)
                    
                }
            })
            obs["add"] = addPath
            
            // リクエストが変更されるたびに検知するメソッドを追加
            let changePath = Constant.dbRequest + "/" + doctorId + "/" + ownId
            self.ref.child(changePath).observe(.childChanged, with: {snapshot in
                
                let attr = snapshot.key
                if attr == Constant.dbRequestIsConfirm {
                    
                    let realmDM = RealmManager.getInstance()
                    
                    let isConf = snapshot.value as! Bool
                    let base = realmDM.getRequestByCustomerId(customerId: ownId)!
                    let req = base.copyModel()
                    
                    req.requestConfirm = isConf
                    _ = realmDM.insertUpdateRequest(req)
                    // デリゲート
                    self.delegateReq?.requestInserted(reqModel:req)
                    
                }
            })
            obs["change"] = changePath
            
            // リクエストが削除されるたびに検知するメソッドを追加
            let removePath = Constant.dbRequest + "/" + doctorId + "/" + ownId
            self.ref.child(removePath).observe(.childRemoved, with: {_ in
                
                
                let realmDM = RealmManager.getInstance()
                if realmDM.getRequestByCustomerId(customerId: ownId) != nil{
                    realmDM.deleteRequest(customerId: ownId)
                    // デリゲート
                    self.delegateReq?.requestDeleted(doctorId: doctorId, customerId: ownId)
                }
                
            })
            obs["remove"] = removePath
            reqObs[deleReq] = obs
        }
    }
    
    func setReqModelAndInsUpdate(_ snapshot:DataSnapshot, doctorId:String) -> (Int, RequestModel) {
        
        let customerId = snapshot.key
        let req = snapshot.value as! NSDictionary
        let reqModel = RequestModel()
        reqModel.doctorId = doctorId
        reqModel.customerId = customerId
        reqModel.requestDate = DateUtils.dateFromString(req[Constant.dbRequestRequestDate] as! String)
        reqModel.requestConfirm = req[Constant.dbRequestIsConfirm] as! Bool
        if let confDate = req[Constant.dbRequestConfirmDate] as? String{
            reqModel.requestConfirmDate = DateUtils.dateFromString(confDate)
        }
        
        let realmDM = RealmManager.getInstance()
        let ret = realmDM.insertUpdateRequest(reqModel)
        
        return (ret,reqModel)
    }
    
}


protocol MessageLoadDelegate {
    func messageUpdated(msgModel:MessageModel)
    func messageReaded(msgModel:MessageModel)
}

protocol RequestDelegate {
    func requestUpdated(reqModel:RequestModel)
    func requestInserted(reqModel:RequestModel)
    func requestDeleted(doctorId:String, customerId:String)
}
