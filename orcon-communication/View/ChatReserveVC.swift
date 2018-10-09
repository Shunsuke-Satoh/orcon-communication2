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
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var img1: EnhancedCircleImageView!
    @IBOutlet weak var img2: EnhancedCircleImageView!
    @IBOutlet weak var img3: EnhancedCircleImageView!
    @IBOutlet weak var img4: EnhancedCircleImageView!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var lbl3: UILabel!
    @IBOutlet weak var lbl4: UILabel!
    
    var imgs: [EnhancedCircleImageView] = []
    var lbls: [UILabel] = []
    
    var schedules: [ScheduledDateModel] = []
    var kinds:[CalKindModel] = []
    var selectedDates:[Date] = []
    var selectedAm:[Bool] = []
    var selectedPm:[Bool] = []
    var doctorId: String!
    var formatter: DateFormatter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        let realmDM = RealmManager.getInstance()

        if CommonUtils.isUserTypeUser() {
            doctorId = realmDM.getRequestByCustomerId(customerId: UserDefaultManager().getOwnUserId())!.doctorId
        } else {
            doctorId = UserDefaultManager().getOwnUserId()
        }
        
        schedules = realmDM.getSchedulesByDoctorId(doctorId: doctorId)
        kinds = realmDM.getKindsByDoctorId(doctorId: doctorId)
        
        lbls.append(lbl1)
        lbls.append(lbl2)
        lbls.append(lbl3)
        lbls.append(lbl4)
        
        imgs.append(img1)
        imgs.append(img2)
        imgs.append(img3)
        imgs.append(img4)
        
        // 初期化
        for (indx,lbl) in lbls.enumerated() {
            lbl.text = "\n\n\n"
            imgs[indx].isHidden = true
        }
        
        // ４個以上は取らない
        while kinds.count > 4 {
            _ = kinds.popLast()
        }
        
        for (indx,kind) in kinds.enumerated() {
            lbls[indx].text = kind.getAllTitle()
            imgs[indx].backgroundColor = CommonUtils.uiColor(kind)
            imgs[indx].isHidden = false
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
        
        for (indx,_) in selectedDates.enumerated() {
            var text = "第" + (indx + 1).description + "希望" + ":"
            text += DateUtils.stringMMddFromDate(selectedDates[indx]) + "（" + formatter.weekdaySymbols[getWeekIdx(selectedDates[indx]) - 1].prefix(1) + "） "
            
            if selectedAm[indx] && selectedPm[indx]{
                text += "終日"
            } else if selectedAm[indx] {
                text += "午前中"
            } else if selectedPm[indx] {
                text += "午後"
            }
            
            message += text + "\n"
        }
        
        let navi = self.navigationController!
        let pre = navi.viewControllers.count - 2
        let vc = navi.viewControllers[pre] as! ChatViewController
        // メッセージ欄に追加
        vc.messageInputBar.inputTextView.text += message
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
    // MARK: - Navigation

}

extension ChatReserveVC:UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedDates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatReserveCell") as! ChatReserveCell
        
        cell.date = selectedDates[indexPath.row]
        cell.indexPath = indexPath
        cell.delegate = self
        cell.title.text = "第" + (indexPath.row + 1).description + "希望"
        cell.subTitle.text = DateUtils.stringMMddFromDate(cell.date) + "（" + formatter.weekdaySymbols[getWeekIdx(cell.date) - 1].prefix(1) + "）"
        cell.amBtn.isSelected = selectedAm[indexPath.row]
        cell.pmBtn.isSelected = selectedPm[indexPath.row]
        cell.setColors()
        
        return cell
    }
    
    
}

// AM,PM,削除ボタン
extension ChatReserveVC:ChatReserveCellDelegate {
    func minus(_ indexPath: IndexPath) {
        selectedDates.remove(at: indexPath.row)
        selectedAm.remove(at: indexPath.row)
        selectedPm.remove(at: indexPath.row)
        table.reloadData()
    }
    
    func tapAM(_ isSelected: Bool, _ indexPath: IndexPath) {
        selectedAm[indexPath.row] = isSelected
    }
    
    func tapPM(_ isSelected: Bool, _ indexPath: IndexPath) {
        selectedPm[indexPath.row] = isSelected
    }
}

extension ChatReserveVC:FSCalendarDelegate ,FSCalendarDataSource,FSCalendarDelegateAppearance {
    
    // カレンダーがタップされた時の処理
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        // 画面上に保持している全スケジュールからタップしようとしているスケジュールがあるか調べる
        let dayYYYYMMdd = DateUtils.stringYYYYMMddFromDate(date)
        if let mdl = schedules.filter({scheMdl -> Bool in
            return scheMdl.id_yyyymmdd == dayYYYYMMdd
            
        }).first {
            // 見つかれば何もしない
            if mdl.kind != nil {
                if mdl.kind!.allCloseFlg {
                    return
                }
            }
        }
        
        // 候補日に追加する
        selectedDates.append(date)
        selectedAm.append(true)
        selectedPm.append(true)
        table.reloadData()
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
