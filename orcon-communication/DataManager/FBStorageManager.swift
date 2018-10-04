//
//  ImageManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/17.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

class FBStorageManager: NSObject {
    var delegate: ChatDataManager!
    
    // constractor
    override init() {
        super.init()
    }
    
    // uploadImage
    func upLoadImage(img: UIImage, uid: String, mode: Int, completion:@escaping (Bool) -> Void)->Void{
        let storageRef = Storage.storage().reference()
        
        // 登録するイメージの種類
        let imageName = (mode == Constant.storageImgModeTOP) ? Constant.topImgName : Constant.iconImgName
        
        // ディレクトリ指定
        let imageRef = storageRef.child(Constant.storageUserPath + "/" + uid + "/" + imageName)
        //let imageRef = storageRef.child("test.jpg")
        
        let imageData = img.jpegData(compressionQuality: 0.5)!
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if (error != nil) {
                print("upload Error")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // uploadImageForMessage
    func upLoadImageForMessage(roomId:String, message:MessageModel, uiImage: UIImage, completion:@escaping (Bool) -> Void)->Void{
        let storageRef = Storage.storage().reference()

        // fireStorage上のフルパス指定
        let imageRef = storageRef.child(getMessagePath(roomId: roomId, message: message))
        
        let imageData = uiImage.jpegData(compressionQuality: 0.5)!
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if (error != nil) {
                print("upload Error")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // downLoadImage
    func downLoadImage(fullPath: String, callback: @escaping (UIImage)->Void) {
        var ret = UIImage()
        let islandRef = Storage.storage().reference(withPath:fullPath)
        islandRef.getData(maxSize: 4 * 4096 * 4096) { data, error in
            if error != nil {
                print(error ?? "error")
            } else {
                let img = UIImage(data: data!)
                ret = img!
            }
            callback(ret)
        }
    }
    
    func getMessagePath(roomId:String, message:MessageModel) -> String {
        return Constant.storageChatPath + "/" + roomId + "/" + message.messageId + ".jpg"
    }
    func getUserIconImgPath(userId:String) -> String {
        return Constant.storageUserPath + "/" + userId + "/" + Constant.iconImgName
    }
    func getUserTopImgPath(userId:String) -> String {
        return Constant.storageUserPath + "/" + userId + "/" + Constant.topImgName
    }
}
