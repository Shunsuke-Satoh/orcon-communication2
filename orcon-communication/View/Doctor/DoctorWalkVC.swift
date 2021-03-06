//
//  TestVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/06.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import BWWalkthrough

class DoctorWalkVC: UIViewController, BWWalkthroughViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func showWalkthrough(){
        
        // Walkthrough.storyboard のインスタンス作成
        let stb = UIStoryboard(name: "DoctorWalk", bundle: nil)
        
        // 先程設定した Storyboard ID を元に Storyboard内の ViewController を呼び出す
        let walkthrough = stb.instantiateViewController(withIdentifier: "doctorwalk") as! BWWalkthroughViewController
        let page_one = stb.instantiateViewController(withIdentifier: "doctorwalk1")
        let page_two = stb.instantiateViewController(withIdentifier: "doctorwalk2")
        let page_three = stb.instantiateViewController(withIdentifier: "doctorwalk3")
        let page_four = stb.instantiateViewController(withIdentifier: "doctorwalk4")
        let page_five = stb.instantiateViewController(withIdentifier: "doctorwalk5")
        
        // Walkthrough.storyboard の 1枚目の ViewController に delegateを設定
        walkthrough.delegate = self
        
        // ウォークスルーに載せたいページを追加していく
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        walkthrough.add(viewController:page_four)
        walkthrough.add(viewController:page_five)
        
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    func walkthroughPageDidChange(_ pageNumber: Int) {
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
}
