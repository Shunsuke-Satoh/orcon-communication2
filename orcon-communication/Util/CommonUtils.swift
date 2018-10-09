//
//  CommonUtils.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/25.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import Firebase

class CommonUtils {
    private static var own: CommonUtils?
    
    private var topics:[String] = [] // トピックパス
    
    private init() {
    }
    
    static func getInstance() -> CommonUtils{
        if own == nil {
            own = CommonUtils.init()
        }
        return own!
    }
    
    
    static func isUserTypeDoctor() -> Bool {
        var ret = false
        if UserDefaultManager().getOwnUserType() == Constant.userTypeDoctor {
            ret = true
        }
        return ret
    }
    static func isUserTypeUser() -> Bool {
        var ret = false
        if UserDefaultManager().getOwnUserType() == Constant.userTypeCustomer {
            ret = true
        }
        return ret
    }
    
    static func uiColor(_ kindMdl:CalKindModel) -> UIColor{
        return UIColor(red: kindMdl.color_r, green: kindMdl.color_g, blue: kindMdl.color_b, alpha: 1)
    }
    
    static func hh_mm(_ hhmm: String) -> String{
        let hh = hhmm.prefix(2)
        let mm = hhmm.suffix(2)
        return hh + ":" + mm
    }
    
    static func getChatTopicName(roomId:String) -> String {
        var topicName = ""
        if let room = RealmManager.getInstance().getChatRoomModelByRoomId(roomId: roomId) {
            
            if isUserTypeUser() {
                topicName = "chat_" + (room.otherUser?.userId)! + UserDefaultManager().getOwnUserId()
            } else if isUserTypeDoctor() {
                topicName = "chat_" + UserDefaultManager().getOwnUserId() + (room.otherUser?.userId)!
            }
        }
        
        return topicName
    }
    
    func signInTockenToChat(_ isNewToken:Bool) {
        if UserDefaultManager().getOwnToken() == "" {
            return
        }
        
        if let rooms = RealmManager.getInstance().getChatRoomModels() {
            for room in rooms {
                let topicName = CommonUtils.getChatTopicName(roomId: room.roomId)
                if Messaging.messaging().fcmToken != nil {
                    // 既にトピック参加していないか？
                    if topics.contains(topicName) {
                        if isNewToken {
                            Messaging.messaging().subscribe(toTopic: topicName)
                        }
                    } else {
                        Messaging.messaging().subscribe(toTopic: topicName)
                        topics.append(topicName)
                    }
                }
            }
        }
    }
    
    static func getReqTopicName(doctorId:String, customerId:String) -> String {
        
        return "req_" + doctorId + customerId
    }
    
    static func getReqDoctorTopicName(doctorId:String) -> String {
        
        return "reqDoc_" + doctorId
    }
    
    func signInTockenToRequest(_ isNewToken:Bool) {
        if UserDefaultManager().getOwnToken() == "" {
            return
        }
        
        if CommonUtils.isUserTypeUser() {
            if let req = RealmManager.getInstance().getRequestByCustomerId(customerId: UserDefaultManager().getOwnUserId()) {
                
                let topicName = CommonUtils.getReqTopicName(doctorId: req.doctorId, customerId:req.customerId)
                // 既にトピック参加していないか？
                if topics.contains(topicName) {
                    if isNewToken {
                        Messaging.messaging().subscribe(toTopic: topicName)
                    }
                } else {
                    Messaging.messaging().subscribe(toTopic: topicName)
                    topics.append(topicName)
                }
            }
        } else if CommonUtils.isUserTypeDoctor() {
            let reqs = RealmManager.getInstance().getRequestsByDoctorId(doctorId: UserDefaultManager().getOwnUserId())
            
            for req in reqs {
                let topicName = CommonUtils.getReqTopicName(doctorId: req.doctorId, customerId:req.customerId)
                // 既にトピック参加していないか？
                if topics.contains(topicName) {
                    if isNewToken {
                        Messaging.messaging().subscribe(toTopic: topicName)
                    }
                } else {
                    Messaging.messaging().subscribe(toTopic: topicName)
                    topics.append(topicName)
                }
            }
            
            // 自分自身のトピックにも加入
            let topicName = CommonUtils.getReqDoctorTopicName(doctorId: UserDefaultManager().getOwnUserId())
            // 既にトピック参加していないか？
            if topics.contains(topicName) {
                if isNewToken {
                    Messaging.messaging().subscribe(toTopic: topicName)
                }
            } else {
                Messaging.messaging().subscribe(toTopic: topicName)
                topics.append(topicName)
            }
        }
    }
    
    static func setBadge() {
        let realmDM = RealmManager.getInstance()
        let userDM = UserDefaultManager()
        
        // 他者の未読の数を数えてバッジを更新
        let messages = realmDM.getMessagesAllNoRead()
        var count = 0
        for msg in messages {
            if msg.senderId != userDM.getOwnUserId() {
                count += 1
            }
        }
        // 申請中リクエストの数を数えてバッジを更新
        if isUserTypeDoctor() {
           let reqs = realmDM.getRequestsByDoctorId(doctorId: userDM.getOwnUserId())
            for req in reqs {
                if req.requestConfirm == false {
                    count += 1
                }
            }
        }
        
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    static func postDataMessage(topicName:String,title:String,body:String, callback:@escaping (Bool) -> Void) {
        let url = URL.init(string: "https://fcm.googleapis.com/fcm/send")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("key=" + "AAAADj0wvXo:APA91bHShTGwaSG4xR5fVh40ydAFOKRObSCbSCcsRyRE12ZA3J2292kF3lgyb19y8Ikq4hCawWzZlYv3sVod99j1wpqzKFs46CiC7pqIOIMJsUxYKtt6VWbr6FsrKCve8NEVLcNqPA9L", forHTTPHeaderField: "Authorization")
        
        var sendData = Dictionary<String,Any>()
        sendData["to"] = "/topics/" + topicName
        sendData["priority"] = "high"
        var sendDataChild = Dictionary<String,Any>()
        sendDataChild["badge"] = 1
        sendDataChild["body"] = body
        sendDataChild["title"] = title
        
        sendData["notification"] = sendDataChild
        
        
        do {
            let sendJsonData = try JSONSerialization.data(withJSONObject: sendData, options: [])
            
            request.httpBody = sendJsonData
            
            // session
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
            
            // send
            let task = session.dataTask(with: request, completionHandler:{
                (data,response,error)->Void in
                
                if error == nil{
                    if data == nil {
                        callback(false)
                        return
                    } else {
                        callback(true)
                    }
                } else {
                    callback(false)
                }
            })
            task.resume()
        } catch _ {
            callback(false)
        }
    }
}
