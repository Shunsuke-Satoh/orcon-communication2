//
//  FBUserManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/05.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import Firebase

class FBRequestManager {
    static let dbRequest = "request"
    static let dbRequestRequestDate = "request_date"
    static let dbRequestIsConfirm = "is_Confirm"
    static let dbRequestConfirmDate = "confirm_date"
    
    private var ref: DatabaseReference!
    private let userDM: UserDefaultManager!
    private let imgM: FBStorageManager!
    private let realmM: RealmManager!
    
    private var getDatas:[String] = [] // ダウンロード試行済みのデータ
    private var obserbers = Dictionary<String, [UInt]>() // 登録済みのオブザーバ
    var delegate:FBRequestManagerDelegate? // デリゲート
    
    private static var own: FBRequestManager?
    
    private init(){
        ref = Database.database().reference().child(FBRequestManager.dbRequest)
        imgM = FBStorageManager()
        userDM = UserDefaultManager()
        realmM = RealmManager.getInstance()
    }
    
    static func getInstance() -> FBRequestManager{
        if own == nil {
            own = FBRequestManager.init()
        }
        return own!
    }
    
    func getData(_ doctorId:String, callback: @escaping (_ errorMsg:String) -> Void) {
        
        if CommonUtils.isUserTypeUser() {
            getRequest(doctorId: doctorId, customerId: userDM.getOwnUserId(), callback: {(errorMsg) in
                callback(errorMsg)
            })
        }
        else if CommonUtils.isUserTypeDoctor() {
            getRequestsByDoctorId(doctorId: userDM.getOwnUserId(), callback: {(errorMsg) in
                callback(errorMsg)
            })
        }
    }
    
    func getRequest(doctorId:String, customerId:String, callback: @escaping (_ errorMsg:String)->Void){
        
        // 未リクエストなら何もしない
        if doctorId == "" {
            callback("")
            return
        }
        
        // 試行ずみなら何もしない
        if getDatas.contains(doctorId) {
            callback("")
            return
        }
        
        var isFinish = false
        
        ref.child(doctorId + "/" + customerId).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.exists() {
                // Realm保存
                self.saveReqFromSnap(snapshot.value as! Dictionary, doctorId: doctorId, customerId: customerId)
            }
            isFinish = true
            // オブザーバも追加
            self.setRequestObserver(doctorId: doctorId, customerId: customerId)
            callback("")
        })
        
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
                    callback("タイムアウト")
                }
            }
        }
    }
    
    func getRequestsByDoctorId(doctorId:String, callback: @escaping (_ errorMsg:String)->Void){
        
        // 試行ずみなら何もしない
        if getDatas.contains(doctorId) {
            callback("")
            return
        }
        
        var isFinish = false
        ref.child(doctorId).observeSingleEvent(of: .value, with: {(snapshot) in
            if snapshot.exists() {
                let userRequests = snapshot.value as! NSDictionary
                for (customerId, reqFB) in userRequests {
                    // Realm保存
                    self.saveReqFromSnap(reqFB as! Dictionary<String,Any>, doctorId: doctorId, customerId: customerId as! String)
                }
            }
            isFinish = true
            callback("")
            // オブザーバも追加
            self.setRequestObserver(doctorId: doctorId, customerId: "")
        })
        
        
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
                    callback("タイムアウト")
                }
            }
        }
    }
    
    
    func setRequestObserver(doctorId:String, customerId:String) {
        // 登録ずみなら何もしない
        if obserbers.keys.contains(doctorId) {
            return
        }
        
        var localObs:[UInt] = []
        
        if CommonUtils.isUserTypeDoctor() {
            // リクエストが追加されるたびに検知するメソッドを追加
            localObs.append(ref.child(doctorId).observe(.childAdded, with: {snapshot in
                
                // realm保存
                self.saveReqFromSnap(snapshot.value as! Dictionary, doctorId: doctorId, customerId: snapshot.key)
                
                // 新規リクエストの場合はユーザ情報がないので取得
                FBUserManager.getInstance().getData(snapshot.key, callback: {(_) in
                })
                
                // デリゲート
                self.delegate?.requestInserted(reqModel: self.realmM.getRequestByCustomerId(customerId: snapshot.key)!)
                
                // バッジ更新
                CommonUtils.setBadge()
                
                // トピックにトークンを登録
                CommonUtils.getInstance().signInTockenToRequest(false)
            }))
            
            // リクエストが変更されるたびに検知するメソッドを追加
            localObs.append(ref.child(doctorId).observe(.childChanged, with: {snapshot in
                self.saveReqFromSnap(snapshot.value as! Dictionary, doctorId: doctorId, customerId: snapshot.key)
                
                // デリゲート
                self.delegate?.requestUpdated(reqModel: self.realmM.getRequestByCustomerId(customerId: snapshot.key)!)
                
                // バッジ更新
                CommonUtils.setBadge()
            }))
            
            // リクエストが削除されるたびに検知するメソッドを追加
            localObs.append(ref.child(doctorId).observe(.childRemoved, with: {snapshot in
                
                self.realmM.deleteRequest(customerId: snapshot.key)
                self.realmM.deleteUserModel(snapshot.key)
                
                // ユーザのリスナも消そうね
                FBUserManager.getInstance().removeObs(snapshot.key)
                
                // デリゲート
                self.delegate?.requestDeleted(doctorId: doctorId, customerId: snapshot.key)
                
                // バッジ更新
                CommonUtils.setBadge()
            }))
            
        }
            // カスタマーの時
        else {
            // リクエストの項目が追加されるたびに検知するメソッドを追加
            // 承認
            localObs.append(ref.child(doctorId + "/" + customerId).observe(.childAdded, with: {snapshot in
                
                let attr = snapshot.key
                if attr == FBRequestManager.dbRequestConfirmDate {
                    let confirmDate = DateUtils.dateFromString(snapshot.value as! String)
                    let base = self.realmM.getRequestByCustomerId(customerId: customerId)!
                    let req = base.copyModel()
                    
                    req.requestConfirmDate = confirmDate
                    _ = self.realmM.insertUpdateRequest(req)
                    // デリゲート
                    self.delegate?.requestUpdated(reqModel: req)
                    
                }
            }))
            // リクエストが変更されるたびに検知するメソッドを追加
            localObs.append(ref.child(doctorId + "/" + customerId).observe(.childChanged, with: {snapshot in
                
                let attr = snapshot.key
                if attr == FBRequestManager.dbRequestIsConfirm {
                    let isConf = snapshot.value as! Bool
                    let base = self.realmM.getRequestByCustomerId(customerId: customerId)!
                    let req = base.copyModel()
                    
                    req.requestConfirm = isConf
                    _ = self.realmM.insertUpdateRequest(req)
                    // デリゲート
                    self.delegate?.requestUpdated(reqModel:req)
                    
                }
            }))
            
            // リクエストが削除されるたびに検知するメソッドを追加
            localObs.append(ref.child(doctorId + "/" + customerId).observe(.childRemoved, with: {_ in
                
                if self.realmM.getRequestByCustomerId(customerId: customerId) != nil{
                    self.realmM.deleteRequest(customerId: customerId)
                    // デリゲート
                    self.delegate?.requestDeleted(doctorId: doctorId, customerId: customerId)
                }
                self.removeObs(doctorId)
            }))
        }
        
        // 登録済みに追加
        obserbers[doctorId] = localObs
    }
    
    func resetGetDatas() {
        getDatas.removeAll()
    }
    
    func removeAllObserver(){
        for doctorId in obserbers.keys {
            removeObs(doctorId)
        }
    }
    
    func removeObs(_ doctorId:String) {
        // 登録していたら削除
        if let handles = obserbers[doctorId] {
            for handle in handles {
                ref.child(doctorId).removeObserver(withHandle: handle)
            }
        }
        for (indx, id) in getDatas.enumerated() {
            if id == doctorId {
                getDatas.remove(at: indx)
                break
            }
        }
    }
    
    func saveReqFromSnap(_ dict:Dictionary<String,Any>
        , doctorId:String, customerId:String) {
        let mdl = RequestModel()
        let reqFBMdl = dict
        mdl.customerId = customerId
        mdl.doctorId = doctorId
        mdl.requestConfirm = reqFBMdl[FBRequestManager.dbRequestIsConfirm] as! Bool
        mdl.requestDate = DateUtils.dateFromString(reqFBMdl[FBRequestManager.dbRequestRequestDate] as! String)
        if let confirmDate = reqFBMdl[FBRequestManager.dbRequestConfirmDate] as? String {
            mdl.requestConfirmDate = DateUtils.dateFromString(confirmDate)
        }
        
        // realm保存
        self.realmM.insertRequest(customerId: mdl.customerId, doctorId: mdl.doctorId, requestDate: mdl.requestDate, isConfirm: mdl.requestConfirm, confirmDate: mdl.requestConfirmDate)
        
    }
    
    func uploadRequestFromCustomerToDoctor(doctorId:String) -> Void {
        var request = Dictionary<String,Any>()
        
        request[FBRequestManager.dbRequestIsConfirm] = false
        request[FBRequestManager.dbRequestRequestDate] = DateUtils.stringFromDate(Date())
        
        ref.child(doctorId + "/" + userDM.getOwnUserId()).setValue(request)
        
        FBUserManager.getInstance().updateUserRequestDoctorId(doctorId)
    }
    
    // 承認
    func updateRequestFromDoctorToCustomer(customerId:String){
        let ownId = userDM.getOwnUserId()
        // チャットルーム作成
        let roomId = ownId + "_" + DateUtils.stringFromDate(Date(), format: "yyyyMMdd_HHmmssSSS")
        
        // リクエスト更新
        ref.child(ownId + "/" + customerId + "/" + FBRequestManager.dbRequestIsConfirm).setValue(true)
        ref.child(ownId + "/" + customerId + "/" + FBRequestManager.dbRequestConfirmDate).setValue(DateUtils.stringFromDate(Date()))
        
        // ユーザ情報更新
        FBUserManager.getInstance().updateUserRooms(roomId, ownId:ownId, otherId: customerId)
        FBUserManager.getInstance().updateUserStatus(userId: customerId, status: Constant.statusTreat)
        
        // Realm更新
        realmM.insertChatRoom(roomId: roomId, userId: customerId)
        
        let custMdl = realmM.getUserModelByUserId(userId: customerId)!.copyModel()
        custMdl.status = Constant.statusTreat
        
        realmM.updateUser(custMdl)
        
        // チャットルームのリスナー登録
        ChatDataManager.getInstance().setObserverMsg(roomId)
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
        ref.child(doctorId + "/" + customerId).removeValue()
    }
    
}

protocol FBRequestManagerDelegate {
    func requestUpdated(reqModel:RequestModel)
    func requestInserted(reqModel:RequestModel)
    func requestDeleted(doctorId:String, customerId:String)
}
