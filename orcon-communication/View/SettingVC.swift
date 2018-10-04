//
//  SettingVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/02.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class SettingVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAcountChangeSegue" {
            let vc = segue.destination as! AcountEntryViewController
            vc.userType = UserDefaultManager().getOwnUserType()
            navigationController?.isNavigationBarHidden = false
        }
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
