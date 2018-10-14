//
//  DoctorMainViewController.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/13.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SCLAlertView
import BWWalkthrough

class MainVC: UIViewController {
    @IBOutlet weak var clinicNameLbl: UILabel!
    @IBOutlet weak var clinicIconImg: UIImageView!
    @IBOutlet weak var clinicTopImg: UIImageView!
    @IBOutlet weak var requestLbl: UILabel!
    @IBOutlet weak var calendarBtn: UIButton!
    @IBOutlet weak var requestBtn: UIButton!
    @IBOutlet weak var chatBtn: UIButton!
    @IBOutlet weak var chatCount: circleLabel!
    @IBOutlet weak var requestCount: circleLabel!
    @IBOutlet weak var centerLineView: centerLineView!
    @IBOutlet weak var calendarLbl: UILabel!
    @IBOutlet weak var remainingPeriod: UILabel!
    
    // 期限切れ用
    var isShownPurchase1 = false
    var isShownPurchase3 = false
    var isShownPurchase7 = false
    
    // ウォークスルー用
    var walkthrough:BWWalkthroughViewController!
    
    
    var name: String = ""
    var clinicName: String = ""
    var topImg: UIImage!
    var iconImg: UIImage!
    
    let userDM = UserDefaultManager()
    let realmDM = RealmManager.getInstance()
    let imgM = FBStorageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 中央線を引くクラスは外部から背景透過を指定
        centerLineView.isOpaque = false
        // ナビゲーションタイトルにロゴ指定
        let imgView = UIImageView(image:UIImage(named:"logo_title_blue_big"))
        imgView.contentMode = .scaleAspectFit
        
        navigationItem.titleView = imgView
        
        // 患者とドクターでラベル表示が違う
        if CommonUtils.isUserTypeUser() {
            calendarLbl.text = "予約"
            
            requestBtn.imageView?.image = UIImage(named: "icon_tel")
            requestBtn.setTitle("電話をかける", for: .normal)
        }
        
        // ウォークスルーへ
        if userDM.isWalkthroughDone() == false {
            userDM.setWalkthrough()
            if CommonUtils.isUserTypeUser() {
                // リクエスト承認が完了していたら
                if isCustomerRequestConfirm() {
                    showCustomerWalk()
                }
            }
            else if CommonUtils.isUserTypeDoctor() {
                showDoctorWalk()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // 有効期限切れ確認 中でドクターかは確認済み
        if CommonUtils.isSafeLimit() == false {
            isShownPurchase1 = true
            isShownPurchase3 = true
            isShownPurchase7 = true
            showPurchase()
        }
        // 期限間近でもアラート
        else if CommonUtils.isUserTypeDoctor() {
            let ownMdl = realmDM.getUserModelByUserId(userId: userDM.getOwnUserId())!
            let diff = DateUtils.differenceInDay(fromDate: Date(), toDate: ownMdl.purchaseLimitDate!)
            
            if diff <= 1 && isShownPurchase1 == false {
                isShownPurchase1 = true
                isShownPurchase3 = true
                isShownPurchase7 = true
                showPurchaseInAdvance()
            }
            else if diff <= 3 && isShownPurchase3 == false {
                isShownPurchase3 = true
                isShownPurchase7 = true
                showPurchaseInAdvance()
            }
            else if diff <= 7 && isShownPurchase7 == false {
                isShownPurchase7 = true
                showPurchaseInAdvance()
            }
            else if diff > 7 {
                isShownPurchase1 = false
                isShownPurchase3 = false
                isShownPurchase7 = false
            }
        }
        dataReload()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // チャットボタンの行き先はドクター、カスタマーで違う
    @IBAction func tapChat(_ sender: UIButton) {
        // 有効期限切れ確認
        if CommonUtils.isSafeLimit() == false {
            showPurchase()
            return
        }
        
        if CommonUtils.isUserTypeUser(){
            if let rooms = RealmManager.getInstance().getChatRoomModels() {
                performSegue(withIdentifier: "toChatViewUserSegue", sender: rooms[0].roomId)
            }
        } else if CommonUtils.isUserTypeDoctor() {
            performSegue(withIdentifier: "toChatListSegue", sender: nil)
        }
    }
    // カレンダーボタンも行き先はドクター、カスタマーで違う
    @IBAction func tapCalendar(_ sender: UIButton) {
        // 有効期限切れ確認
        if CommonUtils.isSafeLimit() == false {
            showPurchase()
            return
        }
        
        if CommonUtils.isUserTypeUser() {
            if let rooms = RealmManager.getInstance().getChatRoomModels() {
                // チャットルームー＞予約ページ
                let chatVC = storyboard?.instantiateViewController(withIdentifier: "chatVC") as! ChatViewController
                chatVC.roomId = rooms[0].roomId
               
                let reserveVC = storyboard?.instantiateViewController(withIdentifier: "chatRVC")
               
                let vcs:[UIViewController] = [self, chatVC, reserveVC!]
                
                navigationController?.setViewControllers(vcs, animated: true)
            }
        }
        else if CommonUtils.isUserTypeDoctor(){
            performSegue(withIdentifier: "toCalendarSetSegue", sender: nil)
        }
    }
    
    // リクエストボタンも行き先はドクター、カスタマーで違う
    @IBAction func tapRequestBtn(_ sender: UIButton) {
        
        // 有効期限切れ確認
        if CommonUtils.isSafeLimit() == false {
            showPurchase()
            return
        }
        
        if CommonUtils.isUserTypeUser() {
            if let requestModel = realmDM.getRequestByCustomerId(customerId: userDM.getOwnUserId()){
                let doctorId = requestModel.doctorId
                let userModel = realmDM.getUserModelByUserId(userId: doctorId)!
                print(userModel.tel)
                let url = URL(string: "tel://" + userModel.tel)!
                if UIApplication.shared.canOpenURL(url){
                    UIApplication.shared.open(url, options: [:], completionHandler:nil)
                } else {
                    print("cant")
                }
            }
        }
        else if CommonUtils.isUserTypeDoctor() {
            performSegue(withIdentifier: "toRequestManageSegue", sender: nil)
        }
    }
    
    // 残期間をタップした場合、課金画面へ
    @IBAction func tapRemaining(_ sender: Any) {
        if CommonUtils.isUserTypeDoctor() {
            performSegue(withIdentifier: "toPurchase1Segue", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toChatViewUserSegue") {
            if let roomId = sender as? String {
                let vc: ChatViewController = (segue.destination as? ChatViewController)!
                vc.roomId = roomId
            }
        }
    }
    
    func dataReload() {
        ChatDataManager.getInstance().delegate = self
        FBRequestManager.getInstance().delegate = self
        FBUserManager.getInstance().delegate = self
        FBUserManager.getInstance().delegateImg = self
        
        remainingPeriod.isEnabled = false
        remainingPeriod.text = ""
        
        let ownId = userDM.getOwnUserId()
        requestLbl.isHidden = true
        
        // 画像のロード
        // ドクターの場合
        if CommonUtils.isUserTypeDoctor() {
            let userModel = realmDM.getUserModelByUserId(userId: ownId)
            clinicNameLbl.text = userModel?.clinicName
            
            clinicIconImg.image = userDM.loadImageForOwnIcon()
            clinicTopImg.image = userDM.loadImageForOwnTop()
            
            // リクエストのリスナー登録
            FBRequestManager.getInstance().setRequestObserver(doctorId: ownId, customerId: "")
            
            // 残期間
            if Date() > (userModel?.purchaseLimitDate)! {
                remainingPeriod.text = "期限切れ"
                remainingPeriod.textColor = .red
                
            } else {
                // 現在の方が新しければマイナス
                let diff = DateUtils.differenceInDay(fromDate: Date(), toDate: (userModel?.purchaseLimitDate!)!)
                remainingPeriod.text = "あと" + diff.description + "日"
                remainingPeriod.textColor = .black
            }
        }
            // カスタマーの場合
        else if CommonUtils.isUserTypeUser(){
            
            if let requestModel = realmDM.getRequestByCustomerId(customerId: ownId){
                let doctorId = requestModel.doctorId
                let userModel = realmDM.getUserModelByUserId(userId: doctorId)
                
                clinicNameLbl.text = userModel?.clinicName
                clinicIconImg.image = userDM.loadImageIcon(userId: doctorId)
                clinicTopImg.image = userDM.loadImageTop(userId: doctorId)
                
                // リクエストの承認が完了しているか
                if requestModel.requestConfirm == false {
                    requestLbl.isHidden = false
                    calendarBtn.isEnabled = false
                    chatBtn.isEnabled = false
                } else {
                    // リクエストのリスナー登録
                    FBRequestManager.getInstance().setRequestObserver(doctorId: requestModel.doctorId, customerId: requestModel.customerId)
                    calendarBtn.isEnabled = true
                    chatBtn.isEnabled = true
                }
            }
        }
        
        // 未読アイコンの更新
        midokuUpdate()
        // リクエスト承認の更新
        requestUpdate()
        // バッジの更新
        CommonUtils.setBadge()
    }
    
    // リクエスト承認済みか
    func isCustomerRequestConfirm() -> Bool {
        if let requestModel = realmDM.getRequestByCustomerId(customerId: userDM.getOwnUserId()){
            return requestModel.requestConfirm
        }
        return false
    }
    // カスタマーから見たドクターを取得
    func getDoctorFromCustomer() -> UserModel {
        let requestModel = realmDM.getRequestByCustomerId(customerId: userDM.getOwnUserId())!
        return realmDM.getUserModelByUserId(userId: requestModel.doctorId)!
    }
    
    func midokuUpdate(){
        chatCount.isHidden = true
        var count = 0
        
        for room in RealmManager.getInstance().getChatRoomModels()! {
            for message in room.messages {
                if message.senderId != userDM.getOwnUserId() && message.read == false{
                    count += 1
                }
            }
        }
        
        chatCount.text = count.description
        
        if count > 0 {
            chatCount.isHidden = false
        }
    }
    
    func requestUpdate() {
        requestCount.isHidden = true
        var count = 0
        
        for request in RealmManager.getInstance().getRequestsByDoctorId(doctorId: userDM.getOwnUserId()) {
            if request.requestConfirm == false {
                count += 1
            }
        }
        
        requestCount.text = count.description
        
        if count > 0 {
            requestCount.isHidden = false
        }
    }
    // POPで戻ってくる時の受け皿
    @IBAction func unwindToFirstViewControllerWithSegue(segue: UIStoryboardSegue) {
    }
    
}

extension MainVC: MessageDelegate {
    func messageUpdated(msgModel: MessageModel) {
        midokuUpdate()
    }
    func messageReaded(msgModel: MessageModel) {
        midokuUpdate()
    }
}

extension MainVC: FBRequestManagerDelegate{
    func requestUpdated(reqModel:RequestModel){
        if CommonUtils.isUserTypeDoctor(){
            requestUpdate()
        } else if CommonUtils.isUserTypeUser() {
            dataReload()
            // チャットルームのデータロード
            ChatDataManager.getInstance().getDataFromDB(callback: {(_) in})
            // ウォークスルーへ
            if userDM.isWalkthroughDone() == false {
                // リクエスト承認が完了していたら
                if isCustomerRequestConfirm() {
                    showCustomerWalk()
                }
            }
        }
    }
    func requestInserted(reqModel:RequestModel){
        requestUpdate()
    }
    func requestDeleted(doctorId:String, customerId:String){
        if CommonUtils.isUserTypeDoctor(){
            requestUpdate()
        } else if CommonUtils.isUserTypeUser() {
            // リクエストが削除された
            // ポップアップを準備
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton:false
            )
            
            let confV = SCLAlertView(appearance: appearance)
            
            // 申請ボタン
            confV.addButton("閉じる"){
                // 自身を閉じる
                confV.dismiss(animated: true, completion: {})
                
                // リクエスト画面へ
                self.performSegue(withIdentifier: "toUserRequestSegue2", sender: nil)
            }
            
            // ダイアログ表示
            confV.showNotice("確認", subTitle: "リクエストが医院から削除されました。\n再度、リクエスト先を選んでください。")
        }
    }
    
    // 有効期限切れ
    func showPurchase() {
        
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // 移動ボタン
        confV.addButton("お支払い画面へ"){
            // 自身を閉じる
            confV.dismiss(animated: true, completion: {})
            
            // リクエスト画面へ
            self.performSegue(withIdentifier: "toPurchase1Segue", sender: nil)
        }
        
        confV.addButton("閉じる"){
            confV.dismiss(animated: true, completion: {})
        }
        // ダイアログ表示
        confV.showWarning("期限切れ", subTitle: "利用ライセンスの有効期限切れです。\n継続利用する場合は設定→支払い情報からライセンス購入をお願い致します。")
    }
    
    // 事前通知
    func showPurchaseInAdvance() {
        
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // 移動ボタン
        confV.addButton("お支払い画面へ"){
            // 自身を閉じる
            confV.dismiss(animated: true, completion: {})
            
            // リクエスト画面へ
            self.performSegue(withIdentifier: "toPurchase1Segue", sender: nil)
        }
        
        confV.addButton("閉じる"){
            confV.dismiss(animated: true, completion: {})
        }
        // ダイアログ表示
        confV.showInfo("確認", subTitle: "利用ライセンスの有効期限が間近です。\n継続利用する場合は設定→支払い情報からライセンス購入をお願い致します。")
    }
}

extension MainVC: FBUserManagerImageDelegate, FBUserManagerDelegate {
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

// ウォークスルーの設定
extension MainVC: BWWalkthroughViewControllerDelegate {
    func showDoctorWalk() {
        // Walkthrough.storyboard のインスタンス作成
        let stb = UIStoryboard(name: "DoctorWalk", bundle: nil)
        
        // 先程設定した Storyboard ID を元に Storyboard内の ViewController を呼び出す
        walkthrough = (stb.instantiateViewController(withIdentifier: "doctorwalk") as! BWWalkthroughViewController)
        walkthrough.delegate = self
        let page_zero = stb.instantiateViewController(withIdentifier: "doctorwalk0")
        let page_one = stb.instantiateViewController(withIdentifier: "doctorwalk1")
        let page_two = stb.instantiateViewController(withIdentifier: "doctorwalk2")
        let page_three = stb.instantiateViewController(withIdentifier: "doctorwalk3")
        let page_four = stb.instantiateViewController(withIdentifier: "doctorwalk4")
        let page_five = stb.instantiateViewController(withIdentifier: "doctorwalk5")
        
        // Walkthrough.storyboard の 1枚目の ViewController に delegateを設定
        walkthrough.delegate = self
        
        // ウォークスルーに載せたいページを追加していく
        walkthrough.add(viewController:page_zero)
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        walkthrough.add(viewController:page_four)
        walkthrough.add(viewController:page_five)
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    func showCustomerWalk() {
        // Walkthrough.storyboard のインスタンス作成
        let stb = UIStoryboard(name: "UserWalk", bundle: nil)
        
        // 先程設定した Storyboard ID を元に Storyboard内の ViewController を呼び出す
        walkthrough = (stb.instantiateViewController(withIdentifier: "userwalk") as! BWWalkthroughViewController)
        walkthrough.delegate = self
        let page_zero = stb.instantiateViewController(withIdentifier: "userwalk0")
        let page_one = stb.instantiateViewController(withIdentifier: "userwalk1")
        let page_two = stb.instantiateViewController(withIdentifier: "userwalk2")
        let page_three = stb.instantiateViewController(withIdentifier: "userwalk3")
        
        // Walkthrough.storyboard の 1枚目の ViewController に delegateを設定
        walkthrough.delegate = self
        
        // ウォークスルーに載せたいページを追加していく
        walkthrough.add(viewController:page_zero)
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    func walkthroughPageDidChange(_ pageNumber: Int) {
        print(pageNumber)
        if (pageNumber + 1) == walkthrough.numberOfPages {
            walkthrough.closeButton?.setTitle("閉じる", for: .normal)
            
        } else {
            walkthrough.closeButton?.setTitle("スキップ", for: .normal)
        }
    }
    
    func walkthroughCloseButtonPressed() {
        walkthrough.dismiss(animated: true, completion: nil)
    }
}

