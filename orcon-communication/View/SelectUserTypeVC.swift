//
//  SelectUserTypeVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/24.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class SelectUserTypeVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    // 次画面への情報渡し
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUserEntrySegue" {
            let vc = segue.destination as! AcountEntryViewController
            
            vc.userType = Constant.userTypeCustomer
        } else if segue.identifier == "toDoctorEntrySegue" {
            let vc = segue.destination as! AcountEntryViewController
            
            vc.userType = "doctor"
        } else {
            // TODO
        }
    }

}
