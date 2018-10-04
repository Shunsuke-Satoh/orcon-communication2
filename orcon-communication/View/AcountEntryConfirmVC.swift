//
//  AcountEntryConfirmViewController.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/12.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class AcountEntryConfirmViewController: UIViewController {
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var passwordLbl: UILabel!
    @IBOutlet weak var clinicNameLbl: UILabel!
    @IBOutlet weak var telLbl: UILabel!
    @IBOutlet weak var clinicAddressLbl: UILabel!
    
    @IBOutlet weak var topImgView: UIImageView!
    @IBOutlet weak var iconImgView: UIImageView!
    
    @IBOutlet weak var confirmBtn: UIButton!
    
    @IBOutlet weak var loadingIcon: UIActivityIndicatorView!
    
    @IBOutlet weak var clinicNameStack: UIStackView!
    @IBOutlet weak var clinicAddressStack: UIStackView!
    var userType = ""
    var name: String = ""
    var email: String = ""
    var password: String = ""
    var clinicName: String = ""
    var tel: String = ""
    var clinicAddress: String = ""
    var topImg: UIImage!
    var iconImg: UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingIcon.hidesWhenStopped = true
        loadingIcon.stopAnimating()
        loadingIcon.frame = CGRect(x: self.view.center.x - 25, y: self.view.center.y - 25, width: 50, height: 50)
        loadingIcon.center = self.view.center
        
        // ボタンのスタイル
        confirmBtn.setTitleColor(UIColor.black, for: .normal)
        confirmBtn.backgroundColor = UIColor.white
        confirmBtn.layer.cornerRadius = 20
        confirmBtn.layer.borderWidth = 1
        confirmBtn.layer.shadowOpacity = 0.5
        confirmBtn.layer.shadowOffset = CGSize(width:2,height:2)
        
        
        nameLbl.text = name
        telLbl.text = tel
        emailLbl.text = email
        passwordLbl.text = password
        
        if userType == Constant.userTypeDoctor {
            clinicNameLbl.text = clinicName
            clinicAddressLbl.text = clinicAddress
            topImgView.image = topImg
        } else {
            clinicNameStack.isHidden = true
            clinicAddressStack.isHidden = true
        }
        
        iconImgView.image = iconImg
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // 画面遷移前のバリデーション
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // uploadが成功したら改めて画面遷移させる
        if identifier == "toCompleteSegue" {
            upload()
        }
        
        return false
    }
    
    func upload() {
        let fbRTDM = FBRealTimeDataBaseManager.getInstance()
        let imgM = FBStorageManager()
        let userDM = UserDefaultManager()
        let realmDM = RealmManager.getInstance()
        
        // 非同期処理を最後に同期させることでローディングエフェクトを開始終了させる
        let dispatchGroup = DispatchGroup()
        
        // ローディング開始
        loadingIcon.startAnimating()
        
        // ユーザ認証
        Auth.auth().createUser(withEmail: email, password: password){(authResult, error) in
            if let error = error {
                print(error)
            } else{
                // ユーザID
                let uid = (authResult?.user.uid)!
                
                // 先ずはユーザデフォルトに自分のIDを保存
                userDM.setOwnUserId(uid: uid)
                userDM.setOwnPassword(password: self.password)
                userDM.setOwnUserType(userType: self.userType)
          
                // ユーザ情報をアップロード
                fbRTDM.uploadUserAndDoctor(userId: uid, userType: self.userType, name: self.name, tel: self.tel, email: self.email, password: self.password, clinicName: self.clinicName, clinicAddress: self.clinicAddress)
           
                
                // 画像データをアップロード トップ、アイコン
                if self.userType == Constant.userTypeDoctor {
                    dispatchGroup.enter()
                    DispatchQueue.main.async(group: dispatchGroup) {
                        imgM.upLoadImage(img: self.topImg, uid: uid, mode: Constant.storageImgModeTOP, completion:  {(isSuccess)-> Void in
                            // 失敗した時どうする？
                            // ユーザ設定画面から再設定してもらうか
                            dispatchGroup.leave()
                        })
                    }
                }
                
                dispatchGroup.enter()
                DispatchQueue.main.async(group: dispatchGroup) {
                    imgM.upLoadImage(img: self.iconImg, uid: uid, mode: Constant.storageImgModeICON, completion:  {(isSuccess)-> Void in
                        // 失敗した時どうする？
                        // ユーザ設定画面から再設定してもらうか
                        dispatchGroup.leave()
                    })
                }
                
                // Realmに保存
                realmDM.insertUpdateUser(userId: uid, userType: self.userType, name: self.name, tel: self.tel, email: self.email, clinicName: self.clinicName, clinicAddress: self.clinicAddress, rooms:[],requestDoctorId: "",entryDate: Date(),status:0)
                
                // UserDefaultに保存 トップ、アイコン
                userDM.saveImageForOwnIcon(uiImage: self.iconImg)
                
                if self.userType == Constant.userTypeDoctor {
                    userDM.saveImageForOwnTop(uiImage: self.topImg)
                }
                
                // ローディング終了
                dispatchGroup.notify(queue: .main) {
                    self.loadingIcon.stopAnimating()
                    self.performSegue(withIdentifier: "toCompleteSegue", sender: nil)
                }
            }
        }
    }
}
