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
    @IBOutlet weak var mySearchBar: UISearchBar!
    
    
    let realmDM = RealmManager.getInstance()
    let userDM = UserDefaultManager()
    
    var doctors:[UserModel] = []
    var searchResults:[UserModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "医院の検索"
        
        // デリゲート
        tableView.delegate = self
        tableView.dataSource = self
        mySearchBar.delegate = self
        FBUserManager.getInstance().delegateImg = self
        
        searchResults = doctors
        
//        load()
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
    
    // 検索件数＝セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return searchResults.count
    }
    
    // セクション内の行は1か0
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchResults.count > 0 {
            return 1
        }
        return searchResults.count
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var ret = UITableViewCell()
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "doctorCell") as? DoctorCell{
//            let row = indexPath.row
            let row = indexPath.section
            cell.clinicName.text = searchResults[row].clinicName
            cell.iconImg.image = userDM.loadImageIcon(userId: searchResults[row].userId)
            cell.topImg.image = userDM.loadImageTop(userId:searchResults[row].userId)
            cell.userId = searchResults[row].userId
            
            ret = cell
        }
        
        return ret
    }
    
    // 選択時の動作
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        performSegue(withIdentifier: "toRequestSendSegue", sender: searchResults[indexPath.section].userId)
    }
    
    // セクションヘッダー行間
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    // セクションヘッダータイトル
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section + 1).description + "件目"
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let v = view as? UITableViewHeaderFooterView
        v?.textLabel?.frame = (v?.frame)!
        v?.textLabel?.textAlignment = .center
        v?.backgroundColor = .white
    }
    
    // 検索ボックスの編集による検索
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        searchResults.removeAll()
//        for doc in doctors {
//            if doc.clinicName.contains(mySearchBar.text!) {
//                searchResults.append(doc)
//            }
//        }
//        tableView.reloadData()
//    }
    
    // 検索ボックスによる検索
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        if searchBar.text! != "" {
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton:false
            )
            let waitView = SCLAlertView(appearance: appearance)
            let waitViewRes = waitView.showWait("クラウド検索中", subTitle: "")
            FBUserManager.getInstance().searchAndSaveRealmDoctorInfo(searchBar.text!, callback: {
                self.doctors = self.realmDM.getDoctors()
                self.searchResults.removeAll()
                for doc in self.doctors {
                    if doc.clinicName.contains(self.mySearchBar.text!) || doc.clinicAddress.contains(self.mySearchBar.text!) {
                        self.searchResults.append(doc)
                    }
                }
                self.tableView.reloadData()
                waitViewRes.close()
            })
        }
    }
    
    // 遷移先にドクターIDを渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! UserRequestSendVC
        vc.doctorId = sender as! String
    }
}

extension UserRequestVC: FBUserManagerImageDelegate {
    func compTopImg(userId: String) {
        tableView.reloadData()
    }
    
    func compIconImg(userId: String) {
        tableView.reloadData()
    }
}
