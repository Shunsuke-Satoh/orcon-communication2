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

class ChatDataManager{
    static let dbRoom = "room"
    static let dbRoomIdMembers = "members"
    static let dbRoomIdLatestmsgnum = "latest_msg_num"
    
    static let dbMessage = "message"
    static let dbMessageSenderUid = "sender_uid"
    static let dbMessageMsgType = "message_type"
    static let dbMessageContents = "contents"
    static let dbMessageEntryDate = "entry_date"
    static let dbMessageRead = "read"
    
    private var refRoom: DatabaseReference!
    private var refMsg: DatabaseReference!
    private let userDM: UserDefaultManager!
    private let imgM: FBStorageManager!
    private let realmM: RealmManager!
    private var getDatas:[String] = [] // ダウンロード試行済みのデータ
    private var obserbers = Dictionary<String, [UInt]>() // 登録済みのオブザーバ
    var delegate:MessageDelegate? // デリゲート
    
    private var obsChatRoomIds: [String] = [] // 監視しているチャットルームIDs
    
    private static var own: ChatDataManager?
    
    private init() {
        // チャットデータの取得
        refRoom = Database.database().reference().child(ChatDataManager.dbRoom)
        refMsg = Database.database().reference().child(ChatDataManager.dbMessage)
        imgM = FBStorageManager()
        userDM = UserDefaultManager()
        realmM = RealmManager.getInstance()
    }
    
    static func getInstance() -> ChatDataManager{
        if own == nil {
            own = ChatDataManager.init()
        }
        return own!
    }
    
    /// 自身に関わるユーザ情報、チャットルーム、メッセージをFirebaseから取得する
    /// コールバック時はメッセージ,他者ユーザ情報,リクエスト情報はFirebaseと同期状態になる
    /// 画像メッセージの場合は画像がダウンロードできてるかどうかは保証されない
    /// - Parameter callback: errorMsgが空文字の場合は成功
    func getDataFromDB(callback:@escaping (_ errorMsg:String) -> Void) -> Void{
        
        // 初回登録時はやらない
        if userDM.getOwnUserId() == "" {
            return
        }
        
        let uid = userDM.getOwnUserId()
        
        // 自身のユーザ情報をダウンロードする（既にダウンロードしていたら一瞬でコールバックされる）,チャットルームもできてる
        FBUserManager.getInstance().getData(uid, callback: {(errorMsg) in
            let dispatchGroup = DispatchGroup()
            
            if errorMsg != "" {
                callback(errorMsg) // タイムアウトかモデルがサーバにない
                
            }
            
            let ownUser = self.realmM.getUserModelByUserId(userId: uid)!
            // ユーザデフォルトにユーザタイプを保存
            self.userDM.setOwnUserType(userType: ownUser.userType)
            
            // realmモデルを別スレッドに持ち込んだらいけないので欲しい変数だけ保存
            let requestDoctorId = ownUser.requestDoctorId
            
            // リクエスト情報を取得
            dispatchGroup.enter()
            DispatchQueue.global().async(group: dispatchGroup) {
                
                FBRequestManager.getInstance().getData(requestDoctorId, callback: {(errorMsg) in
                    
                    // エラーは上にあげる
                    if errorMsg != "" {
                        callback(errorMsg)
                    }
                    
                    // 同期したいので完了を待つ
                    dispatchGroup.leave()
                })
            }
            
            // チャット情報を取得
            for roomId in ownUser.chatRooms {
                let roomMdl = self.realmM.getChatRoomModelByRoomId(roomId: roomId)!
                
                // 画像の取得に前回失敗している場合があるのでローカルにない場合は取得
                for msg in roomMdl.messages {
                    if msg.messageType == Constant.msgTypeImage {
                        self.getMessageImg(roomId: roomId, msgModel: msg, callback: {})
                    }
                }
                
                // チャットメッセージの取り出し(別スレッドなのでrealmは渡さない
                dispatchGroup.enter()
                DispatchQueue.global().async(group: dispatchGroup) {
                    // メッセージの取得・登録
                    self.getData(roomId ,callback: {(_) in
                        // 同期したいので完了を待つ
                        dispatchGroup.leave()
                    })
                }
            }
            
            
            dispatchGroup.notify(queue: .main) {
                // トピックにトークンを登録
                CommonUtils.getInstance().signInTockenToChat(false)
                CommonUtils.getInstance().signInTockenToRequest(false)
                let users = self.realmM.getUserModelsExceptOwn()
                for usr in users {
                    FBUserManager.getInstance().setObserver(usr.userId)
                }
                
                callback("")
            }
        })
    }
    
    
    func getData(_ roomId:String, callback:@escaping (_ errorMsg:String) -> Void) {
        
        // 試行ずみなら何もしない
        if getDatas.contains(roomId) {
            callback("")
            return
        }
        
        // 一旦多重起動は止める
        getDatas.append(roomId)
        
        let tempMdl = realmM.getChatRoomModelByRoomId(roomId: roomId)!
        
        // メッセージが全くない場合は全量取得
        if tempMdl.lastDate == nil {
            
            refMsg.child(roomId).queryOrdered(byChild: ChatDataManager.dbMessageEntryDate).observeSingleEvent(of: .value, with: { (snapshot) in
                let newMdl = self.realmM.getChatRoomModelByRoomId(roomId: roomId)!.copyModel()
                // 念のため全部クリア
                newMdl.messages.removeAll()
                
                // realmにメッセージとチャットルームの関係を保存
                self.saveMessageFromSnap(snapshot, newMdl: newMdl)
                callback("")
            })
        }
            // 途中から取得
        else {
                refMsg.child(roomId).queryStarting(atValue: DateUtils.stringFromDate(tempMdl.lastDate!), childKey: ChatDataManager.dbMessageEntryDate).queryOrdered(byChild: ChatDataManager.dbMessageEntryDate).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let newMdl = self.realmM.getChatRoomModelByRoomId(roomId: roomId)!.copyModel()
                    // realmにメッセージとチャットルームの関係を保存
                    self.saveMessageFromSnap(snapshot, newMdl: newMdl)
                    callback("")
            })
        }
        // オブザーバも追加
        setObserverMsg(roomId)
    }
    
    func saveMessageFromSnap(_ snapshot:DataSnapshot, newMdl:ChatRoomModel) {
        for child in snapshot.children {
            let item = child as! DataSnapshot
            let msg = item.value as? NSDictionary
            
            // 同じものは取得しない
            var flag = false
            for msg in newMdl.messages {
                if msg.messageId == item.key {
                    flag = true
                    break
                }
            }
            if flag {
                continue
            }
            
            // 登録
            let mdl = MessageModel()
            mdl.messageId =  item.key
            mdl.messageType = msg?[ChatDataManager.dbMessageMsgType] as! String
            mdl.contents = msg?[ChatDataManager.dbMessageContents] as! String
            mdl.senderId = msg?[ChatDataManager.dbMessageSenderUid] as! String
            let msgDate = msg?[ChatDataManager.dbMessageEntryDate] as! String
            mdl.entryDate = DateUtils.dateFromString(msgDate)
            if let isRead = msg?[ChatDataManager.dbMessageRead] as? Bool{
                mdl.read = isRead
            }
            
            // Realm保存
            self.realmM.insertMessage(msgId: mdl.messageId, messageType: mdl.messageType, contents: mdl.contents, senderId: mdl.senderId, entryDate: mdl.entryDate, read: mdl.read)
            
            let savedMdl = self.realmM.getMessage(msgId: mdl.messageId)!
            
            // チャットルームに追加
            newMdl.messages.append(savedMdl)
            // 最終更新日を更新
            newMdl.lastDate = mdl.entryDate
            
            // メッセージが画像だったら画像を取得（非同期）
            if mdl.messageType == Constant.msgTypeImage {
                self.getMessageImg(roomId: newMdl.roomId, msgModel: mdl, callback: {})
            }
        }
        
        // チャットルームにメッセージ追加
        self.realmM.insertUpdateChatRoom(newMdl)
    }
    
    func setObserverMsg(_ roomId:String){
        // 登録ずみなら何もしない
        if obserbers.keys.contains(roomId) {
            return
        }
        
        var localObs:[UInt] = []
        
        let roomMdl = realmM.getChatRoomModelByRoomId(roomId: roomId)!
        var lastMessageDate = ""
        if roomMdl.lastDate != nil {
            lastMessageDate = DateUtils.stringFromDate(roomMdl.lastDate!)
        }
        
        // メッセージが追加されるたびに検知するメソッドを追加
        localObs.append(refMsg.child(roomId).queryStarting(atValue: lastMessageDate, childKey: ChatDataManager.dbMessageEntryDate).queryOrdered(byChild: ChatDataManager.dbMessageEntryDate).observe(.childAdded, with: {snapshot in
            
            let msgId = snapshot.key
            let msg = snapshot.value as? NSDictionary
            if self.realmM.isExistMessage(msgId: msgId) == false{
                let msgModel = self.realmM.insertMessage(msgId:msgId, roomId:roomId, msg:msg!)
                
                // メッセージが画像だったら画像を取得
                if msgModel.messageType == Constant.msgTypeImage {
                    
                    self.getMessageImg(roomId: roomId, msgModel: msgModel, callback: {
                        // メッセージ追加の通知
                        self.delegate?.messageUpdated(msgModel: msgModel)
                    })
                } else {
                    // メッセージ追加の通知
                    self.delegate?.messageUpdated(msgModel: msgModel)
                }
            } else {
                let msgModel = self.realmM.getMessage(msgId: msgId)!
                
                if msgModel.senderId == self.userDM.getOwnUserId() {
                    if let read = msg?[ChatDataManager.dbMessageRead] as? Bool {
                        if read {
                            self.realmM.updateMessageRead(msg: msgModel)
                            // メッセージ追加の通知
                            self.delegate?.messageReaded(msgModel: msgModel)
                        }
                    }
                }
            }
        }))
        
        // メッセージが既読になるたびに検知するメソッドを追加
        localObs.append(refMsg.child(roomId).queryStarting(atValue: lastMessageDate, childKey: ChatDataManager.dbMessageEntryDate).queryOrdered(byChild: ChatDataManager.dbMessageEntryDate).observe(.childChanged, with: {snapshot in
            
            let userDM = UserDefaultManager()
            let msgId = snapshot.key
            if self.realmM.isExistMessage(msgId: msgId) {
                let msgModel = self.realmM.getMessage(msgId: msgId)!
                // 自分のメッセージが読まれたら更新する
                if msgModel.senderId == userDM.getOwnUserId() {
                    self.realmM.updateMessageRead(msg: msgModel)
                    // メッセージ既読の通知
                    self.delegate?.messageReaded(msgModel: self.realmM.getMessage(msgId: msgModel.messageId)!)
                }
            }
        }))
        
        obserbers[roomId] = localObs
    }
    
    func getMessageImg(roomId:String, msgModel:MessageModel, callback:@escaping ()->Void) {
        let imgM = FBStorageManager()
        let imgPath = imgM.getMessagePath(roomId: roomId, message: msgModel)
        
        imgM.downLoadImage(fullPath: imgPath, callback: { (img) in
            // ローカルに保存
            self.userDM.saveImageForMessage(messageId: msgModel.messageId, uiImage: img)
            
            callback()
        })
    }
    
    func uploadMessage(roomId: String, messageModel:MessageModel){
        var message = Dictionary<String, Any>()
        
        // メッセージタイプ（テキスト・画像）
        message[ChatDataManager.dbMessageMsgType] = messageModel.messageType
        
        // メッセージ内容
        if messageModel.messageType == Constant.msgTypeText {
            message[ChatDataManager.dbMessageContents] = messageModel.contents
            
            // 画像メッセージの時はコンテンツにFireStorage上のフルパスを入れる
        } else if messageModel.messageType == Constant.msgTypeImage {
            message[ChatDataManager.dbMessageContents] = imgM.getMessagePath(roomId: roomId, message: messageModel)
        }
        // 登録日時
        message[ChatDataManager.dbMessageEntryDate] = DateUtils.stringFromDate(messageModel.entryDate)
        
        // 投稿者ユーザID
        message[ChatDataManager.dbMessageSenderUid] = messageModel.senderId
        
        // RealTimeDBにアップロード
        refMsg.child(roomId + "/" + messageModel.messageId).setValue(message)
    }
    
    func updateRead(roomId:String,messageModel:MessageModel){
        refMsg.child(roomId + "/" + messageModel.messageId + "/read").setValue(true)
    }
}


protocol MessageDelegate {
    func messageUpdated(msgModel:MessageModel)
    func messageReaded(msgModel:MessageModel)
}
