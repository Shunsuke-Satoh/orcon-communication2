//
//  AcountEntryCompleteViewController.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/12.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class AcountEntryCompleteViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // ユーザタイプによって画面分岐
    @IBAction func toNextSegue(_ sender: Any) {
        let userDM = UserDefaultManager()
        
        let realmDM = RealmManager.getInstance()
        let userModel = realmDM.getUserModelByUserId(userId: userDM.getOwnUserId())
        
        if userModel?.userType == Constant.userTypeCustomer {
            performSegue(withIdentifier: "toRequestSegue", sender: nil)
        } else {
            
            performSegue(withIdentifier: "toMainSegue", sender: nil)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
