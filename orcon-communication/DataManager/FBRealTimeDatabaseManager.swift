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
    
    func downloadAllDataFromUserId(userId:String, callback: @escaping (Bool,String)->Void) -> Void {
        // realmデータベースを初期化
        RealmManager.getInstance().clearAllData()

        ChatDataManager.getInstance().getDataFromDB(callback: {(errorMsg) in
            // 失敗
            if errorMsg != "" {
                callback(false,errorMsg)
                return
            }
            
            // 成功
            self.setScheduleObserver()
            self.setKindObserver()
            self.setKindDetailObserver()
            callback(true, "")
        })
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
                if kindId != "" {
                    let tempKind = CalKindModel()
                    tempKind.kindId = kindId
                    mdl.kind = tempKind
                }
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
                if kindId != "" {
                    let tempKind = CalKindModel()
                    tempKind.kindId = kindId
                    mdl.kind = tempKind
                }
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
        if kindId == "" {
            return
        }
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
        
        realmDM.insertUpdateKind(mdl)
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
    
    // RealmとFirebaseにデフォルト種別登録 医者しか呼ばれない
    func insertDefaultKind() {
        let calKindMdl1 = CalKindModel()
        calKindMdl1.kindId = UUID().uuidString
        calKindMdl1.kindNum = 1
        calKindMdl1.doctorId = UserDefaultManager().getOwnUserId()
        calKindMdl1.allCloseFlg = false
        
        // 青
        calKindMdl1.color_r = 55/255
        calKindMdl1.color_g = 114/255
        calKindMdl1.color_b = 255/255
        calKindMdl1.closeFlg = true
        
        let kindOPMdl1 = CalKindOpenCloseModel()
        kindOPMdl1.opencloseType = "open"
        kindOPMdl1.num = 0
        kindOPMdl1.kindId_openclose_num = calKindMdl1.kindId + "_" + "open_" + kindOPMdl1.num.description
        kindOPMdl1.StartHHmm = String("09:00")
        kindOPMdl1.EndHHmm = String("17:00")
        calKindMdl1.open.append(kindOPMdl1)
        
        let kindCLMdl1 = CalKindOpenCloseModel()
        kindCLMdl1.opencloseType = "close"
        kindCLMdl1.num = 0
        kindCLMdl1.kindId_openclose_num = calKindMdl1.kindId + "_" + "close_" + kindCLMdl1.num.description
        kindCLMdl1.StartHHmm = String("12:00")
        kindCLMdl1.EndHHmm = String("13:00")
        calKindMdl1.close.append(kindCLMdl1)
        
        let calKindMdl2 = CalKindModel()
        calKindMdl2.kindId = UUID().uuidString
        calKindMdl2.kindNum = 2
        calKindMdl2.doctorId = UserDefaultManager().getOwnUserId()
        calKindMdl2.allCloseFlg = false
        // 緑
        calKindMdl2.color_r = 162/255
        calKindMdl2.color_g = 255/255
        calKindMdl2.color_b = 163/255
        calKindMdl2.closeFlg = false
        
        let kindOPMdl2 = CalKindOpenCloseModel()
        kindOPMdl2.opencloseType = "open"
        kindOPMdl2.num = 0
        kindOPMdl2.kindId_openclose_num = calKindMdl2.kindId + "_" + "open_" + kindOPMdl2.num.description
        kindOPMdl2.StartHHmm = String("09:00")
        kindOPMdl2.EndHHmm = String("12:00")
        calKindMdl2.open.append(kindOPMdl2)
        
        let calKindMdl3 = CalKindModel()
        calKindMdl3.kindId = UUID().uuidString
        calKindMdl3.kindNum = 3
        calKindMdl3.doctorId = UserDefaultManager().getOwnUserId()
        calKindMdl3.allCloseFlg = false
        // 黄
        calKindMdl3.color_r = 255/255
        calKindMdl3.color_g = 253/255
        calKindMdl3.color_b = 152/255
        calKindMdl3.closeFlg = false
        
        let kindOPMdl3 = CalKindOpenCloseModel()
        kindOPMdl3.opencloseType = "open"
        kindOPMdl3.num = 0
        kindOPMdl3.kindId_openclose_num = calKindMdl3.kindId + "_" + "open_" + kindOPMdl3.num.description
        kindOPMdl3.StartHHmm = String("13:00")
        kindOPMdl3.EndHHmm = String("17:00")
        calKindMdl3.open.append(kindOPMdl3)
        
        
        let calKindMdl4 = CalKindModel()
        calKindMdl4.kindId = UUID().uuidString
        calKindMdl4.kindNum = 4
        calKindMdl4.doctorId = UserDefaultManager().getOwnUserId()
        calKindMdl4.allCloseFlg = true
        // 茶
        calKindMdl4.color_r = 244/255
        calKindMdl4.color_g = 85/255
        calKindMdl4.color_b = 85/255
        calKindMdl4.closeFlg = true
        
        // 登録
        let realmM = RealmManager.getInstance()
        realmM.insertUpdateKind(calKindMdl1)
        realmM.insertUpdateKind(calKindMdl2)
        realmM.insertUpdateKind(calKindMdl3)
        realmM.insertUpdateKind(calKindMdl4)
    }
}
