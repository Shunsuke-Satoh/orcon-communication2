//
//  UserDefaultManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/21.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//
import UIKit

final class UserDefaultManager {
    func getOwnUserId() -> String {
        var ret = ""
        if let temp = UserDefaults.standard.string(forKey: Constant.uerId) {
            ret = temp
        }
        return ret
//        return "Si3tTr8z9JbOTWO8RGnkwGsFuN32"
    }
    
    func setOwnUserId(uid:String) -> Void {
        UserDefaults.standard.set(uid, forKey: Constant.uerId)
    }
    
    func getOwnPassword() -> String {
        var ret = ""
        if let temp = UserDefaults.standard.string(forKey: Constant.password) {
            ret = temp
        }
        return ret
    }
    
    func setOwnPassword(password:String) -> Void {
        UserDefaults.standard.set(password, forKey: Constant.password)
    }
    
    func getOwnUserType() -> String {
        var ret = ""
        if let temp = UserDefaults.standard.string(forKey: Constant.userType) {
            ret = temp
        }
        return ret
    }
    
    func setOwnToken(token:String) -> Void {
        UserDefaults.standard.set(token, forKey: Constant.dbUserToken)
    }
    
    func getOwnToken() -> String {
        var ret = ""
        if let temp = UserDefaults.standard.string(forKey: Constant.dbUserToken) {
            ret = temp
        }
        return ret
    }
    
    func setOwnUserType(userType:String) -> Void {
        UserDefaults.standard.set(userType, forKey: Constant.userType)
    }
    
    
    // 自分トップ画像を保存する
    func saveImageForOwnTop(uiImage: UIImage) -> Void {
        saveImageTop(userId: getOwnUserId(), uiImage: uiImage)
    }
    // 自分のトップ画像を取得する
    func loadImageForOwnTop() -> UIImage? {
        return loadImageTop(userId: getOwnUserId())
    }
    // 自分のアイコン画像を保存する
    func saveImageForOwnIcon(uiImage: UIImage) -> Void {
        saveImageIcon(userId: getOwnUserId(), uiImage: uiImage)
    }
    // 自分のアイコン画像を取得する
    func loadImageForOwnIcon() -> UIImage? {
        return loadImageIcon(userId: getOwnUserId())
    }
    
    // ユーザIDを元にアイコン画像を保存する
    func saveImageIcon(userId: String, uiImage: UIImage) -> Void {
        let resizedImage = uiImage.resize(size: CGSize(width:100, height:100))
        if let imgFile = resizedImage!.jpegData(compressionQuality: 0.5) {
            let imgFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(userId + "_" + Constant.iconImgName)
            do {
                try
                    imgFile.write(to:imgFilePath)
            } catch let error{
                print(error)
            }
        }
    }
    // ユーザIDを元にアイコン画像を取得する
    func loadImageIcon(userId: String) -> UIImage? {
        
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(userId + "_" + Constant.iconImgName)
        
        if let image = UIImage(contentsOfFile: filePath.path) {
            return image
        }
        
        return nil
    }
    
    // ユーザIDを元にトップ画像を保存する
    func saveImageTop(userId: String, uiImage: UIImage) -> Void {
        let resizedImage = uiImage.resize(size: CGSize(width:400, height:300))
        if let imgFile = resizedImage!.jpegData(compressionQuality: 0.5) {
            let imgFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(userId + "_" + Constant.topImgName)
            do {
                try
                    imgFile.write(to:imgFilePath)
            } catch let error{
                print(error)
            }
        }
    }
    // ユーザIDを元にトップ画像を取得する
    func loadImageTop(userId: String) -> UIImage? {
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(userId + "_" + Constant.topImgName)
        
        if let image = UIImage(contentsOfFile: filePath.path) {
            return image
        }
        
        return nil
    }
    
    // メッセージIDを元にメッセージ（画像）を保存する
    func saveImageForMessage(messageId: String, uiImage: UIImage) -> Void {
        if let imgFile = uiImage.jpegData(compressionQuality: 0.5) {
            let imgFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(messageId + ".jpg")
            do {
                try
                    imgFile.write(to:imgFilePath)
            } catch let error{
                print(error)
            }
        }
    }
    // メッセージIDを元にメッセージ（画像）を取得する
    func getImageForMessage(messageId: String) -> UIImage? {
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(messageId + ".jpg")
        
        if let image = UIImage(contentsOfFile: filePath.path) {
            return image
        }
        
        return nil
    }
    
}

extension UIImage {
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}
