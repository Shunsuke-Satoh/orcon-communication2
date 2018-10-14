//
//  UserRequestSendVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/11.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import SCLAlertView

class UserRequestSendVC: UIViewController {
    @IBOutlet weak var topImg: UIImageView!
    @IBOutlet weak var iconImg: EnhancedCircleImageView!
    @IBOutlet weak var clinicName: UILabel!
    @IBOutlet weak var clinicAddress: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var tel: UILabel!
    
    var doctorId = ""
    var doctorMdl :UserModel!
    let realmM = RealmManager.getInstance()
    let userDM = UserDefaultManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // タイトルバー設定
        navigationItem.title = "リクエスト先医院の決定"
        
        // 医院情報のロード
        doctorMdl = realmM.getUserModelByUserId(userId: doctorId)!
        
        // 画面表示
        topImg.image = userDM.loadImageTop(userId: doctorId)
        iconImg.image = userDM.loadImageIcon(userId: doctorId)
        clinicName.text = doctorMdl.clinicName
        clinicAddress.text = doctorMdl.clinicAddress
        clinicName.text = doctorMdl.clinicName
        tel.text = doctorMdl.tel
    }
    
    @IBAction func tapRequest(_ sender: UIButton) {
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // 申請ボタン
        confV.addButton("はい"){
            // 自身を閉じる
            confV.dismiss(animated: true, completion: {})
            
            // リクエスト送信
            self.send()
            
            // 完了ダイアログ
            let completeV = SCLAlertView(appearance: appearance)
            completeV.addButton("閉じる"){
                // 自分自身も閉じる
                completeV.dismiss(animated: true, completion: {})
                // 画面遷移
                self.performSegue(withIdentifier: "toThanksForRequestSegue", sender: nil)
            }
            // 完了ダイアログ表示
            completeV.showSuccess("完了しました", subTitle: "")
        }
        
        // キャンセルボタン
        confV.addButton("いいえ"){
            confV.dismiss(animated: true, completion: {})
        }
        
        // ダイアログ表示
        confV.showNotice("確認", subTitle: "通信環境の良い場所で送信してください。")
    }
    
    func send() {
        // Realm保存
        realmM.insertRequest(customerId: userDM.getOwnUserId(), doctorId: doctorId, requestDate: Date(), isConfirm: false, confirmDate: nil)
        
        // サーバアップロード
        let fbReqM = FBRequestManager.getInstance()
        fbReqM.uploadRequestFromCustomerToDoctor(doctorId: doctorId)
        
        // push通知
        let topicName = CommonUtils.getReqDoctorTopicName(doctorId: doctorId)
        
        let ownMdl = realmM.getUserModelByUserId(userId: userDM.getOwnUserId())!
        CommonUtils.postDataMessage(topicName: topicName, title: ownMdl.name + "さんからリクエストが届きました", body: "", callback: {(_) in})
        
        // push受け取りのためトピック参加
        CommonUtils.getInstance().signInTockenToRequest(false)
        
        // リスナー登録
        fbReqM.setRequestObserver(doctorId: doctorId, customerId: ownMdl.userId)
        
        // 関係無いドクター情報を消去
        let doctors = realmM.getDoctors()
        for doc in doctors {
            if doc.userId != doctorId {
                FBUserManager.getInstance().removeObserver(doc.userId)
                realmM.deleteUserModel(doc.userId)
            }
        }
    }

}
