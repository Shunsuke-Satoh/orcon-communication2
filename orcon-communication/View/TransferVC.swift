//
//  TransferVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/26.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import FirebaseAuth
import SCLAlertView

class TransferVC: UIViewController{
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        email.delegate = self
        password.delegate = self
        email.text = ""
        password.text = ""
        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func doTransfer(_ sender: UIButton) {
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        let waitView = SCLAlertView(appearance: appearance)
        let successView = SCLAlertView(appearance: appearance)
        let failView = SCLAlertView(appearance: appearance)
        
        // ボタン追加
        successView.addButton("次へ"){
            successView.dismiss(animated: true, completion: {})
            // メイン画面へ
            self.performSegue(withIdentifier: "TransVCtoMainVC", sender: nil)
        }
        failView.addButton("やり直す"){
            failView.dismiss(animated: true, completion: {})
        }
        
        // 通信中ポップアップを表示
        let waitViewRes = waitView.showWait("ユーザ認証中です", subTitle: "")
        
        // 認証する
        Auth.auth().signIn(withEmail: email.text!, password: password.text!, completion: {(user, error) in
            if error != nil {
                waitViewRes.close()
                let er = error as! NSError
                if er.code == 17009{
                    failView.showError("認証に失敗しました" , subTitle: "メールアドレスまたはパスワードが違います")
                } else {
                    failView.showError("認証に失敗しました" , subTitle: "ネットワークの状態を確認して下さい")
                }
            } else {
                waitViewRes.setTitle("データ引継ぎ中です")
                // 認証成功
                var uid = ""
                if let temp = user?.user.uid {
                    uid = temp
                }
                
                // ユーザ情報の保存
                let userDM = UserDefaultManager()
                userDM.setOwnUserId(uid: uid)
                userDM.setOwnPassword(password: self.password.text!)
                
                var isFinish = false
                
                // データをダウンロードする
                let fbM = FBRealTimeDataBaseManager.getInstance()
                fbM.downloadAllDataFromUserId(userId: uid, callback: { (isSuccess, errorMsg) in
                    if isFinish == false {
                        waitViewRes.close()
                        // 成功したらポップアップを出してメイン画面へ
                        if isSuccess {
                            successView.showSuccess("データ引継ぎに成功しました", subTitle: "")
                        } else {
                            // 失敗したらポップアップを出して止まる
                            failView.showError("データ引継ぎに失敗しました", subTitle: errorMsg)
                            fbM.removeAllObserver()
                        }
                    }
                    isFinish = true
                })
            }
        })
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

// キーボード隠す
extension TransferVC:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
