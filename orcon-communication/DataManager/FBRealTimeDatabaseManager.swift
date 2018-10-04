//
//  FireBaseManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/21.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import Firebase

class FBRealTimeDataBaseManager {
    var ref: DatabaseReference!
    let imgM: FBStorageManager!
    
    var handlers:[UInt] = []
    var isAddObsReq = false // リクエストのオブザーバを登録したか
    var isAddObsSche = false // スケジュールのオブザーバを登録したか
    var isAddObsKind = false //種別のオブザーバを登録したか
    var isAddObsKindDetail = false //種別詳細のオブザーバを登録したか
    
    static var own: FBRealTimeDataBaseManager?
    
    private init(){
        ref = Database.database().reference()
        imgM = FBStorageManager()
    }
    
    static func getInstance() -> FBRealTimeDataBaseManager{
        if own == nil {
            own = FBRealTimeDataBaseManager.init()
        }
        return own!
    }
    
    func removeAllObserver(){
        ref.removeAllObservers()
        
    }
    
    func uploadToken() {
        ref.child(Constant.dbUser + "/" + UserDefaultManager().getOwnUserId() + "/" + Constant.dbUserToken).setValue(UserDefaultManager().getOwnToken())
    }
    
    func uploadMessage(roomId: String, messageModel:MessageModel){
        var message = Dictionary<String, Any>()
        
        // メッセージタイプ（テキスト・画像）
        message[Constant.dbMessageMsgType] = messageModel.messageType
        
        // メッセージ内容
        if messageModel.messageType == Constant.msgTypeText {
            message[Constant.dbMessageContents] = messageModel.contents
            
            // 画像メッセージの時はコンテンツにFireStorage上のフルパスを入れる
        } else if messageModel.messageType == Constant.msgTypeImage {
            message[Constant.dbMessageContents] = imgM.getMessagePath(roomId: roomId, message: messageModel)
        }
        // 登録日時
        message[Constant.dbMessageEntryDate] = DateUtils.stringFromDate(messageModel.entryDate)
        
        // 投稿者ユーザID
        message[Constant.dbMessageSenderUid] = messageModel.senderId
        
        // RealTimeDBにアップロード
        ref.child(Constant.dbMessage + "/" + roomId + "/" + messageModel.messageId).setValue(message)
    }
    
    func updateRead(roomId:String,messageModel:MessageModel){
        ref.child(Constant.dbMessage + "/" + roomId + "/" + messageModel.messageId + "/read").setValue(true)
    }
    
    
    func uploadUserAndDoctor(userId:String, userType:String, name:String, tel:String, email:String, password:String, clinicName:String, clinicAddress:String) {
        //----------
        // realtime databaseへのアップロード
        //----------
        var profile = Dictionary<String,String>()
        profile[Constant.dbUserName] = name
        profile[Constant.dbUserTel] = tel
        profile[Constant.dbUserEmail] = email
        profile[Constant.dbUserUsertype] = userType
        profile[Constant.dbUserEntryDate] = DateUtils.stringFromDate(Date())
        profile[Constant.dbUserStatus] = Constant.statusRequest.description
        if userType == Constant.userTypeDoctor {
            profile[Constant.dbUserClinicName] = clinicName
            profile[Constant.dbUserClinicAddress] = clinicAddress
            
            // 医者情報にアップロード
            ref.child(Constant.dbDoctor + "/" + userId).setValue(profile)
            
            profile[Constant.dbUserTopimgupdate] = DateUtils.stringFromDate(Date())
        }
        profile[Constant.dbUserIconimgupdate] = DateUtils.stringFromDate(Date())
        
        
        // ユーザ情報にアップロード
        ref.child(Constant.dbUser + "/" + userId).setValue(profile)
    }
    
    func updateUserAndDoctor(userMdl:UserModel){
        //----------
        // realtime databaseへのアップロード
        //----------
        var profile = Dictionary<String,Any>()
        profile[Constant.dbUserName] = userMdl.name
        profile[Constant.dbUserTel] = userMdl.tel
        profile[Constant.dbUserEmail] = userMdl.email
        profile[Constant.dbUserUsertype] = userMdl.userType
        profile[Constant.dbUserEntryDate] = DateUtils.stringFromDate(userMdl.entryDate!)
        profile[Constant.dbUserStatus] = userMdl.status
        
        if CommonUtils.isUserTypeDoctor() {
            profile[Constant.dbUserClinicName] = userMdl.clinicName
            profile[Constant.dbUserClinicAddress] = userMdl.clinicAddress
            
            // 医者情報にアップロード
            ref.child(Constant.dbDoctor + "/" + userMdl.userId).updateChildValues(profile)
            
            profile[Constant.dbUserTopimgupdate] = DateUtils.stringFromDate(Date())
        } else if CommonUtils.isUserTypeUser() {
            if let reqMdl = RealmManager.getInstance().getRequestByCustomerId(customerId: userMdl.userId) {
                profile[Constant.dbUserRequestdoctorid] = reqMdl.doctorId
            }
        }
        profile[Constant.dbUserIconimgupdate] = DateUtils.stringFromDate(Date())
        
        if let chatRooms = RealmManager.getInstance().getChatRoomModels() {
            var rooms = Dictionary<String,String>()
            for chatRoom in chatRooms {
                rooms[chatRoom.roomId] = chatRoom.otherUser!.userId
            }
            profile[Constant.dbUserRooms] = rooms
        }
        
        // ユーザ情報にアップロード
        ref.child(Constant.dbUser + "/" + userMdl.userId).updateChildValues(profile)
    }
    
    func downloadAndSaveRealmDoctorInfo(callback: @escaping (Bool,String)->Void) -> Void{
        let realmDM = RealmManager.getInstance()
        let dispatchGroup = DispatchGroup()
        
        // 先生情報を初期化
        realmDM.clearDoctorData()
        
        self.ref.child(Constant.dbDoctor).observeSingleEvent(of: .value, with: { snapshot in
            if let doctors = snapshot.value as? NSDictionary {
                for (userId, doctor) in doctors {
                    let uid = userId as! String
                    let doctorFB = doctor as! NSDictionary
                    let temp:[String] = []
                    
                    realmDM.insertUpdateUser(userId: uid, userType: Constant.userTypeDoctor, name: doctorFB[Constant.dbUserName] as! String, tel: doctorFB[Constant.dbUserTel] as! String, email: doctorFB[Constant.dbUserEmail] as! String, clinicName: doctorFB[Constant.dbUserClinicName] as! String, clinicAddress: doctorFB[Constant.dbUserClinicAddress] as! String, rooms: temp, requestDoctorId: "", entryDate: DateUtils.dateFromString(doctorFB[Constant.dbUserEntryDate] as! String), status:doctorFB[Constant.dbUserStatus] as! Int)
                    
                    
                    dispatchGroup.enter()
                    DispatchQueue.main.async(group: dispatchGroup) {
                        self.imgM.downLoadImage(fullPath: self.imgM.getUserTopImgPath(userId: uid), callback: {uiImage in
                            let userDM = UserDefaultManager()
                            userDM.saveImageTop(userId: uid, uiImage: uiImage)
                            dispatchGroup.leave()
                        })
                    }
                    
                    dispatchGroup.enter()
                    DispatchQueue.main.async(group: dispatchGroup) {
                        self.imgM.downLoadImage(fullPath: self.imgM.getUserIconImgPath(userId: uid), callback: {uiImage in
                            let userDM = UserDefaultManager()
                            userDM.saveImageIcon(userId: uid, uiImage: uiImage)
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
    
    func uploadRequestFromCustomerToDoctor(doctorId:String) -> Void {
        let userDM = UserDefaultManager()
        var request = Dictionary<String,Any>()
        
        request[Constant.dbRequestIsConfirm] = false
        request[Constant.dbRequestRequestDate] = DateUtils.stringFromDate(Date())
        
        ref.child(Constant.dbRequest + "/" + doctorId + "/" + userDM.getOwnUserId()).setValue(request)
        
        ref.child(Constant.dbUser + "/" + userDM.getOwnUserId() + "/" + Constant.dbUserRequestdoctorid).setValue(doctorId)
    }
    
    // 承認
    func updateRequestFromDoctorToCustomer(customerId:String){
        let ownId = UserDefaultManager().getOwnUserId()
        // チャットルーム作成
        let roomId = ownId + "_" + DateUtils.stringFromDate(Date(), format: "yyyyMMdd_HHmmssSSS")
        ref.child(Constant.dbUser  + "/" + customerId + "/" + Constant.dbUserRooms + "/" + roomId).setValue(ownId)
        ref.child(Constant.dbUser + "/" + ownId + "/" + Constant.dbUserRooms + "/" + roomId).setValue(customerId)
        
        // ユーザステータス更新
        ref.child(Constant.dbRequest + "/" + UserDefaultManager().getOwnUserId() + "/" + customerId + "/" + Constant.dbRequestIsConfirm).setValue(true)
        ref.child(Constant.dbRequest + "/" + UserDefaultManager().getOwnUserId() + "/" + customerId + "/" + Constant.dbRequestConfirmDate).setValue(DateUtils.stringFromDate(Date()))
        
        // ユーザステータス更新
        ref.child(Constant.dbUser + "/" + customerId + "/" + Constant.dbUserStatus).setValue(Constant.statusTreat)
        
        // Realm更新
        RealmManager.getInstance().insertChatRoom(roomId: roomId, userId: customerId)
        
        RealmManager.getInstance().updateUser(userId: customerId, status: Constant.statusTreat)
    }
    
    // 削除
    func deleteRequestFromDoctor(customerId:String){
        deleteRequest(doctorId: UserDefaultManager().getOwnUserId(), customerId: customerId)
    }
    // 削除
    func deleteRequestFromUser(doctorId:String){
        deleteRequest(doctorId: doctorId, customerId: UserDefaultManager().getOwnUserId())
    }
    // 削除共通
    func deleteRequest(doctorId:String, customerId:String){
        ref.child(Constant.dbRequest + "/" + doctorId + "/" + customerId).removeValue()
    }
    
    func downloadAllDataFromUserId(userId:String, callback: @escaping (Bool,String)->Void) -> Void {
        // 0.realmデータベースを初期化
        RealmManager.getInstance().clearAllData()

        
        let dispatchGroup = DispatchGroup()
        
        // 1.自身のユーザ情報を取得
        getUserByUserId(userId: userId, callback: { userMdl, requestDoctorId, error in
            print("req="+requestDoctorId)
            if error != "" {
                callback(false, error) // ユーザ情報取得失敗
            }
            
            if userMdl.userId == "" {
                callback(false,"自身のユーザ情報がありません[userId=" + userMdl.userId + "]") // ユーザ情報取得失敗
            }
            
            // ユーザタイプの保存
            let userDM = UserDefaultManager()
            userDM.setOwnUserType(userType: userMdl.userType)
            
            // 2-1.カスタマーだった場合 リクエストしていない場合はスキップ
            if userMdl.userType == Constant.userTypeCustomer && requestDoctorId != ""{
                dispatchGroup.enter()
                DispatchQueue.main.async(group: dispatchGroup) {
                    // 2-1-1.自身に関わるリクエスト情報を1件取得
                    self.getRequest(doctorId: requestDoctorId, customerId: userMdl.userId, callback: { (reqMdl, error) in
                        
                        if error != "" {
                            callback(false,error) // リクエスト情報取得失敗
                            dispatchGroup.leave()
                            return
                        }
                        
                        if reqMdl.customerId == "" {
                            callback(false,"リクエストがありません[userId=" + userMdl.userId + "]") // リクエスト情報取得失敗
                            dispatchGroup.leave()
                            return
                        }
                        
                        // 2-1-2.リクエスト先の医院情報を1件取得
                        self.getUserByUserId(userId: reqMdl.doctorId, callback: {
                            (doctorMdl, gomi, error) in
                            if error != "" {
                                callback(false, error) // 医院情報取得失敗
                            }else if doctorMdl.userId == "" {
                                callback(false,"リクエスト先の医院情報がありません[userId=" + userId + "]" ) // 医院情報取得失敗
                            }
                            dispatchGroup.leave() // 正常終了
                        })
                        
                    })
                }
                
            }
                // 2-2.医院だった場合
            else if userMdl.userType == Constant.userTypeDoctor {
                
                dispatchGroup.enter()
                DispatchQueue.global().async(group: dispatchGroup) {
                    // 2-2-1.自身のリクエスト情報を全て取得
                    self.getRequestsByDoctorId(doctorId: userMdl.userId, callback:{(reqMdls, error) in
                        if error != "" {
                            callback(false,error) // リクエスト情報取得失敗
                            dispatchGroup.leave()
                            return
                        }
                        // 2-2-2.リクエスト元のカスタマー情報を全て取得
                        for reqMdl in reqMdls {
                            self.getUserByUserId(userId: reqMdl.customerId, callback: { (customerMdl, gomi, error) in
                                if error != "" {
                                    callback(false, error) // カスタマー情報取得失敗
                                    dispatchGroup.leave()
                                    return
                                }
                                
                                if customerMdl.userId == "" {
                                    callback(false,"リクエスト元のカスタマー情報がありません[userId=" + reqMdl.customerId + "]" ) // カスタマー情報取得失敗
                                    dispatchGroup.leave()
                                    return
                                }
                            })
                        }
                        dispatchGroup.leave()
                    })
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // 2-3.チャットルームのメッセージ情報を全て取得
                ChatDataManager().getDataFromDB()
                
                // 2-4.スケジュール情報を取得
                self.setScheduleObserver()
                self.setKindObserver()
                self.setKindDetailObserver()
                callback(true, "")
            }
        })
    }
    
    
    func getRequest(doctorId:String, customerId:String, callback: @escaping (RequestModel, _ error:String)->Void){
        let ret = RequestModel()
        var isFinish = false
        
        ref.child(Constant.dbRequest + "/" + doctorId + "/" + customerId).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.exists() {
                // みつかった
                let reqFBModel = snapshot.value as! NSDictionary
                
                ret.customerId = customerId
                ret.doctorId = doctorId
                ret.requestConfirm = reqFBModel[Constant.dbRequestIsConfirm] as! Bool
                ret.requestDate = DateUtils.dateFromString(reqFBModel[Constant.dbRequestRequestDate] as! String)
                
                if ret.requestConfirm {
                    ret.requestConfirmDate = DateUtils.dateFromString(reqFBModel[Constant.dbRequestConfirmDate] as! String)
                }
                _ = RealmManager.getInstance().insertUpdateRequest(ret)
            }
            isFinish = true
            callback(ret, "")
        })
        
        DispatchQueue.global().async() {
            let group = DispatchGroup()
            
            DispatchQueue.global().async(group:group) {
                while !isFinish {}
            }
            
            let time: DispatchTime = .now() + .seconds(10)
            if group.wait(timeout:time) == .timedOut {
                print("timeout" + #function)
                group.leave()
                group.notify(queue: .main) {
                    // タイムアウト時の処理
                    callback(ret,"タイムアウト")
                }
            }
        }
    }
    
    func getRequestsByDoctorId(doctorId:String, callback: @escaping ([RequestModel], _ error:String)->Void){
        var ret :[RequestModel] = []
        
        var isFinish = false
        ref.child(Constant.dbRequest + "/" + doctorId).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.exists() {
                let userRequests = snapshot.value as! NSDictionary
                for (customerId, reqFB) in userRequests {
                    let requestModel = RequestModel()
                    let reqFBMdl = reqFB as! NSDictionary
                    requestModel.customerId = customerId as! String
                    requestModel.doctorId = doctorId
                    requestModel.requestConfirm = reqFBMdl[Constant.dbRequestIsConfirm] as! Bool
                    requestModel.requestDate = DateUtils.dateFromString(reqFBMdl[Constant.dbRequestRequestDate] as! String)
                    if requestModel.requestConfirm {
                        requestModel.requestConfirmDate = DateUtils.dateFromString(reqFBMdl[Constant.dbRequestConfirmDate] as! String)
                    }
                    
                    // realm保存
                    _ = RealmManager.getInstance().insertUpdateRequest(requestModel)
                    
                    ret.append(requestModel)
                }
            }
            isFinish = true
            callback(ret, "")
        })
        
        
        DispatchQueue.global().async() {
            let group = DispatchGroup()
            
            DispatchQueue.global().async(group:group) {
                while !isFinish {}
            }
            
            let time: DispatchTime = .now() + .seconds(10)
            if group.wait(timeout:time) == .timedOut {
                print("timeout" + #function)
                group.leave()
                group.notify(queue: .main) {
                    // タイムアウト時の処理
                    callback(ret,"タイムアウト")
                }
            }
        }
    }
    
    func getUserByUserId(userId:String, callback: @escaping (UserModel, _ requestDoctorId:String, _ error:String)->Void){
        print(#function)
        let ret :UserModel = UserModel()
        var isFinish = false
        
        ref.child(Constant.dbUser + "/" + userId).observeSingleEvent(of: .value, with: {(snapshot) in
            
            let imgMG = FBStorageManager()
            var requestDoctorId = ""
            
            if snapshot.exists() {
                // 見つかった
                let userFB = snapshot.value as! NSDictionary
                ret.userId = userId
                ret.name = userFB[Constant.dbUserName] as! String
                ret.tel = userFB[Constant.dbUserTel] as! String
                ret.email = userFB[Constant.dbUserEmail] as! String
                ret.userType = userFB[Constant.dbUserUsertype] as! String
                ret.iconImgUpdate = DateUtils.dateFromString(userFB[Constant.dbUserIconimgupdate] as! String)
                ret.entryDate =  DateUtils.dateFromString(userFB[Constant.dbUserIconimgupdate] as! String)
                if let status = userFB[Constant.dbUserStatus] as? Int{
                    ret.status = status
                }
                
                if ret.userType == Constant.userTypeDoctor {
                    ret.clinicName = userFB[Constant.dbUserClinicName] as! String
                    ret.clinicAddress = userFB[Constant.dbUserClinicAddress] as! String
                    ret.topImgUpdate = DateUtils.dateFromString(userFB[Constant.dbUserTopimgupdate] as! String)
                    imgMG.downLoadImage(fullPath: imgMG.getUserTopImgPath(userId: userId),callback: {(uiImage)->Void in
                        UserDefaultManager().saveImageTop(userId: userId, uiImage: uiImage)
                    })
                } else if ret.userType == Constant.userTypeCustomer {
                    requestDoctorId = userFB[Constant.dbUserRequestdoctorid] as? String ?? ""
                }
                
                imgMG.downLoadImage(fullPath: imgMG.getUserIconImgPath(userId: userId),callback: {(uiImage)->Void in
                    UserDefaultManager().saveImageIcon(userId: userId, uiImage: uiImage)
                })
                
                var rooms:[String] = []
                if let roomsFB = userFB[Constant.dbUserRooms] as? NSDictionary {
                    for roomId in roomsFB.allKeys {
                        rooms.append(roomId as! String)
                        ret.chatRooms.append(roomId as! String)
                    }
                }
                
                // Realm保存
                RealmManager.getInstance().insertUpdateUser(userId: ret.userId, userType: ret.userType, name: ret.name, tel: ret.tel, email: ret.email, clinicName: ret.clinicName, clinicAddress: ret.clinicAddress, rooms: rooms, requestDoctorId: requestDoctorId, entryDate: ret.entryDate!,status:ret.status)
                
            }
            isFinish = true
            callback(ret, requestDoctorId, "")
        })
        
        DispatchQueue.global().async() {
            let group = DispatchGroup()
            
            DispatchQueue.global().async(group:group) {
                while !isFinish {}
            }
            
            let time: DispatchTime = .now() + .seconds(10)
            if group.wait(timeout:time) == .timedOut {
                print("timeout" + #function)
                group.leave()
                group.notify(queue: .main) {
                    // タイムアウト時の処理
                    callback(UserModel(),"","タイムアウト")
                }
            }
        }
    }
    
//    ref.child(Constant.dbMessage + "/" + roomId).queryOrdered(byChild: Constant.dbMessageEntryDate).queryLimited(toLast: 100).observeSingleEvent
//    
    
    
    func updateUserStatus(userId:String, status:Int) {
        ref.child(Constant.dbUserStatus + "/" + userId + "/" + Constant.dbUserStatus).setValue(status.description)
        
        RealmManager.getInstance().updateUser(userId: userId, status: status)
    }
    
    // 医者しか呼び出さない
    func deleteKind(_ kindMdl:CalKindModel){
        // 種別を破棄
        ref.child("calendarKind/" + kindMdl.doctorId + "/" + kindMdl.kindId).removeValue()
    }
    
    // 医者しか呼び出さない
    func deleteKindDetail(id:String) {
        ref.child("calendarKindDetail/" + UserDefaultManager().getOwnUserId() + "/" + id).removeValue()
    }
    
    // 医者しか呼び出さない
    func updateKind(_ kindMdl:CalKindModel){
        // 登録用の種別FBデータを作る
        var FBkind = Dictionary<String, Any>()
        
        FBkind["kindNum"] = kindMdl.kindNum
        FBkind["color_r"] = kindMdl.color_r
        FBkind["color_g"] = kindMdl.color_g
        FBkind["color_b"] = kindMdl.color_b
        FBkind["allCloseFlg"] = kindMdl.allCloseFlg
        FBkind["closeFlg"] = kindMdl.closeFlg
        
        for op in kindMdl.open {
            FBkind[op.kindId_openclose_num] = true
        }
        for cl in kindMdl.close {
            FBkind[cl.kindId_openclose_num] = true
        }
        
        ref.child("calendarKind/" + kindMdl.doctorId + "/" + kindMdl.kindId).updateChildValues(FBkind)
    }
    
    // 医者しか呼び出さない
    func updateKindDetail(_ kindDetailMdl:CalKindOpenCloseModel){
        var FBopcl = Dictionary<String, Any>()
        FBopcl["opencloseType"] = kindDetailMdl.opencloseType
        FBopcl["num"] = kindDetailMdl.num
        FBopcl["StartHHmm"] = kindDetailMdl.StartHHmm
        FBopcl["EndHHmm"] = kindDetailMdl.EndHHmm
        
        ref.child("calendarKindDetail/" + UserDefaultManager().getOwnUserId() + "/" + kindDetailMdl.kindId_openclose_num).updateChildValues(FBopcl)
    }
    
    // 医者しか呼び出さない
    func updateSchedule(_ mdl:ScheduledDateModel){
        // アップデート
        ref.child("schedule/" + mdl.doctorId + "/" + mdl.id_yyyymmdd + "/kindId").setValue(mdl.kindId)
    }
    
    // 医者しか呼び出さない
    func deleteSchedule(_ mdl:ScheduledDateModel){
        // アップデート
        ref.child("schedule/" + mdl.doctorId + "/" + mdl.id_yyyymmdd).removeValue()
    }
    
    func setScheduleObserver() {
        // 登録ずみなら何もしない
        if isAddObsSche {
            return
        }
        
//        // 医者は自分でハンドリングするのでつけない
//        if CommonUtils.isUserTypeDoctor(){
//            return
//        }
        
        var customerId = ""
        var doctorId = ""
        
        let realmDM = RealmManager.getInstance()
        
        if CommonUtils.isUserTypeUser(){
            customerId = UserDefaultManager().getOwnUserId()
            if let reqMdl = realmDM.getRequestByCustomerId(customerId: customerId){
                doctorId = reqMdl.doctorId
            }
            
        } else {
            doctorId = UserDefaultManager().getOwnUserId()
        }
        
        if doctorId == "" {
            return
        }
        
        let path = "schedule/" + doctorId
        
        // スケジュールが追加されるたびに検知する
        handlers.append(ref.child(path).observe(.childAdded, with: {snapshot in
            let yyyymmdd = snapshot.key
            let kindId = snapshot.childSnapshot(forPath: "kindId").value as! String
            
            let realmDM = RealmManager.getInstance()
            let mdl = ScheduledDateModel()
            
            mdl.id_yyyymmdd = yyyymmdd
            mdl.date = DateUtils.dateFromString(yyyymmdd, format: "YYYYMMdd")
            mdl.doctorId = doctorId
            mdl.kindId = kindId
            if let kind = realmDM.getKind(kindId: kindId) {
                mdl.kind = kind
            } else {
                let tempKind = CalKindModel()
                tempKind.kindId = kindId
                mdl.kind = tempKind
            }
            realmDM.updateInsertScheduleModel(mdl)
        }))
        
        // スケジュールが更新される度に検知する
        handlers.append(ref.child(path).observe(.childChanged, with: {snapshot in
            let yyyymmdd = snapshot.key
            let kindId = snapshot.childSnapshot(forPath: "kindId").value as! String
            
            let realmDM = RealmManager.getInstance()
            let mdl = ScheduledDateModel()
            
            mdl.id_yyyymmdd = yyyymmdd
            mdl.date = DateUtils.dateFromString(yyyymmdd, format: "YYYYMMdd")
            mdl.doctorId = doctorId
            mdl.kindId = kindId
            if let kind = realmDM.getKind(kindId: kindId) {
                mdl.kind = kind
            } else {
                let tempKind = CalKindModel()
                tempKind.kindId = kindId
                mdl.kind = tempKind
            }
            realmDM.updateInsertScheduleModel(mdl)
        }))
        
        // スケジュールが削除される度に検知する
        handlers.append(ref.child(path).observe(.childRemoved, with: {snapshot in
            let yyyymmdd = snapshot.key
            
            let realmDM = RealmManager.getInstance()
            realmDM.deleteScheduleModel(yyyymmdd)
        }))
        
        isAddObsSche = true
    }
    
    func setKindObserver() {
        // 登録ずみなら何もしない
        if isAddObsKind {
            return
        }
        
        // 医者は自分でハンドリングするのでつけない
//        if CommonUtils.isUserTypeDoctor(){
//            return
//        }
        
        
        var customerId = ""
        var doctorId = ""
        
        let realmDM = RealmManager.getInstance()
        
        if CommonUtils.isUserTypeUser(){
            customerId = UserDefaultManager().getOwnUserId()
            if let reqMdl = realmDM.getRequestByCustomerId(customerId: customerId){
                doctorId = reqMdl.doctorId
            }
            
        } else {
            doctorId = UserDefaultManager().getOwnUserId()
        }
        
        if doctorId == "" {
            return
        }
            
        // 種別が追加されるたびに検知する
        let path = "calendarKind/" + doctorId
        
        handlers.append(ref.child(path).observe(.childAdded, with: {snapshot in
            self.updateKindForUser(snapshot, doctorId)
        }))
        // 種別が更新される度に検知する
        handlers.append(ref.child(path).observe(.childChanged, with: {snapshot in
            self.updateKindForUser(snapshot, doctorId)
        }))
        
        // 種別が削除される度に検知する
        handlers.append(ref.child(path).observe(.childRemoved, with: {snapshot in
            let kindId = snapshot.key
            realmDM.deleteKind(kindId: kindId)
        }))
        
        isAddObsKind = true
    }
    
    func updateKindForUser(_ snapshot:DataSnapshot, _ doctorId:String) {
        let kindId = snapshot.key
        let allCloseFlg = snapshot.childSnapshot(forPath: "allCloseFlg").value as! Bool
        let closeFlg = snapshot.childSnapshot(forPath: "closeFlg").value as! Bool
        
        let color_r = snapshot.childSnapshot(forPath: "color_r").value as! CGFloat
        let color_g = snapshot.childSnapshot(forPath: "color_g").value as! CGFloat
        let color_b = snapshot.childSnapshot(forPath: "color_b").value as! CGFloat
        let kindNum = snapshot.childSnapshot(forPath: "kindNum").value as! Int
        
        var opens:[String] = []
        var closes:[String] = []
        for (_,val) in snapshot.children.enumerated() {
            let snap = val as! DataSnapshot
            let keyName = snap.key
            if keyName.starts(with:kindId + "_open") {
                opens.append(keyName)
            } else if keyName.starts(with:kindId + "_close") {
                closes.append(keyName)
            }
        }
        
        let realmDM = RealmManager.getInstance()
        let mdl = CalKindModel()
        mdl.doctorId = doctorId
        mdl.kindId = kindId
        mdl.kindNum = kindNum
        mdl.color_r = color_r
        mdl.color_g = color_g
        mdl.color_b = color_b
        mdl.allCloseFlg = allCloseFlg
        mdl.closeFlg = closeFlg
        
        for op in opens {
            if let ret = realmDM.getKindDetail(op) {
                mdl.open.append(ret)
            } else {
                let opclMdl = CalKindOpenCloseModel()
                opclMdl.kindId_openclose_num = op
                mdl.open.append(opclMdl)
            }
        }
        
        for cl in closes {
            if let ret = realmDM.getKindDetail(cl) {
                mdl.close.append(ret)
            } else {
                let opclMdl = CalKindOpenCloseModel()
                opclMdl.kindId_openclose_num = cl
                mdl.close.append(opclMdl)
            }
        }
        
        realmDM.insertKind(mdl)
    }
    
    func setKindDetailObserver() {
        // 登録ずみなら何もしない
        if isAddObsKindDetail {
            return
        }
        
        var customerId = ""
        var doctorId = ""
        
        let realmDM = RealmManager.getInstance()
        
        if CommonUtils.isUserTypeUser(){
            customerId = UserDefaultManager().getOwnUserId()
            if let reqMdl = realmDM.getRequestByCustomerId(customerId: customerId){
                doctorId = reqMdl.doctorId
            }
            
        } else {
            doctorId = UserDefaultManager().getOwnUserId()
        }
        
        if doctorId == "" {
            return
        }
            
        // 種別詳細が追加されるたびに検知する
        let path = "calendarKindDetail/" + doctorId
        
        handlers.append(ref.child(path).observe(.childAdded, with: {snapshot in
            let kindDetailKey = snapshot.key
            let startHHmm = snapshot.childSnapshot(forPath: "StartHHmm").value as! String
            let endHHmm = snapshot.childSnapshot(forPath: "EndHHmm").value as! String
            let num = snapshot.childSnapshot(forPath: "num").value as! Int
            let opencloseType = snapshot.childSnapshot(forPath: "opencloseType").value as! String
            
            let mdl = CalKindOpenCloseModel()
            mdl.kindId_openclose_num = kindDetailKey
            mdl.StartHHmm = startHHmm
            mdl.EndHHmm = endHHmm
            mdl.num = num
            mdl.opencloseType = opencloseType
            
            RealmManager.getInstance().insertUpdateKindDetail(mdl)
        }))
        // 種別詳細が更新される度に検知する
        handlers.append(ref.child(path).observe(.childChanged, with: {snapshot in
            let kindDetailKey = snapshot.key
            let startHHmm = snapshot.childSnapshot(forPath: "StartHHmm").value as! String
            let endHHmm = snapshot.childSnapshot(forPath: "EndHHmm").value as! String
            let num = snapshot.childSnapshot(forPath: "num").value as! Int
            let opencloseType = snapshot.childSnapshot(forPath: "opencloseType").value as! String
            
            let mdl = CalKindOpenCloseModel()
            mdl.kindId_openclose_num = kindDetailKey
            mdl.StartHHmm = startHHmm
            mdl.EndHHmm = endHHmm
            mdl.num = num
            mdl.opencloseType = opencloseType
            
            RealmManager.getInstance().insertUpdateKindDetail(mdl)
        }))
        
        // 種別詳細が削除される度に検知する
        handlers.append(ref.child(path).observe(.childRemoved, with: {snapshot in
            let kindDetailKey = snapshot.key
            
            RealmManager.getInstance().deleteKindDetail(kindDetailKey)
        }))
        
        isAddObsKindDetail = true
    }
    
    func removeScheduleKindDetailObserves() {
        
        for handle in handlers {
            ref.removeObserver(withHandle: handle)
        }
        isAddObsSche = false
        isAddObsKind = false
        isAddObsKindDetail = false
    }
}
