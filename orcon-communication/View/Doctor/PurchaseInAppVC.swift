//
//  PurchaseInAppVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/12.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import SCLAlertView
import SVProgressHUD

class PurchaseInAppVC: UIViewController {
    @IBOutlet weak var iconImg: EnhancedCircleImageView!
    @IBOutlet weak var clinicName: UILabel!
    @IBOutlet weak var purchaseLimitDate: UILabel!
    @IBOutlet weak var Btn1: rectButton!
    @IBOutlet weak var Btn2: rectButton!
    @IBOutlet weak var Btn3: rectButton!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var lbl3: UILabel!
    @IBOutlet weak var price1: UILabel!
    @IBOutlet weak var price2: UILabel!
    @IBOutlet weak var price3: UILabel!
    
    let realmM = RealmManager.getInstance()
    let userDM = UserDefaultManager()
    let purchM = PurchaseManager.getInstance()
    
    var userMdl: UserModel!
    var btns: [rectButton] = []
    var lbls: [UILabel] = []
    var prices: [UILabel] = []
    var productsInfo: [Dictionary<String,String>] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ナビゲーションタイトル
        navigationItem.title = "利用料金のお支払い"
        
        // デリゲート
        PurchaseManager.getInstance().delegate = self
        
        // 処理しやすいように配列化
        btns.append(Btn1)
        btns.append(Btn2)
        btns.append(Btn3)
        lbls.append(lbl1)
        lbls.append(lbl2)
        lbls.append(lbl3)
        prices.append(price1)
        prices.append(price2)
        prices.append(price3)
        
        // プロダクト情報のロード
       let products = purchM.getProducts()
        if let product = products[PurchaseManager.id1] as? Dictionary<String,String>{
            productsInfo.append(product)
            lbl1.text = product[PurchaseManager.titlestr]!
            price1.text = product[PurchaseManager.pricestr]!
        }
        if let product = products[PurchaseManager.id2] as? Dictionary<String,String>{
            productsInfo.append(product)
            lbl2.text = product[PurchaseManager.titlestr]!
            price2.text = product[PurchaseManager.pricestr]!
        }
        if let product = products[PurchaseManager.id3] as? Dictionary<String,String>{
            productsInfo.append(product)
            lbl3.text = product[PurchaseManager.titlestr]!
            price3.text = product[PurchaseManager.pricestr]!
        }
        
        reloadDate()
    }
    
    func reloadDate() {
        // ユーザ情報の取得
        userMdl = realmM.getUserModelByUserId(userId: userDM.getOwnUserId())!
        
        // 画面情報のセット
        iconImg.image = userDM.loadImageForOwnIcon()
        clinicName.text = userMdl.clinicName
        purchaseLimitDate.text = DateUtils.stringFromDate(userMdl.purchaseLimitDate!)
    }
    
    @IBAction func tap1(_ sender: Any) {
        showDialog(0)
    }
    
    @IBAction func tap2(_ sender: Any) {
        showDialog(1)
    }
    
    @IBAction func tap3(_ sender: Any) {
        showDialog(2)
    }
    
    func showDialog(_ index:Int) {
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // 登録ボタン
        confV.addButton("購入する"){
            // 課金処理
            let pr = self.productsInfo[index]
            self.purchM.buy(pr[PurchaseManager.productIdstr]!)
            SVProgressHUD.show()
        }
        
        // キャンセルボタン
        confV.addButton("キャンセル"){
            confV.dismiss(animated: true, completion: {})
        }
        
        // ダイアログ表示
        if productsInfo.count > index {
            let product = productsInfo[index]
            let title = product[PurchaseManager.titlestr]!
            var text = ""
            text += "価格:" + product[PurchaseManager.pricestr]! + "\n"
            text += product[PurchaseManager.descstr]!
            confV.showNotice(title, subTitle:text)
        }
    }
    
    // realmとFBにデータ保存
    func setNewLimitDateToRealmFB(extendedPeriodDay: Int, baseDate:Date){
        let newMdl = userMdl.copyModel()
        let newDate = DateUtils.calcDateDay(day: extendedPeriodDay, baseDate: DateUtils.stringFromDate(baseDate))
        newMdl.purchaseLimitDate = newDate
        
        // realm
        realmM.updateUser(newMdl)
        // FB
        FBUserManager.getInstance().updatePurchaseLimitTime(newMdl.userId, newLimitDate: newMdl.purchaseLimitDate!)
    }
}

extension PurchaseInAppVC:PurchaseManagerDelegate {
    func success(id: String) {
        // realm保存
        var extendedPeriod = 0
        if id == PurchaseManager.id1 {
            extendedPeriod = 30
        }
        else if id == PurchaseManager.id2 {
            extendedPeriod = 90
        }
        else if id == PurchaseManager.id3 {
            extendedPeriod = 180
        }
        
        // 延長期間を計算してrealmとFBに保存
        var newDate = userMdl.purchaseLimitDate!
        // もし有効期限切れ日より現在が新しければそこから延長でしょう！
        if newDate < Date() {
            newDate = Date()
        }
        
        setNewLimitDateToRealmFB(extendedPeriodDay: extendedPeriod, baseDate: newDate)
        
        SVProgressHUD.dismiss()
        
        // 画面リロード
        reloadDate()
        
    }
    
    func fail(id: String) {
        SVProgressHUD.dismiss()
    }
}
