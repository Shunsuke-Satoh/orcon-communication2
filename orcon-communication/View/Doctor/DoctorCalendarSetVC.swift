//
//  DoctorCalendarSetViewController.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/13.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import SCLAlertView

class DoctorCalendarSetViewController: UIViewController,UIPopoverPresentationControllerDelegate {
    
    var kindModelDisp:[CalKindModel] = []
    var isAdd = false
    var selectedRow = 0
    
    @IBOutlet weak var color1: EnhancedCircleImageView!
    @IBOutlet weak var color2: EnhancedCircleImageView!
    @IBOutlet weak var color3: EnhancedCircleImageView!
    @IBOutlet weak var color4: EnhancedCircleImageView!
    @IBOutlet weak var openTime1: UILabel!
    @IBOutlet weak var openTime2: UILabel!
    @IBOutlet weak var openTime3: UILabel!
    @IBOutlet weak var closeFlg1: UILabel!
    @IBOutlet weak var closeFlg2: UILabel!
    @IBOutlet weak var closeFlg3: UILabel!
    @IBOutlet weak var closeTime1: UILabel!
    @IBOutlet weak var closeTime2: UILabel!
    @IBOutlet weak var closeTime3: UILabel!
    
    var colors: [EnhancedCircleImageView] = []
    var openTimes: [UILabel] = []
    var closeFlgs: [UILabel] = []
    var closeTimes: [UILabel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "診療日種別の選択"
        
        colors.append(color1)
        colors.append(color2)
        colors.append(color3)
        colors.append(color4)
        openTimes.append(openTime1)
        openTimes.append(openTime2)
        openTimes.append(openTime3)
        closeFlgs.append(closeFlg1)
        closeFlgs.append(closeFlg2)
        closeFlgs.append(closeFlg3)
        closeTimes.append(closeTime1)
        closeTimes.append(closeTime2)
        closeTimes.append(closeTime3)
        
        
        dataLoad()
        // Do any additional setup after loading the view.
    }
    
    func dataLoad() {
        kindModelDisp = RealmManager.getInstance().getKindModelsOrderByKindNum()
        
        // 色設定
        for (indx,kindMdl) in kindModelDisp.enumerated() {
            colors[indx].backgroundColor = CommonUtils.uiColor(kindMdl)
        }
        
        for (indx, _) in openTimes.enumerated() {
            let kindMdl = kindModelDisp[indx]
            
            openTimes[indx].text = kindMdl.open[0].StartHHmm + " 〜 " + kindMdl.open[0].EndHHmm
            
            if kindMdl.closeFlg {
                closeTimes[indx].text = kindMdl.close[0].StartHHmm + " 〜 " + kindMdl.close[0].EndHHmm
                
                closeFlgs[indx].isHidden = true
                closeTimes[indx].isHidden = false
            } else {
                closeFlgs[indx].isHidden = false
                closeTimes[indx].isHidden = true
            }
        }
    }
    @IBAction func touch1(_ sender: Any) {
        selectedRow = 0
        commonSegue()
    }
    @IBAction func touch2(_ sender: Any) {
        selectedRow = 1
        commonSegue()
    }
    @IBAction func touch3(_ sender: Any) {
        selectedRow = 2
        commonSegue()
    }
    @IBAction func touch4(_ sender: Any) {
        selectedRow = 3
        commonSegue()
    }
    
    func commonSegue() {
        isAdd = false
        // 画面遷移
        performSegue(withIdentifier: "DoctorCalendarKindPop", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DoctorCalendarKindPop" {
            
            let popVC = segue.destination as! DoctorCalendarKindVC

            popVC.calKindMdl = kindModelDisp[selectedRow]
            
            popVC.delegate = self
            popVC.isAdd = isAdd
            popVC.row = selectedRow
        }
    }
}

extension DoctorCalendarSetViewController: DoctorCalKindPopDelegate {
    func save(mdl: CalKindModel) {
        dataLoad()
    }
    
    func add(mdl: CalKindModel) {
        dataLoad()
    }
    
    func addAllClose(mdl: CalKindModel) {
        dataLoad()
    }
    
    func delete() {
        // 他のkindNumを変更する
        kindModelDisp.remove(at: selectedRow)
        for (newKindNum, kindMdl) in kindModelDisp.enumerated() {
            // kindNumは1から始まるので行番号＋１で付け替える
            RealmManager.getInstance().updateKindModelKindNum(mdl: kindMdl, newKindNum: newKindNum + 1)
        }
        
        dataLoad()
    }
}
