//
//  DoctorCalendarViewController.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/13.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import FSCalendar
import CalculateCalendarLogic
import SCLAlertView

class DoctorCalendarViewController: UIViewController ,FSCalendarDelegate ,FSCalendarDataSource,FSCalendarDelegateAppearance{
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var img1: EnhancedCircleImageView!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var img2: EnhancedCircleImageView!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var img3: EnhancedCircleImageView!
    @IBOutlet weak var lbl3: UILabel!
    @IBOutlet weak var img4: EnhancedCircleImageView!
    @IBOutlet weak var lbl4: UILabel!
    @IBOutlet weak var stack1: UIStackView!
    @IBOutlet weak var stack2: UIStackView!
    @IBOutlet weak var stack3: UIStackView!
    @IBOutlet weak var stack4: UIStackView!
    @IBOutlet weak var leftArrowBtn: UIButton!
    @IBOutlet weak var rightArrowBtn: UIButton!
    
    var stacks: [UIStackView] = []
    var lbls: [UILabel] = []
    var imgs: [EnhancedCircleImageView] = []
    var kinds: [CalKindModel] = []
    var selectIndx = -1
    var schedule: [ScheduledDateModel] = []
    var isEdited = false
    
    var rightBarBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    FBRealTimeDataBaseManager.getInstance().removeScheduleKindDetailObserves()

        // デリゲートの設定
        self.calendar.dataSource = self
        self.calendar.delegate = self
        
        rightBarBtn = UIBarButtonItem(title: "診療日種別の設定 >", style: .plain, target: self, action: #selector(DoctorCalendarViewController.tappedNextBtn))
        navigationItem.title = "診療日の設定"
        navigationItem.rightBarButtonItem = rightBarBtn
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        myInit()
    }

    func myInit() {
        selectIndx = -1
        // とりあえず配列を初期化
        stacks.removeAll()
        stacks.append(stack1)
        stacks.append(stack2)
        stacks.append(stack3)
        stacks.append(stack4)
        
        lbls.removeAll()
        lbls.append(lbl1)
        lbls.append(lbl2)
        lbls.append(lbl3)
        lbls.append(lbl4)
        
        imgs.removeAll()
        imgs.append(img1)
        imgs.append(img2)
        imgs.append(img3)
        imgs.append(img4)
        
        // 種別取得
        kinds = RealmManager.getInstance().getKindsByDoctorId(doctorId: UserDefaultManager().getOwnUserId())
        
        // ４個以上は取らない
        while kinds.count > 4 {
            _ = kinds.popLast()
        }
        
        // いらないものは不可視化
        while kinds.count < stacks.count {
            stacks.last?.isHidden = true
            _ = stacks.popLast()
            _ = lbls.popLast()
            _ = imgs.popLast()
        }
        // いるものは可視化
        for stack in stacks {
            stack.isHidden = false
        }
        
        for (index, kindMdl) in kinds.enumerated() {
            
            lbls[index].text = kindMdl.getAllTitle()
            
            imgs[index].backgroundColor = UIColor(red: kindMdl.color_r, green: kindMdl.color_g, blue: kindMdl.color_b, alpha: 1)
        }
        
        // スケジュール取得
        let yyyymm = DateUtils.stringYYYYMMddFromDate(calendar.currentPage).prefix(4)
        schedule = RealmManager.getInstance().getScheduleModelsOrderByDate(yyyymm: String(yyyymm))
        
        calendar.reloadData()
        self.view.layoutIfNeeded()
    }
    @IBAction func left(_ sender: Any) {
        let date = Calendar.current.date(byAdding: .month, value: -1, to: calendar.currentPage)
        calendar.setCurrentPage(date! , animated: true)
        
    }
    @IBAction func right(_ sender: Any) {
        let date = Calendar.current.date(byAdding: .month, value: +1, to: calendar.currentPage)
        calendar.setCurrentPage(date! , animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // データ更新
    @IBAction func tapSave(_ sender: UIButton) {
        // ポップアップを準備
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton:false
        )
        
        let confV = SCLAlertView(appearance: appearance)
        
        // 登録ボタン
        confV.addButton("はい"){
            // 登録処理へ
            for mdl in self.schedule{
                RealmManager.getInstance().updateInsertScheduleModel(mdl)
            }
            // データ再取得・描画
            self.myInit()
            self.isEdited = false
            
            confV.dismiss(animated: true, completion: {})
        }
        
        // キャンセルボタン
        confV.addButton("いいえ"){
            confV.dismiss(animated: true, completion: {})
        }
        
        // ダイアログ表示
        confV.showNotice("確認", subTitle: "現在の状態で更新します")
    }
    
    // カレンダーがタップされた時の処理
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        // この時点では表示上紐付いているがDB更新はされない
        
        if selectIndx == -1 {
            return
        }
        // キーを探す
        let tapDayYYYYMMdd = DateUtils.stringYYYYMMddFromDate(date)
        
        // キーが見つかれば削除して新規作成、追加する
        for (indx,mdl) in schedule.enumerated() {
            if mdl.id_yyyymmdd == tapDayYYYYMMdd {
                schedule.remove(at: indx)
                break
            }
        }
        // 生成して紐つける
        let scheMdl = ScheduledDateModel()
        scheMdl.doctorId = UserDefaultManager().getOwnUserId()
        scheMdl.date = date
        scheMdl.id_yyyymmdd = tapDayYYYYMMdd
        scheMdl.kind = kinds[selectIndx]
        scheMdl.kindId = kinds[selectIndx].kindId
        
        schedule.append(scheMdl)
        
    }
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        calendar.reloadData()
        return true
    }
    
    // 各日のひも付き種別を見て色を表示する
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        
        // 画面上に保持している全スケジュールから表示しようとしているスケジュールがあるか調べる
        let dayYYYYMMdd = DateUtils.stringYYYYMMddFromDate(date)
        if let mdl = schedule.filter({scheMdl -> Bool in
            return scheMdl.id_yyyymmdd == dayYYYYMMdd
            
        }).first {
            // 見つかれば色を返す
            if mdl.kind != nil {
                return CommonUtils.uiColor(mdl.kind!)
            }
        }
        
        return nil
    }
    
    // セルを選んだ時に着色する色
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {

        if selectIndx != -1 {
            return CommonUtils.uiColor(kinds[selectIndx])
        }
        return UIColor.blue
    }
    
    
    // 月替わり
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        // 表示する月の情報をすでに取得しているか確認する
        let yyyymm = DateUtils.stringYYYYMMddFromDate(calendar.currentPage).prefix(4)
        if schedule.filter({scheMdl -> Bool in
            return scheMdl.id_yyyymmdd.starts(with:yyyymm)
            
        }).first == nil {
            // 取得していない場合、取得する
            let mdls = RealmManager.getInstance().getScheduleModelsOrderByDate(yyyymm: String(yyyymm))
            
            for mdl in mdls {
                schedule.append(mdl)
            }
        }
    }
    
    fileprivate let gregorian: Calendar = Calendar(identifier: .gregorian)
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
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
        if let mdl = schedule.filter({scheMdl -> Bool in
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
    
    // 種別が選ばれた時の処理
    @IBAction func colorTap1(_ sender: UITapGestureRecognizer) {
        selectIndx = 0
        setSelectBorders()
    }
    @IBAction func colorTap2(_ sender: UITapGestureRecognizer) {
        selectIndx = 1
        setSelectBorders()
    }
    @IBAction func colorTap3(_ sender: UITapGestureRecognizer) {
        selectIndx = 2
        setSelectBorders()
    }
    @IBAction func colorTap4(_ sender: UITapGestureRecognizer) {
        selectIndx = 3
        setSelectBorders()
    }
    func setSelectBorders(){
        for (indx, _) in imgs.enumerated() {
            if selectIndx == indx {
                setBorder(index: indx, flag: true)
            } else {
                setBorder(index: indx, flag: false)
            }
        }
    }
    func setBorder(index:Int, flag:Bool){
        if flag {
            imgs[index].layer.borderColor = UIColor.lightGray.cgColor
            imgs[index].layer.borderWidth = 10
        } else {
            imgs[index].layer.borderColor = UIColor.white.cgColor
            imgs[index].layer.borderWidth = 0
        }
    }
    // MARK: - Navigation
    
    @objc func tappedNextBtn() {
        if isEdited {
            // ポップアップを準備
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton:false
            )
            
            let confV = SCLAlertView(appearance: appearance)
            
            // 破棄ボタン
            confV.addButton("はい"){
                confV.dismiss(animated: true, completion: {})
                self.next()
            }
            
            // キャンセルボタン
            confV.addButton("いいえ"){
                confV.dismiss(animated: true, completion: {})
            }
            
            // ダイアログ表示
            confV.showNotice("更新されていない編集があります", subTitle: "現在の編集を破棄して移動しますか？")
        } else{
            next()
        }
    }
    // 次画面への遷移時に編集されてたら破棄確認ダイアログを出す
    @IBAction func nextBtn(_ sender: UIBarButtonItem) {
        if isEdited {
            // ポップアップを準備
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton:false
            )
            
            let confV = SCLAlertView(appearance: appearance)
            
            // 破棄ボタン
            confV.addButton("はい"){
                confV.dismiss(animated: true, completion: {})
                self.next()
            }
            
            // キャンセルボタン
            confV.addButton("いいえ"){
                confV.dismiss(animated: true, completion: {})
            }
            
            // ダイアログ表示
            confV.showNotice("更新されていない編集があります", subTitle: "現在の編集を破棄して移動しますか？")
        } else{
            next()
        }
    }
    
    func next() {
        performSegue(withIdentifier: "toCalendarSet", sender: nil)
    }
}
