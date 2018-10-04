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
    
    static let dbUser = "user"
    static let dbUserUsertype = "user_type"
    static let dbUserName = "name"
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
    static let dbUserToken = "token"
    
    static let dbDoctor = "doctor"
    static let dbDoctorName = "name"
    static let dbDoctorEmail = "email"
    static let dbDoctorTel = "tel"
    static let dbDoctorClinicName = "clinic_name"
    static let dbDoctorClinicAddress = "clinic_address"
    
    static let dbRoom = "room"
    static let dbRoomIdMembers = "members"
    static let dbRoomIdLatestmsgnum = "latest_msg_num"
    static let dbMessage = "message"
    static let dbMessageSenderUid = "sender_uid"
    static let dbMessageMsgType = "message_type"
    static let dbMessageContents = "contents"
    static let dbMessageEntryDate = "entry_date"
    static let dbMessageRead = "read"
    
    static let dbRequest = "request"
    static let dbRequestRequestDate = "request_date"
    static let dbRequestIsConfirm = "is_Confirm"
    static let dbRequestConfirmDate = "confirm_date"
}
