//
//  DoctorCalendarKindPopVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/29.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import MKColorPicker
import SCLAlertView

class DoctorCalendarKindVC: UIViewController {
    var delegate:DoctorCalKindPopDelegate?
    
    var colorPicker:ColorPickerViewController!
    
    @IBOutlet weak var kindTitle: UILabel!
    @IBOutlet weak var colorImg: EnhancedCircleImageView!
    @IBOutlet weak var openStart: UIDatePicker!
    @IBOutlet weak var openEnd: UIDatePicker!
    @IBOutlet weak var closeSW: UISwitch!
    @IBOutlet weak var closeStart: UIDatePicker!
    @IBOutlet weak var closeEnd: UIDatePicker!
    @IBOutlet weak var closeView: UIView!
//    @IBOutlet weak var allCloseBtn: UIButton!
//    @IBOutlet weak var deleteBtn: UIButton!
    
    var calKindMdl:CalKindModel!
    var isAdd = true
    var row = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "診療日種別の設定"
        
        // カラーピッカーの初期化
        colorPicker = ColorPickerViewController()
        colorPicker.selectedColor = {color in
            self.colorImg.backgroundColor = color
        }
        
        // 追加時の初期化
        if isAdd {
            calKindMdl = CalKindModel()
            calKindMdl.kindNum = row
            // 追加時の削除は無効化
//            deleteBtn.isHidden = true
        } else {
            // 追加時のみ休診日の設定を許す
//            allCloseBtn.isHidden = true
        }
        
        // タイトル
        kindTitle.text = calKindMdl.getTitle()
        
        // 休診日の場合はほとんど表示しない
        if calKindMdl.allCloseFlg {
            openStart.isHidden = true
            openEnd.isHidden = true
            closeView.isHidden = true
            closeSW.isHidden = true
            
            colorImg.backgroundColor = UIColor(red: calKindMdl.color_r, green: calKindMdl.color_g, blue: calKindMdl.color_b, alpha: 1)
            
            return
        }
        
        let yyyy_mm_dd_hh_mm_ss = DateUtils.stringFromDate(Date())
        let yyyy_mm_dd_ = yyyy_mm_dd_hh_mm_ss.prefix(11)
        
        if !isAdd {
            openStart.date = DateUtils.dateFromString(yyyy_mm_dd_ + calKindMdl.open[0].StartHHmm + ":00")
            openEnd.date = DateUtils.dateFromString(yyyy_mm_dd_ + calKindMdl.open[0].EndHHmm + ":00")
            
            colorImg.backgroundColor = UIColor(red: calKindMdl.color_r, green: calKindMdl.color_g, blue: calKindMdl.color_b, alpha: 1)
        }else {
            openStart.date = DateUtils.dateFromString(yyyy_mm_dd_ + "09:00:00")
            openEnd.date = DateUtils.dateFromString(yyyy_mm_dd_ + "17:00:00")
        }
        
        if calKindMdl.closeFlg {
            closeStart.date = DateUtils.dateFromString(yyyy_mm_dd_ + calKindMdl.close[0].StartHHmm + ":00")
            closeEnd.date = DateUtils.dateFromString(yyyy_mm_dd_ + calKindMdl.close[0].EndHHmm + ":00")
            closeSW.isOn = true
        } else {
            closeSW.isOn = false
            closeStart.date = DateUtils.dateFromString(yyyy_mm_dd_ + "12:00:00")
            closeEnd.date = DateUtils.dateFromString(yyyy_mm_dd_ + "13:00:00")
        }
        
        //分刻みを15分に
        openStart.minuteInterval = 15
        openEnd.minuteInterval = 15
        closeStart.minuteInterval = 15
        closeEnd.minuteInterval = 15
        
        // 休憩表示有無の再描画
        showOrHidden()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // 休診日 追加時が保証されている
//    @IBAction func tapAllClose(_ sender: UIButton) {
//        var forInsertMdl:CalKindModel!
//        forInsertMdl = calKindMdl
//        
//        // キー情報の生成
//        forInsertMdl.doctorId = UserDefaultManager().getOwnUserId()
//        forInsertMdl.kindId = UUID().uuidString
//        forInsertMdl.kindNum = row
//        
//        // 休診日の設定
//        forInsertMdl.allCloseFlg = true
//        
//        // 色の設定
//        forInsertMdl.color_r = (colorImg.backgroundColor?.redValue)!
//        forInsertMdl.color_g = (colorImg.backgroundColor?.greenValue)!
//        forInsertMdl.color_b = (colorImg.backgroundColor?.blueValue)!
//        
//        // Realmに保存
//        RealmManager.getInstance().insertUpdateKind(forInsertMdl)
//        
//        delegate?.addAllClose(mdl: forInsertMdl)
//        
//        dismiss(animated: true, completion: {})
//    }
    // 削除
//    @IBAction func tapDelete(_ sender: Any) {
//        // ポップアップを準備
//        let appearance = SCLAlertView.SCLAppearance(
//            showCloseButton:false
//        )
//
//        let confV = SCLAlertView(appearance: appearance)
//
//        // 削除ボタン
//        confV.addButton("はい"){
//            // 削除処理へ
//            RealmManager.getInstance().deleteKind(kindId: self.calKindMdl.kindId)
//            self.delegate?.delete()
//
//            confV.dismiss(animated: true, completion: {})
//            self.dismiss(animated: true, completion: {})
//        }
//
//        // キャンセルボタン
//        confV.addButton("いいえ"){
//            confV.dismiss(animated: true, completion: {})
//        }
//
//        // ダイアログ表示
//        confV.showNotice("確認", subTitle: "削除しますか？")
//
//    }
    
    @IBAction func tapSave(_ sender: UIButton) {
        var forInsertMdl:CalKindModel!
        
        if isAdd{
            forInsertMdl = calKindMdl
            
            // キー情報の生成
            forInsertMdl.doctorId = UserDefaultManager().getOwnUserId()
            forInsertMdl.kindId = UUID().uuidString
            forInsertMdl.kindNum = row
        } else {
            // キー情報のコピー
            forInsertMdl = CalKindModel()
            forInsertMdl.kindId = calKindMdl.kindId
            forInsertMdl.doctorId = calKindMdl.doctorId
            forInsertMdl.kindNum = calKindMdl.kindNum
            forInsertMdl.allCloseFlg = calKindMdl.allCloseFlg
        }
        
        // 色情報
        forInsertMdl.color_r = (colorImg.backgroundColor?.redValue)!
        forInsertMdl.color_g = (colorImg.backgroundColor?.greenValue)!
        forInsertMdl.color_b = (colorImg.backgroundColor?.blueValue)!
        
        // 休診日以外は他もセット
        if forInsertMdl.allCloseFlg == false{
        
            forInsertMdl.closeFlg = closeSW.isOn
            
            // 営業時間
            let kindOPMdl = CalKindOpenCloseModel()
            // キー情報
            kindOPMdl.opencloseType = "open"
            // numは複数に対応する時の連番なので今は1固定
            kindOPMdl.num = 1
            kindOPMdl.kindId_openclose_num = forInsertMdl.kindId + "_" + "open_" + kindOPMdl.num.description
            // 時間
            kindOPMdl.StartHHmm = String(DateUtils.stringFromDate(openStart.date).suffix(8).prefix(5))
            kindOPMdl.EndHHmm = String(DateUtils.stringFromDate(openEnd.date).suffix(8).prefix(5))
            
            forInsertMdl.open.append(kindOPMdl)
            
            // 休憩があったら休憩も写して保存
            if closeSW.isOn {
                let kindCLMdl = CalKindOpenCloseModel()
                // キー情報
                kindCLMdl.opencloseType = "close"
                // numは複数に対応する時の連番なので今は1固定
                kindCLMdl.num = 1
                kindCLMdl.kindId_openclose_num = forInsertMdl.kindId + "_" + "close_" + kindCLMdl.num.description
                // 時間
                kindCLMdl.StartHHmm = String(DateUtils.stringFromDate(closeStart.date).suffix(8).prefix(5))
                kindCLMdl.EndHHmm = String(DateUtils.stringFromDate(closeEnd.date).suffix(8).prefix(5))
                
                forInsertMdl.close.append(kindCLMdl)
            }
        }
        
        // realm保存
        RealmManager.getInstance().insertUpdateKind(forInsertMdl)
        
        if isAdd {
            delegate?.add(mdl:forInsertMdl)
        }else {
            delegate?.save(mdl: forInsertMdl)
        }
        
        self.navigationController?.popViewController(animated: true)
//        dismiss(animated: true, completion: {})
    }
    @IBAction func tapCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapSW(_ sender: UISwitch) {
        showOrHidden()
    }
    
    func showOrHidden() {
        if closeSW.isOn {
            closeView.isHidden = false
        } else {
            closeView.isHidden = true
        }
    }
    
    @IBAction func showPickerC(_ sender: UITapGestureRecognizer) {
        
        if let popoverC = colorPicker.popoverPresentationController{
            popoverC.delegate = colorPicker
            popoverC.permittedArrowDirections = .any
            popoverC.sourceView = colorImg
            popoverC.sourceRect = colorImg.bounds
        }
        self.present(colorPicker, animated:true,completion:nil)
    }
}

protocol DoctorCalKindPopDelegate {
    func save(mdl:CalKindModel)
    func add(mdl:CalKindModel)
    func delete()
    func addAllClose(mdl:CalKindModel)
}
