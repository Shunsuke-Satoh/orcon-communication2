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

class MainVC: UIViewController {
    @IBOutlet weak var clinicNameLbl: UILabel!
    @IBOutlet weak var clinicIconImg: UIImageView!
    @IBOutlet weak var clinicTopImg: UIImageView!
    @IBOutlet weak var icon_comment: UIImageView!
    @IBOutlet weak var requestLbl: UILabel!
    @IBOutlet weak var icon_request: UIImageView!
    @IBOutlet weak var calendarBtn: UIButton!
    @IBOutlet weak var requestBtn: UIButton!
    @IBOutlet weak var chatBtn: UIButton!
    
    var name: String = ""
    var clinicName: String = ""
    var topImg: UIImage!
    var iconImg: UIImage!
    
    let userDM = UserDefaultManager()
    let realmDM = RealmManager.getInstance()
    let imgM = FBStorageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.title = "メイン"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        dataReload()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // チャットボタンの行き先はドクター、カスタマーで違う
    @IBAction func tapChat(_ sender: UIButton) {
        if CommonUtils.isUserTypeUser(){
            if let rooms = RealmManager.getInstance().getChatRoomModels() {
                performSegue(withIdentifier: "toChatViewUserSegue", sender: rooms[0].roomId)
            }
        } else if CommonUtils.isUserTypeDoctor() {
            performSegue(withIdentifier: "toChatListSegue", sender: nil)
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
                chatBtn.isHidden = false
                if requestModel.requestConfirm == false {
                    requestLbl.isHidden = false // ラベルの表示
                    
                    chatBtn.isHidden = true
                } else {
                    // リクエストのリスナー登録
                    FBRequestManager.getInstance().setRequestObserver(doctorId: requestModel.doctorId, customerId: requestModel.customerId)
                }
                
                calendarBtn.isHidden = true
                requestBtn.isHidden = true
            }
        }
        
        // 未読アイコンの更新
        midokuUpdate()
        // リクエスト承認の更新
        requestUpdate()
    }
    
    func midokuUpdate(){
        icon_comment.isHidden = true
        
        for room in RealmManager.getInstance().getChatRoomModels()! {
            for message in room.messages {
                if message.senderId != userDM.getOwnUserId() && message.read == false{
                    icon_comment.isHidden = false
                    break
                }
            }
            if icon_comment.isHidden == false {
                break
            }
        }
    }
    
    func requestUpdate() {
        icon_request.isHidden = true
        
        for request in RealmManager.getInstance().getRequestsByDoctorId(doctorId: userDM.getOwnUserId()) {
            if request.requestConfirm == false {
                icon_request.isHidden = false
                break
            }
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
            showPopUpAndSegue()
        }
    }
    
    func showPopUpAndSegue() {
        
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
