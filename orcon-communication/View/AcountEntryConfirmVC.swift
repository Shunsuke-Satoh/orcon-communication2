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
import SCLAlertView
import SVProgressHUD

class AcountEntryConfirmViewController: UIViewController {
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var hiraLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var passwordLbl: UILabel!
    @IBOutlet weak var clinicNameLbl: UILabel!
    @IBOutlet weak var telLbl: UILabel!
    @IBOutlet weak var clinicAddressLbl: UILabel!
    
    @IBOutlet weak var topImgView: UIImageView!
    @IBOutlet weak var iconImgView: UIImageView!
    
    @IBOutlet weak var confirmBtn: UIButton!
    
    @IBOutlet weak var clinicNameStack: UIStackView!
    @IBOutlet weak var clinicAddressStack: UIStackView!
    var userType = ""
    var name: String = ""
    var hira: String = ""
    var email: String = ""
    var password: String = ""
    var clinicName: String = ""
    var tel: String = ""
    var clinicAddress: String = ""
    var topImg: UIImage!
    var iconImg: UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameLbl.text = name
        hiraLbl.text = hira
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
        let imgM = FBStorageManager()
        let userDM = UserDefaultManager()
        let realmDM = RealmManager.getInstance()
        
        // 非同期処理を最後に同期させることでローディングエフェクトを開始終了させる
        let dispatchGroup = DispatchGroup()
        
        // ローディング開始
        SVProgressHUD.show()
//        loadingIcon.startAnimating()
        
        // ユーザ認証
        Auth.auth().createUser(withEmail: email, password: password){(authResult, error) in
            if let error = error {
                SVProgressHUD.dismiss()
//                self.loadingIcon.stopAnimating()
                // ポップアップを準備
                let appearance = SCLAlertView.SCLAppearance(
                    showCloseButton:false
                )
                
                let confV = SCLAlertView(appearance: appearance)
                
                // 破棄ボタン
                confV.addButton("はい"){
                    confV.dismiss(animated: true, completion: {})
                }
                
                // ダイアログ表示
                confV.showNotice("通信不良または既に登録されているメールアドレスです", subTitle: "登録に心当たりがある場合は、トップ画面に戻り「データ引継ぎ」からデータ引継ぎを行なってください")
            } else{
                // ユーザID
                let uid = (authResult?.user.uid)!
                
                // 先ずはユーザデフォルトに自分のIDを保存
                userDM.setOwnUserId(uid: uid)
                userDM.setOwnPassword(password: self.password)
                userDM.setOwnUserType(userType: self.userType)
                
                // ドクターの場合は課金有効日時も入れる
                var purchaseLimitDate:Date?
          
                // 無料期間は30日
                if CommonUtils.isUserTypeDoctor() {
                    purchaseLimitDate = DateUtils.calcDateDay(day: 30, baseDate: DateUtils.stringFromDate(Date()))
                }
                
                // ユーザ情報をアップロード
                FBUserManager.getInstance().uploadUserAndDoctor(userId: uid, userType: self.userType, name: self.name, hira: self.hira, tel: self.tel, email: self.email, password: self.password, clinicName: self.clinicName, clinicAddress: self.clinicAddress, purchaseLimitDate: purchaseLimitDate)
           
                
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
                
                realmDM.insertUpdateUser(userId: uid, userType: self.userType, name: self.name, hira: self.hira, tel: self.tel, email: self.email, clinicName: self.clinicName, clinicAddress: self.clinicAddress, rooms:[],requestDoctorId: "",entryDate: Date(),status:0, deleteDate: nil, purchaseLimitDate: purchaseLimitDate)
                
                // UserDefaultに保存 トップ、アイコン
                userDM.saveImageForOwnIcon(uiImage: self.iconImg)
                
                if self.userType == Constant.userTypeDoctor {
                    userDM.saveImageForOwnTop(uiImage: self.topImg)
                }
                
                // ローディング終了
                dispatchGroup.notify(queue: .main) {
                    SVProgressHUD.dismiss()
                    self.performSegue(withIdentifier: "toCompleteSegue", sender: nil)
                }
            }
        }
    }
}
