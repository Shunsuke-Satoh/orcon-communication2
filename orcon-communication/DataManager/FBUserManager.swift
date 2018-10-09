//
//  FBUserManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/05.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import Firebase

class FBUserManager {
    
    static let dbUser = "user"
    static let dbUserUsertype = "user_type"
    static let dbUserName = "name"
    static let dbUserHira = "hira"
    static let dbUserTel = "tel"
    static let dbUserEmail = "email"
    static let dbUserClinicName = "clinic_name"
    static let dbUserClinicAddress = "clinic_address"
    static let dbUserTopimgupdate = "top_img_update"
    static let dbUserIconimgupdate = "icon_img_update"
    static let dbUserRooms = "rooms"
    static let dbUserRequestdoctorid = "request_doctorId"
    static let dbUserEntryDate = "entry_date"
    static let dbUserStatus = "status" /* 0:リクエスト中, 1:治療中, 2:治療完了 */
    static let dbUserDeleteDate = "delete_date"
    
    static let dbDoctor = "doctor"
    static let dbDoctorName = "name"
    static let dbDoctorEmail = "email"
    static let dbDoctorTel = "tel"
    static let dbDoctorClinicName = "clinic_name"
    static let dbDoctorClinicAddress = "clinic_address"
    
    private let ref: DatabaseReference!
    private let refDoc: DatabaseReference!
    private let userDM: UserDefaultManager!
    private let imgM: FBStorageManager!
    private let realmM: RealmManager!
    
    private var getDatas:[String] = [] // ダウンロード試行済みのデータ
    private var obserbers = Dictionary<String, UInt>() // 登録済みのオブザーバ
    var delegate:FBUserManagerDelegate? // デリゲート
    var delegateImg:FBUserManagerImageDelegate? // 画像ダウンロードデリゲート
    
    private static var own: FBUserManager?
    
    private init(){
        ref = Database.database().reference().child(FBUserManager.dbUser)
        refDoc = Database.database().reference().child(FBUserManager.dbDoctor)
        imgM = FBStorageManager()
        userDM = UserDefaultManager()
        realmM = RealmManager.getInstance()
    }
    
    static func getInstance() -> FBUserManager{
        if own == nil {
            own = FBUserManager.init()
        }
        return own!
    }
    
    /// ユーザ情報をFirebaseから取得する
    /// 1.自分のユーザ情報取得
    ///   -- チャットルームを作る
    ///   -- 自身に関わるユーザも取得する（コールバック時はRealmに最新状態は保証されない
    ///   -- オブザーバはセットしない (FireBaseとは同期しない、つまり自分で同期させろってこと)
    /// 2.他者のユーザ情報取得
    ///   --チャットルームは作らない
    ///   --オブザーバをセットする（FireBaseと同期状態になる)
    /// - Parameters:
    ///   - userId: 取得したいユーザID, 自身のユーザIDかどうかで挙動が異なる
    ///   - callback: errorMsgが空文字の場合は成功, 要求したユーザ情報はRealmに最新状態が保証されている
    func getData(_ userId:String, callback: @escaping (_ errorMsg:String) -> Void) {
        // 試行ずみなら何もしない
        if getDatas.contains(userId) {
            callback("")
            return
        }
        
        // 一旦多重起動は止める
        getDatas.append(userId)
        
        let ret :UserModel = UserModel()
        var isFinish = false
        
        ref.child(userId).observeSingleEvent(of: .value, with: {(snapshot) in
            
            // 見つからなかったら終了
            if !snapshot.exists() {
                callback("サーバにデータがありません")
                // ダウンロード失敗したので再試行できるようにする
                for (indx, uid) in self.getDatas.enumerated() {
                    if uid == userId {
                        self.getDatas.remove(at: indx)
                        break
                    }
                }
                isFinish = true
                return
            }
            // 見つかった
            let userFB = snapshot.value as! NSDictionary
            ret.userId = userId
            ret.name = userFB[FBUserManager.dbUserName] as! String
            ret.hira = userFB[FBUserManager.dbUserHira] as! String
            ret.tel = userFB[FBUserManager.dbUserTel] as! String
            ret.email = userFB[FBUserManager.dbUserEmail] as! String
            ret.userType = userFB[FBUserManager.dbUserUsertype] as! String
            
            ret.iconImgUpdate = DateUtils.dateFromString(userFB[FBUserManager.dbUserIconimgupdate] as! String)
            
            self.imgM.downLoadImage(fullPath: self.imgM.getUserIconImgPath(userId: userId),callback: {(uiImage)->Void in
                self.userDM.saveImageIcon(userId: userId, uiImage: uiImage)
                self.delegateImg?.compIconImg(userId: userId)
            })
            
            ret.entryDate =  DateUtils.dateFromString(userFB[FBUserManager.dbUserIconimgupdate] as! String)
            if let status = userFB[FBUserManager.dbUserStatus] as? Int{
                ret.status = status
            }
            if let deleteDate = userFB[FBUserManager.dbUserDeleteDate] as? String {
                ret.deleteDate = DateUtils.dateFromString(deleteDate)
            }
            if let clinicName = userFB[FBUserManager.dbUserClinicName] as? String {
                ret.clinicName = clinicName
            }
            if let clinicAddress = userFB[FBUserManager.dbUserClinicAddress] as? String {
                ret.clinicAddress = clinicAddress
            }
            if let topImgUpdate = userFB[FBUserManager.dbUserTopimgupdate] as? String {
                ret.topImgUpdate = DateUtils.dateFromString(topImgUpdate)
                
                self.imgM.downLoadImage(fullPath: self.imgM.getUserTopImgPath(userId: userId),callback: {(uiImage)->Void in
                    self.userDM.saveImageTop(userId: userId, uiImage: uiImage)
                    self.delegateImg?.compTopImg(userId: userId)
                })
            }
            if let doctorId = userFB[FBUserManager.dbUserRequestdoctorid] as? String {
                ret.requestDoctorId = doctorId
            }
            
            var rooms:[String] = []
            
            // 自分のモデルだったらチャットルームまで作成
            if userId == self.userDM.getOwnUserId() {
                
                if let roomsFB = userFB[FBUserManager.dbUserRooms] as? NSDictionary {
                    // キーがルームID
                    for roomId in roomsFB.allKeys {
                            rooms.append(roomId as! String)
                            ret.chatRooms.append(roomId as! String)
                    }
                    
                    // 値が他者ユーザID
                    for roomId in ret.chatRooms {
                        let otherUserId = roomsFB[roomId] as! String
                        // 他者ユーザモデルが無かったらとりあえず作って後でゆっくりダウンロード
                        if self.realmM.getUserModelByUserId(userId: otherUserId) == nil {
                            self.realmM.insertUserTemp(otherUserId)
                            self.getData(otherUserId, callback: {(_) in})
                        }
                        
                        // チャットルームモデルのRealm保存
                        if self.realmM.getChatRoomModelByRoomId(roomId: roomId) == nil {
                           _ = self.realmM.insertUpdateChatRoom(roomId: roomId, userId: otherUserId)
                        }
                    }
                }
            }
            
            // Realm保存
            self.realmM.insertUpdateUser(userId: ret.userId, userType: ret.userType, name: ret.name, hira: ret.hira, tel: ret.tel, email: ret.email, clinicName: ret.clinicName, clinicAddress: ret.clinicAddress, rooms: rooms, requestDoctorId: ret.requestDoctorId, entryDate: ret.entryDate!,status:ret.status, deleteDate: ret.deleteDate)
            
            isFinish = true
            
            // 成功です！　変更監視とプッシュ通知用のトークン監視もしておきますね！
            callback("")
            
            if userId != self.userDM.getOwnUserId() {
                self.setObserver(userId)
            }
            else {
                // トピックにトークンを登録
                CommonUtils.getInstance().signInTockenToChat(false)
            }
        })
        
        // タイムアウト検知
        DispatchQueue.global().async() {
            let group = DispatchGroup()
            
            DispatchQueue.global().async(group:group) {
                while !isFinish {}
            }
            
            let time: DispatchTime = .now() + .seconds(10)
            if group.wait(timeout:time) == .timedOut {
                group.leave()
                group.notify(queue: .main) {
                    // タイムアウト時の処理
                    // ダウンロード失敗したので再試行できるようにする
                    for (indx, uid) in self.getDatas.enumerated() {
                        if uid == userId {
                            self.getDatas.remove(at: indx)
                            break
                        }
                    }
                    callback("タイムアウト")
                }
            }
        }
    }
    
    func setObserver(_ userId:String) {
        // 登録ずみなら何もしない
        if obserbers.keys.contains(userId) {
            return
        }
        
        // 更新されるたびに検知する
        obserbers[userId] = ref.child(userId).observe(.childChanged , with: {(snapshot) in
            let key = snapshot.key // キー
            let newMdl:UserModel! // 新モデル
            
            // データベースにあればそのクローンを使うし、なければダウンロードして終了
            if let mdl = self.realmM.getUserModelByUserId(userId: userId) {
                newMdl = mdl.copyModel()
            } else {
                self.getData(userId, callback:{(_) in})
                return
            }
            
            // 変更の可能性があるものだけ
            if key == FBUserManager.dbUserName {
                newMdl.name = snapshot.value as! String
            }
            else if key == FBUserManager.dbUserHira {
                newMdl.hira = snapshot.value as! String
            }
            else if key == FBUserManager.dbUserTel {
                newMdl.tel = snapshot.value as! String
            }
            else if key == FBUserManager.dbUserEmail {
                newMdl.email = snapshot.value as! String
            }
            else if key == FBUserManager.dbUserClinicName {
                newMdl.clinicName = snapshot.value as! String
            }
            else if key == FBUserManager.dbUserClinicAddress {
                newMdl.clinicAddress = snapshot.value as! String
            }
            else if key == FBUserManager.dbUserTopimgupdate {
                newMdl.topImgUpdate = DateUtils.dateFromString(snapshot.value as! String)
                // 画像ダウンロード
                self.imgM.downLoadImage(fullPath: self.imgM.getUserTopImgPath(userId: userId),callback: {(uiImage)->Void in
                    UserDefaultManager().saveImageTop(userId: userId, uiImage: uiImage)
                    self.delegateImg?.compTopImg(userId: userId)
                })
            }
            else if key == FBUserManager.dbUserIconimgupdate {
                newMdl.iconImgUpdate = DateUtils.dateFromString(snapshot.value as! String)
                // 画像ダウンロード
                self.imgM.downLoadImage(fullPath: self.imgM.getUserIconImgPath(userId: userId),callback: {(uiImage)->Void in
                    UserDefaultManager().saveImageIcon(userId: userId, uiImage: uiImage)
                    self.delegateImg?.compIconImg(userId: userId)
                })
            }
            else if key == FBUserManager.dbUserStatus {
                newMdl.status = snapshot.value as! Int
            }
            else if key == FBUserManager.dbUserDeleteDate {
                newMdl.deleteDate = DateUtils.dateFromString(snapshot.value as! String)
            }
            else if key == FBUserManager.dbUserRequestdoctorid {
                newMdl.requestDoctorId = snapshot.value as! String
            }
            
            // realm登録
            self.realmM.updateUser(newMdl)
            self.delegate?.userUpdated(userModel: newMdl)
            
        })
    }
    
    func resetGetDatas() {
        getDatas.removeAll()
    }
    func removeObserver(_ userId:String){
        for uid in obserbers.keys {
            if userId == uid {
                removeObs(userId)
                obserbers.removeValue(forKey: uid)
                break
            }
        }
    }
    
    func removeAllObserver(){
        for userId in obserbers.keys {
            removeObs(userId)
        }
        obserbers.removeAll()
    }
    
    func removeObs(_ userId:String) {
        // 登録していたら削除
        if let handle = obserbers[userId] {
            ref.child(userId).removeObserver(withHandle: handle)
        }
    }
    
    
    /// realtime databaseへのアップロード（初回）
    ///
    /// - Parameters:
    ///   - userId: userId
    ///   - userType: userType
    ///   - name: name
    ///   - hira: hira
    ///   - tel: tel
    ///   - email: email
    ///   - password: password
    ///   - clinicName: clinicName
    ///   - clinicAddress: clinicAddress
    func uploadUserAndDoctor(userId:String, userType:String, name:String, hira:String, tel:String, email:String, password:String, clinicName:String, clinicAddress:String) {
        
        var profile = Dictionary<String,Any>()
        profile[FBUserManager.dbUserName] = name
        profile[FBUserManager.dbUserHira] = hira
        profile[FBUserManager.dbUserTel] = tel
        profile[FBUserManager.dbUserEmail] = email
        profile[FBUserManager.dbUserUsertype] = userType
        profile[FBUserManager.dbUserEntryDate] = DateUtils.stringFromDate(Date())
        profile[FBUserManager.dbUserStatus] = Constant.statusRequest
        
        if userType == Constant.userTypeDoctor {
            profile[FBUserManager.dbUserClinicName] = clinicName
            profile[FBUserManager.dbUserClinicAddress] = clinicAddress
            
            // 医者情報にアップロード
            refDoc.child(userId).setValue(profile)
            
            profile[FBUserManager.dbUserTopimgupdate] = DateUtils.stringFromDate(Date())
            
            // デフォルトの予約種別を登録する
            FBRealTimeDataBaseManager.getInstance().insertDefaultKind()
            
        }
        
        profile[FBUserManager.dbUserIconimgupdate] = DateUtils.stringFromDate(Date())
        
        // ユーザ情報にアップロード
        ref.child(userId).setValue(profile)
    }
    
    
    /// realtime databaseへのアップロード 会員情報変更
    ///
    /// - Parameter userMdl: userMdl
    func updateUserAndDoctor(userMdl:UserModel){
        
        var profile = Dictionary<String,Any>()
        profile[FBUserManager.dbUserName] = userMdl.name
        profile[FBUserManager.dbUserHira] = userMdl.hira
        profile[FBUserManager.dbUserTel] = userMdl.tel
        profile[FBUserManager.dbUserEmail] = userMdl.email
        profile[FBUserManager.dbUserUsertype] = userMdl.userType
        profile[FBUserManager.dbUserEntryDate] = DateUtils.stringFromDate(userMdl.entryDate!)
        profile[FBUserManager.dbUserStatus] = userMdl.status
        
        if CommonUtils.isUserTypeDoctor() {
            profile[FBUserManager.dbUserClinicName] = userMdl.clinicName
            profile[FBUserManager.dbUserClinicAddress] = userMdl.clinicAddress
            
            // 医者情報にアップロード
            refDoc.child(userMdl.userId).updateChildValues(profile)
            profile[FBUserManager.dbUserTopimgupdate] = DateUtils.stringFromDate(Date())
            
        } else if CommonUtils.isUserTypeUser() {
            if let reqMdl = realmM.getRequestByCustomerId(customerId: userMdl.userId) {
                profile[FBUserManager.dbUserRequestdoctorid] = reqMdl.doctorId
            }
        }
        profile[FBUserManager.dbUserIconimgupdate] = DateUtils.stringFromDate(Date())
        
        if let chatRooms = RealmManager.getInstance().getChatRoomModels() {
            var rooms = Dictionary<String,String>()
            for chatRoom in chatRooms {
                rooms[chatRoom.roomId] = chatRoom.otherUser!.userId
            }
            profile[FBUserManager.dbUserRooms] = rooms
        }
        
        // ユーザ情報にアップロード
        ref.child(userMdl.userId).updateChildValues(profile)
    }
    
    
    func updateUserStatus(userId:String, status:Int) {
        ref.child(userId + "/" + FBUserManager.dbUserStatus).setValue(status)
        let mdl = realmM.getUserModelByUserId(userId: userId)!.copyModel()
        mdl.status = status
        realmM.updateUser(mdl)
    }
    
    func updateUserRequestDoctorId(_ doctorId:String){
        ref.child(userDM.getOwnUserId() + "/" + FBUserManager.dbUserRequestdoctorid).setValue(doctorId)
    }
    
    func updateUserRooms(_ roomId:String, ownId:String, otherId:String) {
        ref.child(ownId + "/" + FBUserManager.dbUserRooms + "/" + roomId).setValue(otherId)
        ref.child(otherId + "/" + FBUserManager.dbUserRooms + "/" + roomId).setValue(ownId)
    }
    
    
    
    /// 先生情報を全量取得する（ユーザのリクエスト準備）
    ///
    /// - Parameter callback: callback
    func downloadAndSaveRealmDoctorInfo(callback: @escaping (Bool,String)->Void) {
        let dispatchGroup = DispatchGroup()
        
        // 先生情報を初期化
        realmM.clearDoctorData()
        
        refDoc.observeSingleEvent(of: .value, with: { snapshot in
            if let doctors = snapshot.value as? NSDictionary {
                for (userId, _) in doctors {
                    let uid = userId as! String
                    dispatchGroup.enter()
                    DispatchQueue.main.async(group: dispatchGroup) {
                        self.getData(uid, callback: {(_) in
                            dispatchGroup.leave()
                        })
                    }
                }
            } else {
                callback(false, "医院情報が一件もありません")
            }
            
            dispatchGroup.notify(queue: .main) {
                callback(true, "")
            }
        })
    }
    
    func searchAndSaveRealmDoctorInfo(_ keyWord:String, callback: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        refDoc.observeSingleEvent(of: .value, with: { snapshot in
            if let doctors = snapshot.value as? NSDictionary {
                
                for (userId, doctor) in doctors {
                    let uid = userId as! String
                    let doctorInfo = doctor as! DataSnapshot
                    let clinicName = doctorInfo.childSnapshot(forPath: FBUserManager.dbDoctorClinicName).value as! String
                    let clinicAddress = doctorInfo.childSnapshot(forPath: FBUserManager.dbDoctorClinicAddress).value as! String
                    
                    if !clinicName.contains(keyWord) && !clinicAddress.contains(keyWord){
                        continue
                    }
                    
                    dispatchGroup.enter()
                    DispatchQueue.main.async(group: dispatchGroup) {
                        self.getData(uid, callback: {(_) in
                            dispatchGroup.leave()
                        })
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                callback()
            }
        })
    }
}

protocol FBUserManagerDelegate {
    func userUpdated(userModel:UserModel)
}

protocol FBUserManagerImageDelegate {
    func compTopImg(userId:String)
    func compIconImg(userId:String)
}
