//
//  TestVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/06.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import BWWalkthrough

class UserWalkVC: UIViewController, BWWalkthroughViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        let userDefaults = UserDefaults.standard
//
//        if !userDefaults.bool(forKey: "userwalkDone") {
//
//            showWalkthrough()
//
//            userDefaults.set(true, forKey: "userwalkDone")
//            userDefaults.synchronize()
//        }
    }
    
    @IBAction func showWalkthrough(){
        // Walkthrough.storyboard のインスタンス作成
        let stb = UIStoryboard(name: "UserWalk", bundle: nil)
        
        // 先程設定した Storyboard ID を元に Storyboard内の ViewController を呼び出す
        let walkthrough = stb.instantiateViewController(withIdentifier: "userwalk") as! BWWalkthroughViewController
        let page_one = stb.instantiateViewController(withIdentifier: "userwalk1")
        let page_two = stb.instantiateViewController(withIdentifier: "userwalk2")
        let page_three = stb.instantiateViewController(withIdentifier: "userwalk3")
        
        // Walkthrough.storyboard の 1枚目の ViewController に delegateを設定
        walkthrough.delegate = self
        
        // ウォークスルーに載せたいページを追加していく
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        
        self.present(walkthrough, animated: true, completion: nil)
    }
    
    func walkthroughPageDidChange(_ pageNumber: Int) {
//        print("Current Page \(pageNumber)")
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
}
