//
//  DoctorUserMVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/26.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import SCLAlertView

class DoctorRequestMVC: UIViewController,UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate,UIPopoverPresentationControllerDelegate,UIGestureRecognizerDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var table: UITableView!
    
    let realmDM = RealmManager.getInstance()
    let userDM = UserDefaultManager()

    var customers:[UserModel] = []
    var searchResults:[UserModel] = []
    var requests:[RequestModel] = []
    
    var selectedUserId = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "患者さん管理"
        
        // データロード
        dataLoad()
        
        // 背景画像のために透過
        table.backgroundColor = UIColor(red:1,green:1,blue:1,alpha:0.5)
        
        // デリゲート
        FBRequestManager.getInstance().delegate = self
        FBUserManager.getInstance().delegateImg = self
        FBUserManager.getInstance().delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    func dataLoad() {
        customers.removeAll()
        requests = realmDM.getRequestsByDoctorId(doctorId: userDM.getOwnUserId())
        for request in requests {
            if let user = realmDM.getUserModelByUserId(userId: request.customerId) {
                customers.append(user)
            }
        }
        
        // 現在の検索条件で検索、リロード
        searchCommon()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // ストーリーボードで指定したidが必要
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserRequestCell") as! UserRequestCell
        
        let userMdl = searchResults[indexPath.row]
        cell.nameLbl.text = userMdl.name
        cell.iconImg.image = userDM.loadImageIcon(userId: userMdl.userId)
        cell.checkImg.isHidden = true
        
        // 治療完了のみチェックマークをつける
        if userMdl.status == Constant.statusComp {
            cell.checkImg.isHidden = false
        }
        
        // セルの背景は完全透過
        cell.backgroundColor = UIColor.clear
        
        return cell
    }
    // 選択時の動作
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        // ポップアップさせる
        performSegue(withIdentifier: "popRequestUser", sender: indexPath)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "popRequestUser" {
            let index = sender as! IndexPath
            let row = index.row
            
            let popVC = segue.destination as! UserRequestPopVC
            popVC.popoverPresentationController?.delegate = self
            
            // 画面サイズ
            popVC.preferredContentSize = CGSize(width:self.view.frame.width * 0.8, height:self.view.frame.height * 0.8)
            
            // 表示位置
            popVC.popoverPresentationController?.sourceView = searchBar
            
            popVC.popoverPresentationController?.sourceRect = searchBar.bounds
            
            
            let user = searchResults[row]
            popVC.user = user
            popVC.image = userDM.loadImageIcon(userId: user.userId)
        }
    }
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // 検索ボックスによる検索
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCommon()
    }
    
    // スコープバーによる検索
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.view.endEditing(true)
        searchCommon()
    }
    
    func searchCommon() {
        var keyWord = ""
        if !searchBar.text!.isEmpty {
            keyWord = searchBar.text!
        }
        
        switch searchBar.selectedScopeButtonIndex {
        case 0:
            searchResults = customers.filter({user -> Bool in
                if keyWord == "" {
                    return true
                }
                return user.name.contains(keyWord) || user.hira.contains(keyWord)
            })
        case 1:
            searchResults = customers.filter({user -> Bool in
                if keyWord == "" {
                    return user.status == Constant.statusRequest
                }
                return (user.name.contains(keyWord)  || user.hira.contains(keyWord)) && user.status == Constant.statusRequest
            })
        case 2:
            searchResults = customers.filter({user -> Bool in
                if keyWord == "" {
                    return user.status == Constant.statusTreat
                }
                return (user.name.contains(keyWord)  || user.hira.contains(keyWord)) && user.status == Constant.statusTreat
            })
        case 3:
            searchResults = customers.filter({user -> Bool in
                if keyWord == "" {
                    return user.status == Constant.statusComp
                }
                return (user.name.contains(keyWord) || user.hira.contains(keyWord)) && user.status == Constant.statusComp
            })
        default:
            break
        }
        table.reloadData()
    }
}

extension DoctorRequestMVC: FBRequestManagerDelegate {
    func requestUpdated(reqModel:RequestModel){
        dataLoad()
    }
    func requestInserted(reqModel:RequestModel){
        dataLoad()
    }
    func requestDeleted(doctorId:String, customerId:String){
        dataLoad()
    }
}


extension DoctorRequestMVC: FBUserManagerImageDelegate, FBUserManagerDelegate {
    func compTopImg(userId: String) {
        dataLoad()
    }
    
    func compIconImg(userId: String) {
        dataLoad()
    }
    
    func userUpdated(userModel: UserModel) {
        dataLoad()
    }
    
}
