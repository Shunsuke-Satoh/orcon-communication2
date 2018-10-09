//
//  UserRequestVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/25.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import SCLAlertView

class UserRequestVC: UIViewController,UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectedLbl: UILabel!
    @IBOutlet weak var requestBtn: UIButton!
    @IBOutlet weak var mySearchBar: UISearchBar!
    
    
    let realmDM = RealmManager.getInstance()
    let userDM = UserDefaultManager()
    
    var doctors:[UserModel] = []
    var searchResults:[UserModel] = []
    
    var selectedUserId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        mySearchBar.delegate = self
        searchResults = doctors
        requestBtn.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        load()
    }
    
    func load() {
        // ローディング画面
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        let waitView = SCLAlertView(appearance: appearance)
        let successView = SCLAlertView(appearance: appearance)
        let failView = SCLAlertView(appearance: appearance)
        // ボタン追加
        successView.addButton("OK"){
            self.doctors = self.realmDM.getDoctors()
            successView.dismiss(animated: true, completion: {})
        }
        failView.addButton("OK"){
            failView.dismiss(animated: true, completion: {})
        }
        
        let waitViewRes = waitView.showWait("医院情報を取得中です", subTitle: "")
        
        //ロード
        FBUserManager.getInstance().downloadAndSaveRealmDoctorInfo(callback: {(isSuccess, errorMsg) in
            
            waitViewRes.close()
            
            // ローディング成功 or ローディング失敗
            if isSuccess {
                successView.showSuccess("医院情報の取得に成功しました", subTitle: "")
            } else {
                failView.showError("医院情報の取得に失敗しました", subTitle: errorMsg)
            }
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var ret = UITableViewCell()
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "doctorCell") as? DoctorCell{
            cell.clinicName.text = searchResults[indexPath.row].clinicName
            cell.iconImg.image = userDM.loadImageIcon(userId: searchResults[indexPath.row].userId)
            cell.topImg.image = userDM.loadImageTop(userId:searchResults[indexPath.row].userId)
            cell.userId = searchResults[indexPath.row].userId
            
            ret = cell
        }
        
        return ret
    }
    
    // 選択時の動作
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        selectedLbl.text = searchResults[indexPath.row].clinicName
        selectedUserId = searchResults[indexPath.row].userId
        requestBtn.isEnabled = true
    }
    
    // 検索ボックスの編集による検索
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResults.removeAll()
        for doc in doctors {
            if doc.clinicName.contains(mySearchBar.text!) {
                searchResults.append(doc)
            }
        }
        requestBtn.isEnabled = false
        selectedLbl.text = ""
        selectedUserId = ""
        tableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        if searchBar.text! != "" {
//            FBUserManager.getInstance().searchAndSaveRealmDoctorInfo(searchBar.text!, callback: {
//                self.load()
//            })
//        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    // リクエスト
    @IBAction func request(_ sender: UIButton) {
        // サーバアップロード
        FBRequestManager.getInstance().uploadRequestFromCustomerToDoctor(doctorId: selectedUserId)
        // Realm保存
        let realmDM = RealmManager.getInstance()
        realmDM.insertRequest(customerId: userDM.getOwnUserId(), doctorId: selectedUserId, requestDate: Date(), isConfirm: false, confirmDate: nil)

        // push通知
        let topicName = CommonUtils.getReqDoctorTopicName(doctorId: selectedUserId)
        let userMdl = realmDM.getUserModelByUserId(userId: userDM.getOwnUserId())!
        CommonUtils.postDataMessage(topicName: topicName, title: userMdl.name + "さんからリクエストが届きました", body: "", callback: {(_) in})
        
        // push受け取りのためトピック参加
        CommonUtils.getInstance().signInTockenToRequest(false)
        // リスナー登録
        FBRequestManager.getInstance().setRequestObserver(doctorId: selectedUserId, customerId: userDM.getOwnUserId())
        // 関係無いドクター情報を消去
        let doctors = realmDM.getDoctors()
        for doc in doctors {
            if doc.userId != selectedUserId {
                FBUserManager.getInstance().removeObserver(doc.userId)
                realmDM.deleteUserModel(doc.userId)
            }
        }
        
        // 画面遷移
        performSegue(withIdentifier: "toUserMainSegue", sender: nil)
    }
}

extension UserRequestVC: FBUserManagerImageDelegate {
    func compTopImg(userId: String) {
        
    }
    
    func compIconImg(userId: String) {
        
    }
}
