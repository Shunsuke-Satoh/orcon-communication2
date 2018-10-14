//
//  ReservePopVC.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/30.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import FSCalendar
import CalculateCalendarLogic

class ChatReserveVC: UIViewController {

    @IBOutlet weak var calendar: FSCalendar!
    
    @IBOutlet weak var img1: EnhancedCircleImageView!
    @IBOutlet weak var img2: EnhancedCircleImageView!
    @IBOutlet weak var img3: EnhancedCircleImageView!
    @IBOutlet weak var img4: EnhancedCircleImageView!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var lbl3: UILabel!
    @IBOutlet weak var lbl4: UILabel!
    @IBOutlet weak var kibou1Lbl: UILabel!
    @IBOutlet weak var kibou2Lbl: UILabel!
    @IBOutlet weak var kibou3Lbl: UILabel!
    @IBOutlet weak var kibou1Btn: UIButton!
    @IBOutlet weak var kibou2Btn: UIButton!
    @IBOutlet weak var kibou3Btn: UIButton!
    @IBOutlet weak var kibou1AMBtn: UIButton!
    @IBOutlet weak var kibou2AMBtn: UIButton!
    @IBOutlet weak var kibou3AMBtn: UIButton!
    @IBOutlet weak var kibou1PMBtn: UIButton!
    @IBOutlet weak var kibou2PMBtn: UIButton!
    @IBOutlet weak var kibou3PMBtn: UIButton!
    
    @IBOutlet weak var centerLine1: centerLineView!
    @IBOutlet weak var centerLine2: centerLineView!
    
    var imgs: [EnhancedCircleImageView] = []
    var lbls: [UILabel] = []
    
    var kibouLbls: [UILabel] = []
    var kibouBtns: [UIButton] = []
    var kibouAMBtns: [UIButton] = []
    var kibouPMBtns: [UIButton] = []
    var selectedDates: [Date] = [Date(),Date(),Date()]
    
    var schedules: [ScheduledDateModel] = []
    var kinds:[CalKindModel] = []
    var currentKibouPos = 0
    var doctorId: String!
    var formatter: DateFormatter!
    
    let selectedColor = UIColor(red: 0/255, green: 160/255, blue: 233/255, alpha: 1)
    let nonSelectedColor = UIColor(red: 200/255
        , green:200/255, blue: 200/255, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // センターラインを透明化
        centerLine1.isOpaque = false
        centerLine2.isOpaque = false
        
        // タイトルセット
        navigationItem.title = "予約希望日を選択"
        
        if CommonUtils.isUserTypeDoctor() {
            navigationItem.title = "予約おすすめ日を選択"
        }
        
        // 日付フォーマッタ
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        // スケジュールのロード
        let realmDM = RealmManager.getInstance()

        if CommonUtils.isUserTypeUser() {
            doctorId = realmDM.getRequestByCustomerId(customerId: UserDefaultManager().getOwnUserId())!.doctorId
        } else {
            doctorId = UserDefaultManager().getOwnUserId()
        }
        
        schedules = realmDM.getSchedulesByDoctorId(doctorId: doctorId)
        kinds = realmDM.getKindsByDoctorId(doctorId: doctorId)
        
        // 処理しやすいように配列化
        lbls.append(lbl1)
        lbls.append(lbl2)
        lbls.append(lbl3)
        lbls.append(lbl4)
        
        imgs.append(img1)
        imgs.append(img2)
        imgs.append(img3)
        imgs.append(img4)
        
        kibouLbls.append(kibou1Lbl)
        kibouLbls.append(kibou2Lbl)
        kibouLbls.append(kibou3Lbl)
        
        kibouBtns.append(kibou1Btn)
        kibouBtns.append(kibou2Btn)
        kibouBtns.append(kibou3Btn)
        
        kibouAMBtns.append(kibou1AMBtn)
        kibouAMBtns.append(kibou2AMBtn)
        kibouAMBtns.append(kibou3AMBtn)
        
        kibouPMBtns.append(kibou1PMBtn)
        kibouPMBtns.append(kibou2PMBtn)
        kibouPMBtns.append(kibou3PMBtn)
        
        // 初期化
        // 種別数 4つ固定なので不要かな
        while kinds.count > 4 {
            _ = kinds.popLast()
        }
        // 種別の色、テキスト
        for (indx,kind) in kinds.enumerated() {
            lbls[indx].text = kind.getAllTitleForChat()
            imgs[indx].backgroundColor = CommonUtils.uiColor(kind)
        }
        
        // 希望日
        if CommonUtils.isUserTypeDoctor() {
            for (indx, kiboulbl) in kibouLbls.enumerated() {
                kiboulbl.text = "第" + (indx + 1).description + "おすすめ日"
            }
        }
        
        // 希望ボタン
        for kibouBtn in kibouBtns {
            kibouBtn.setTitle("未選択", for: .normal)
            kibouBtn.layer.borderColor = UIColor.lightGray.cgColor
        }
        setKibouBtn(0)
        
        // AM,PMボタン
        let ampmBtns = kibouAMBtns + kibouPMBtns
        
        for apmpBtn in ampmBtns {
            apmpBtn.isSelected = false
            setColor(apmpBtn)
        }
    }
    
    func setColor(_ btn:UIButton) {
        if btn.isSelected {
            btn.backgroundColor = selectedColor
        } else {
            btn.backgroundColor = nonSelectedColor
        }
    }
    
    // 保存ボタン
    @IBAction func save(_ sender: Any) {
        var message = ""
        if CommonUtils.isUserTypeUser() {
            message += "予約希望日\n"
        }
        else if CommonUtils.isUserTypeDoctor() {
            message += "予約おすすめ\n"
        }
        
        for (indx, kibouBtn) in kibouBtns.enumerated() {
            if kibouBtn.titleLabel?.text == "未選択" {
                break
            }
            var text = kibouLbls[indx].text! + ":"
            text += DateUtils.stringMMddFromDate(selectedDates[indx]) + "（" + formatter.weekdaySymbols[getWeekIdx(selectedDates[indx]) - 1].prefix(1) + "） "
            
            if kibouAMBtns[indx].isSelected && kibouPMBtns[indx].isSelected {
                text += "終日"
            } else if kibouAMBtns[indx].isSelected {
                text += "午前中"
            } else if kibouPMBtns[indx].isSelected {
                text += "午後"
            }
            
            message += text + "\n"
            
        }
        
        let navi = self.navigationController!
        let pre = navi.viewControllers.count - 2
        let vc = navi.viewControllers[pre] as! ChatViewController
        // メッセージ欄に追加
        vc.messageInputBar.inputTextView.text += message
        // メイン画面からいきなり来た時はチャットのviewDidLoadが呼ばれるのでセット
        vc.reserveMessage = message
        self.navigationController!.popViewController(animated: true)
        
    }
    
    @IBAction func left(_ sender: Any) {
        let date = Calendar.current.date(byAdding: .month, value: -1, to: calendar.currentPage)
        calendar.setCurrentPage(date! , animated: true)

    }
    
    @IBAction func right(_ sender: Any) {
        let date = Calendar.current.date(byAdding: .month, value: +1, to: calendar.currentPage)
        calendar.setCurrentPage(date! , animated: true)
    }
    
    // AMPMボタンが押された時の共通処理
    @IBAction func tapAmPmBtn(_ btn:UIButton) {
        if btn.isSelected {
            btn.isSelected = false
        } else {
            btn.isSelected = true
        }
        // 色も変えようね
        setColor(btn)
    }
    func setKibouBtn(_ pos:Int) {
        for btn in kibouBtns {
            btn.layer.borderWidth = 0
            btn.backgroundColor = UIColor.clear
        }
        kibouBtns[pos].layer.borderWidth = 1
//        kibouBtns[pos].backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
    }
    
    @IBAction func tapKibou1Btn(_ sender: UIButton) {
        currentKibouPos = 0
        setKibouBtn(currentKibouPos)
    }
    @IBAction func tapKibou2Btn(_ sender: UIButton) {
        currentKibouPos = 1
        setKibouBtn(currentKibouPos)
    }
    @IBAction func tapKibou3Btn(_ sender: UIButton) {
        currentKibouPos = 2
        setKibouBtn(currentKibouPos)
    }
    
    
}

extension ChatReserveVC:FSCalendarDelegate ,FSCalendarDataSource,FSCalendarDelegateAppearance {
    
    // カレンダーがタップされた時の処理
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        // 画面上に保持している全スケジュールから休診日かどうか調べる
        let dayYYYYMMdd = DateUtils.stringYYYYMMddFromDate(date)
        if let mdl = schedules.filter({scheMdl -> Bool in
            return scheMdl.id_yyyymmdd == dayYYYYMMdd
            
        }).first {
            if mdl.kind != nil && mdl.kind!.allCloseFlg {
                // 休診日は選択できない
                return
            }
        }
        
        // 候補日を上書きする
        // ボタンタイトル変更
        let title = DateUtils.stringMMddFromDate(date) + "（" + formatter.weekdaySymbols[getWeekIdx(date) - 1].prefix(1) + "） "
        kibouBtns[currentKibouPos].setTitle(title, for: .normal)
        
        // AMPMを全てセレクト状態にする
        kibouAMBtns[currentKibouPos].isSelected = true
        kibouPMBtns[currentKibouPos].isSelected = true
        setColor(kibouAMBtns[currentKibouPos])
        setColor(kibouPMBtns[currentKibouPos])
        
        // 選択日を更新
        selectedDates[currentKibouPos] = date
        
        // フォーカスを次の希望順位にずらす 最後まで行ったら0に戻る
        currentKibouPos += 1
        if currentKibouPos >= selectedDates.count {
            currentKibouPos = 0
        }
        setKibouBtn(currentKibouPos)
        
        calendar.reloadData()
    }
    
    // 種別を見て色を表示する
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        
        // 画面上に保持している全スケジュールから表示しようとしているスケジュールがあるか調べる
        let dayYYYYMMdd = DateUtils.stringYYYYMMddFromDate(date)
        if let mdl = schedules.filter({scheMdl -> Bool in
            return scheMdl.id_yyyymmdd == dayYYYYMMdd
            
        }).first {
            // 見つかれば色を返す
            if mdl.kind != nil {
                return CommonUtils.uiColor(mdl.kind!)
            }
        }
        
        return nil
    }
    
    // 選択された日に目印をつける
    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
        for (indx, d) in selectedDates.enumerated() {
            if d == date {
                return "第" + (indx + 1).description
            }
        }
        return nil
    }
    
    // 縦横比が変わった時
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var newHeight = size.height * 0.50
        
        if size.height > size.width {
           newHeight = size.height * 0.54
        }
        
        calendar.frame = CGRect(origin: calendar.frame.origin, size: CGSize(width: newHeight, height: newHeight))
        
        let newCalHeight = newHeight - calendar.preferredHeaderHeight - calendar.preferredWeekdayHeight
        
        calendar.contentView.frame = CGRect(origin: calendar.contentView.frame.origin, size: CGSize(width:newHeight,height:newCalHeight))
        calendar.daysContainer.frame = CGRect(origin: calendar.daysContainer.frame.origin, size: CGSize(width:newHeight,height:newCalHeight))
        calendar.collectionView.frame = CGRect(origin: calendar.collectionView.frame.origin, size: CGSize(width:newHeight,height:newCalHeight))
        calendar.reloadData()
    }
    
    // 祝日判定
    func judgeHoliday(_ date : Date) -> Bool {
        let tmpCalendar = Calendar(identifier: .gregorian)
        
        let year = tmpCalendar.component(.year, from: date)
        let month = tmpCalendar.component(.month, from: date)
        let day = tmpCalendar.component(.day, from: date)
        
        let holiday = CalculateCalendarLogic()
        
        return holiday.judgeJapaneseHoliday(year: year, month: month, day:day)
    }
    
    // 曜日判定（日曜日：１〜土曜日：７）
    func getWeekIdx(_ date:Date) -> Int{
        let tmpCalendar = Calendar(identifier: .gregorian)
        return tmpCalendar.component(.weekday, from: date)
    }
    
    // 土日の色を変える
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor?{
        
        // 画面上に保持している全スケジュールから表示しようとしているスケジュールがあるか調べる
        let dayYYYYMMdd = DateUtils.stringYYYYMMddFromDate(date)
        if let mdl = schedules.filter({scheMdl -> Bool in
            return scheMdl.id_yyyymmdd == dayYYYYMMdd
            
        }).first {
            // 見つかれば色を返す
            if mdl.kind != nil {
                return UIColor.white
            }
        }
        
        
        if self.judgeHoliday(date){
            return UIColor.red
        }
        
        let weekday = self.getWeekIdx(date)
        if weekday == 1 {
            return UIColor.red
        }
        else if weekday == 7 {
            return UIColor.blue
        }
        
        return nil
    }
}
