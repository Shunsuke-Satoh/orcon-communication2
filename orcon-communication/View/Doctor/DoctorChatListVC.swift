//
//  DoctorChatListViewController.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/13.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import MessageKit
import RealmSwift

class DoctorChatListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate {
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let userDM = UserDefaultManager()
    var array:Results<ChatRoomModel>!
    var searchResults:[ChatRoomModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ChatDataManager.getInstance().delegateMsg = self
        
        // 背景画像のために透過
        table.backgroundColor = UIColor(red:1,green:1,blue:1,alpha:0.5)
        
        array = RealmManager.getInstance().getChatRoomModels()
        
        for mdl in array {
            searchResults.append(mdl)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        table.reloadData()
        navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatElement") as! ChatBarCell
        
        let lastMessage = searchResults[indexPath.row].messages.sorted(byKeyPath: "entryDate", ascending: false).first
        
        
        cell.title?.text = searchResults[indexPath.row].otherUser?.name
        
        if searchResults[indexPath.row].otherUser != nil {
            if let userId = searchResults[indexPath.row].otherUser?.userId {
                cell.iconImage.image = userDM.loadImageIcon(userId:userId)
            }
        }
        
        cell.detail.text = lastMessage?.contents
        
        cell.midokuNum.alpha = 0
        var count = 0
        for msg in searchResults[indexPath.row].messages {
            if msg.senderId != userDM.getOwnUserId() && msg.read == false {
                count += 1
            }
        }
        if count > 0 {
            cell.midokuNum.text = count.description
            cell.midokuNum.alpha = 1
        }
        
        // セルの背景は完全透過
        cell.backgroundColor = UIColor.clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toChatViewSegue", sender: searchResults[indexPath.row].roomId)
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
            searchResults = array.filter({chatRoomMdl -> Bool in
                let user = chatRoomMdl.otherUser!
                if keyWord == "" {
                    return user.status == Constant.statusTreat
                }
                
                return user.name.contains(keyWord) && user.status == Constant.statusTreat
            })
        case 1:
            searchResults = array.filter({chatRoomMdl -> Bool in
                let user = chatRoomMdl.otherUser!
                if keyWord == "" {
                    return user.status == Constant.statusComp
                }
                return user.name.contains(keyWord) && user.status == Constant.statusComp
            })
        default:
            break
        }
        table.reloadData()
    }
    
    //MARK: - UITableViewDelegate
    
    
    // Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toChatViewSegue") {
            if let roomId = sender as? String {
                let vc: ChatViewController = (segue.destination as? ChatViewController)!
                vc.roomId = roomId
                
                navigationController?.isNavigationBarHidden  = false
            }
        }
    }
    
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {
        
    }
}

extension DoctorChatListViewController: MessageLoadDelegate {
   func messageUpdated(msgModel: MessageModel) {
        array = RealmManager.getInstance().getChatRoomModels()
        searchResults.removeAll()
        for mdl in array {
            searchResults.append(mdl)
        }
        table.reloadData()
    }
   func messageReaded(msgModel: MessageModel) {
        if msgModel.senderId != userDM.getOwnUserId() {
            array = RealmManager.getInstance().getChatRoomModels()
            searchResults.removeAll()
            for mdl in array {
                searchResults.append(mdl)
            }
            table.reloadData()
        }
    }
}
