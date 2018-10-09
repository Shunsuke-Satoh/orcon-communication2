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

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    var kindModelDisp:[CalKindModel] = []
    var isAdd = false
    var selectedRow = 0
    var selectedCell:CalendarKindCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "診療日種別の選択"
        
        dataLoad()
        // Do any additional setup after loading the view.
    }
    
    func dataLoad() {
        kindModelDisp = RealmManager.getInstance().getKindModelsOrderByKindNum()
        table.reloadData()
    }
    
    // 追加用スクリプト
//    @IBAction func add(_ sender: UIBarButtonItem) {
//        if kindModelDisp.count < 4 {
//            isAdd = true
//            selectedRow = kindModelDisp.count + 1
//            // ポップアップさせる
//            performSegue(withIdentifier: "DoctorCalendarKindPop", sender: nil)
//        }
//        else {
//            // 追加させない
//            // ポップアップを準備
//            let appearance = SCLAlertView.SCLAppearance(
//                showCloseButton:false
//            )
//
//            let confV = SCLAlertView(appearance: appearance)
//            confV.addButton("了解"){
//                confV.dismiss(animated: true, completion: {})
//            }
//            confV.showWarning("警告", subTitle: "種別は４種類までです。")
//        }
//    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DoctorCalendarKindPop" {
            
            let popVC = segue.destination as! DoctorCalendarKindVC
//            popVC.popoverPresentationController?.delegate = self
            
            // 画面サイズ
//            popVC.preferredContentSize = CGSize(width:self.view.frame.width * 0.95, height:300)
            
            // 表示位置
//            if isAdd {
//                popVC.popoverPresentationController?.sourceView = navBar
//
//                popVC.popoverPresentationController?.sourceRect = navBar.bounds
//            } else {
//                popVC.popoverPresentationController?.sourceView = selectedCell
//
//                popVC.popoverPresentationController?.sourceRect = selectedCell!.bounds
//            }
            popVC.calKindMdl = kindModelDisp[selectedRow]
            
            popVC.delegate = self
            popVC.isAdd = isAdd
            popVC.row = selectedRow
        }
    }
//    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
//        return .none
//    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // 戻るボタン
    @IBAction func back(_ sender: UIBarButtonItem) {
        let navi = self.navigationController!
        navi.popViewController(animated: true)
    }
    
}

extension DoctorCalendarSetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kindModelDisp.count
    }
    
    // セルの表示
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // ストーリーボードで指定したidが必要
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarKindCell") as! CalendarKindCell
        
        let kindMdl = kindModelDisp[indexPath.row]
        
        // 種別タイトル設定
        cell.titleLbl.text = kindMdl.getTitle()
        
        // 色設定
        cell.colorImg.backgroundColor = CommonUtils.uiColor(kindMdl)
        
        // 休診日の場合はほとんど表示しない
        if kindMdl.allCloseFlg {
            cell.openLbl.isHidden = true
            cell.closeLbl.isHidden = true
            cell.yasumiUmuLbl.isHidden = true
            
            return cell
        }
        
        // 営業開始時間
        cell.openLbl.isHidden = false
        cell.openLbl.text = kindMdl.open[0].StartHHmm + " 〜 " + kindMdl.open[0].EndHHmm
        
        // 休診時間
        cell.closeLbl.isHidden = true
        cell.yasumiUmuLbl.isHidden = false
        
        if kindMdl.closeFlg {
            cell.closeLbl.text = kindMdl.close[0].StartHHmm + " 〜 " + kindMdl.close[0].EndHHmm
            
            cell.closeLbl.isHidden = false
            cell.yasumiUmuLbl.isHidden = true
        }
        
        return cell
    }
    
    // 選択時の動作
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        isAdd = false
        selectedRow = indexPath.row
        selectedCell = (table.cellForRow(at: indexPath) as! CalendarKindCell)
        table.deselectRow(at: indexPath, animated: false)
        // ポップアップさせる
        performSegue(withIdentifier: "DoctorCalendarKindPop", sender: nil)
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
