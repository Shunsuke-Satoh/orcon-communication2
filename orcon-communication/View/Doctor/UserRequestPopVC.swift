//
//  UserRequestPopVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/27.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import SCLAlertView

class UserRequestPopVC: UIViewController {
    @IBOutlet weak var imageV: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var telLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var termLbl: UILabel!
    @IBOutlet weak var confirmBtn: UIButton!
    @IBOutlet weak var denyBtn: UIButton!
    @IBOutlet weak var compBtn: UIButton!
    @IBOutlet weak var closeBtn: imageRoundButton!
    
    @IBOutlet weak var telView: UIStackView!
    @IBOutlet weak var mailView: UIStackView!
    @IBOutlet weak var reqView: UIStackView!
    @IBOutlet weak var dateView: UIStackView!
    var image:UIImage?
    var user:UserModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 下線をつける
        telLbl.adjustsFontSizeToFitWidth = true

        imageV.image = image!
        nameLbl.text = user.name
        telLbl.text = user.tel
        emailLbl.text = user.email
        if user.status == Constant.statusRequest {
            statusLbl.text = Constant.status.statusRequest.rawValue
        }
        else if user.status == Constant.statusTreat {
            statusLbl.text = Constant.status.statusTreat.rawValue
        }
        else if user.status == Constant.statusComp {
            statusLbl.text = Constant.status.statusComp.rawValue
        }
        
        termLbl.text = DateUtils.stringFromDate(user.entryDate!) + "に登録"
        
        if user.status == Constant.statusRequest {
            confirmBtn.isHidden = false
            denyBtn.isHidden = false
            
            compBtn.isHidden = true
        } else {
            confirmBtn.isHidden = true
            denyBtn.isHidden = true
            
            compBtn.isHidden = false
        }
        
        setUpBtn(compBtn)
        setUpBtn(confirmBtn)
        setUpBtn(denyBtn)
        setUpBtn(closeBtn)
    }
    
    func setUpBtn(_ btn:UIButton) {
        
        let height = btn.bounds.height
        btn.imageEdgeInsets = UIEdgeInsets(top: height * 0.3, left: 5, bottom: height * 0.3, right: 5)
        
//        btn.layer.cornerRadius = 26
    }
    
    @IBAction func confirm(_ sender: Any) {
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // 登録ボタン
        confV.addButton("はい"){
            // 登録処理へ
            FBRequestManager.getInstance().updateRequestFromDoctorToCustomer(customerId: self.user.userId)
            
            // push通知
            let topicName = CommonUtils.getReqTopicName(doctorId: UserDefaultManager().getOwnUserId(), customerId: self.user.userId)
            CommonUtils.postDataMessage(topicName: topicName, title: "リクエストが承認されました", body: "", callback: {(_) in})
            confV.dismiss(animated: true, completion: {})
            
            // 完了ダイアログ
            let completeV = SCLAlertView(appearance: appearance)
            completeV.addButton("閉じる"){
                // 自分自身も閉じる
                completeV.dismiss(animated: true, completion: {})
                self.dismiss(animated: true, completion: {})
            }
            // 完了ダイアログ表示
            completeV.showSuccess("完了しました", subTitle: "")
        }
        
        // キャンセルボタン
        confV.addButton("いいえ"){
            confV.dismiss(animated: true, completion: {})
        }
        
        // ダイアログ表示
        confV.showNotice("承認確認", subTitle: "以降トークができるようになります")
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    @IBAction func deny(_ sender: Any) {
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // 削除ボタン
        confV.addButton("はい"){
            // 削除処理へ
            FBRequestManager.getInstance().deleteRequestFromDoctor(customerId: self.user.userId)
            
            // push通知
            let topicName = CommonUtils.getReqTopicName(doctorId: UserDefaultManager().getOwnUserId(), customerId: self.user.userId)
            CommonUtils.postDataMessage(topicName: topicName, title: "リクエストが削除されました", body: "", callback: {(_) in})
            
            confV.dismiss(animated: true, completion: {})
            
            // 完了ダイアログ
            let completeV = SCLAlertView(appearance: appearance)
            completeV.addButton("閉じる"){
                // 自分自身も閉じる
                completeV.dismiss(animated: true, completion: {})
                self.dismiss(animated: true, completion: {})
            }
            // 完了ダイアログ表示
            completeV.showSuccess("完了しました", subTitle: "")
        }
        
        // キャンセルボタン
        confV.addButton("いいえ"){
            confV.dismiss(animated: true, completion: {})
        }
        
        // ダイアログ表示
        confV.showNotice("リクエストを削除します", subTitle: "リクエスト間違いなどの確認はお済みですか？")
    }
    
    
    @IBAction func treatComp(_ sender: Any) {
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // 治療完了ボタン
        confV.addButton("はい"){
            // 更新処理へ
            FBUserManager.getInstance().updateUserStatus(userId:self.user.userId,status:Constant.statusComp)
            
            confV.dismiss(animated: true, completion: {})
            
            // 完了ダイアログ
            let completeV = SCLAlertView(appearance: appearance)
            completeV.addButton("閉じる"){
                // 自分自身も閉じる
                completeV.dismiss(animated: true, completion: {})
                self.dismiss(animated: true, completion: {})
            }
            // 完了ダイアログ表示
            completeV.showSuccess("完了しました", subTitle: "")
        }
        
        // キャンセルボタン
        confV.addButton("いいえ"){
            confV.dismiss(animated: true, completion: {})
        }
        
        // ダイアログ表示
        confV.showNotice("治療完了にします", subTitle: "")
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
