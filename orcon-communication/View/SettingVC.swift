//
//  SettingVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/02.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import SCLAlertView

class SettingVC: UIViewController {
    @IBOutlet weak var acountV: UIView!
    @IBOutlet weak var purchaseV: UIView!
    @IBOutlet weak var supportV: UIView!
    @IBOutlet weak var termV: UIView!
    @IBOutlet weak var companyV: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var iconImg: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "設定"
        
        FBUserManager.getInstance().delegate = self
        FBUserManager.getInstance().delegateImg = self
        // Do any additional setup after loading the view.
        dataReload()
    }
    
    func dataReload() {
        let ownMdl = RealmManager.getInstance().getUserModelByUserId(userId: UserDefaultManager().getOwnUserId())
        
        if CommonUtils.isUserTypeDoctor() {
            name.text = ownMdl?.clinicName
        }
        else if CommonUtils.isUserTypeUser() {
            name.text = ownMdl?.name
            purchaseV.isHidden = true
        }
        
        iconImg.image = UserDefaultManager().loadImageForOwnIcon()
    }
    
    // タッチイベント 一回色を元に戻してそれぞれのVに色判定してもらう
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        acountV.backgroundColor = .clear
        purchaseV.backgroundColor = .clear
        supportV.backgroundColor = .clear
        termV.backgroundColor = .clear
        companyV.backgroundColor = .clear
        super.touchesBegan(touches, with: event)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAcountChangeSegue" {
            let vc = segue.destination as! AcountEntryViewController
            vc.userType = UserDefaultManager().getOwnUserType()
        }
    }
    
    // アカウント情報設定画面へ
    @IBAction func tapAcountSet(_ sender: Any) {
        performSegue(withIdentifier: "toAcountChangeSegue", sender: nil)
    }
    
    // 課金画面へ
    @IBAction func tapPerchase(_ sender: Any) {
        if CommonUtils.isUserTypeDoctor() {
            performSegue(withIdentifier: "toPurchaseSegue", sender: nil)
        }
    }
    
    // サポートの表示
    @IBAction func tapSuport(_ sender: Any) {
        let url = URL(string: "https://orcon-web.com/contact/")
        if UIApplication.shared.canOpenURL(url!){
            commonPopUp(url: url!)
        }
        
    }
    // 利用規約の表示
    @IBAction func tapTerm(_ sender: Any) {
        let url = URL(string: "https://orcon-web.com/term/")
        if UIApplication.shared.canOpenURL(url!){
            commonPopUp(url: url!)
        }
    }
    
    // 会社概要の表示
    @IBAction func tapCompany(_ sender: Any) {
        let url = URL(string: "https://orcon-web.com/corporation/")
        if UIApplication.shared.canOpenURL(url!){
            commonPopUp(url: url!)
        }
    }
    
    func commonPopUp(url:URL) {
        
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // ブラウザボタン
        confV.addButton("はい"){
            confV.dismiss(animated: true, completion: {})
            if UIApplication.shared.canOpenURL(url){
                UIApplication.shared.open(url, options:[:], completionHandler: nil)
            }
        }
        
        // キャンセルボタン
        confV.addButton("いいえ"){
            confV.dismiss(animated: true, completion: {})
        }
        
        // ダイアログ表示
        confV.showNotice("確認", subTitle: "ブラウザで外部リンクを開きます")
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


extension SettingVC: FBUserManagerImageDelegate, FBUserManagerDelegate {
    func compTopImg(userId: String) {
        dataReload()
    }
    
    func compIconImg(userId: String) {
        dataReload()
    }
    
    func userUpdated(userModel: UserModel) {
        dataReload()
    }
    
}
