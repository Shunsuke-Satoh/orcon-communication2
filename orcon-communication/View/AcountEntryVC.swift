//
//  AcountEntryViewController.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/12.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import SwiftCop
import RSKImageCropper
import SCLAlertView

class AcountEntryViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var nameTxtF: UITextField!
    @IBOutlet weak var telTxtF: UITextField!
    @IBOutlet weak var emailTxtF: UITextField!
    @IBOutlet weak var passwordTxtF: UITextField!
    @IBOutlet weak var clinicNameTxtF: UITextField!
    @IBOutlet weak var clinicAddressTxtF: UITextField!
    @IBOutlet weak var termConfirmChkB: UISwitch!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var telLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var passwordLbl: UILabel!
    @IBOutlet weak var clinicNameLbl: UILabel!
    @IBOutlet weak var confirmLbl: UILabel!
    
    @IBOutlet weak var confirm: UIButton!
    @IBOutlet weak var topImgsTitleLbl: UILabel!
    
    @IBOutlet weak var topImgView: UIImageView!
    @IBOutlet weak var iconImgView: UIImageView!
    @IBOutlet weak var clinicNameSVConst: NSLayoutConstraint!
    @IBOutlet weak var clinicAddressSVConst: NSLayoutConstraint!
    @IBOutlet weak var topImgTitleLblConst: NSLayoutConstraint!
    @IBOutlet weak var topImgConst: NSLayoutConstraint!
    
    @IBOutlet weak var scrollContentView: NSLayoutConstraint!
    
    @IBOutlet weak var termStack: UIStackView!
    
    var userType = ""
    var swiftCop :SwiftCop?
    
    var topOrIcon = "top"
    
    var picker: UIImagePickerController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        swiftCop = SwiftCop()
        picker  = UIImagePickerController()
        picker?.delegate = self
        nameTxtF.delegate = self
        telTxtF.delegate = self
        emailTxtF.delegate = self
        passwordTxtF.delegate = self
        clinicNameTxtF.delegate = self
        clinicAddressTxtF.delegate = self
        // 入力フォームのアラート初期化
        nameLbl.text = ""
        telLbl.text = ""
        emailLbl.text = ""
        passwordLbl.text = ""
        clinicNameLbl.text = ""
        confirmLbl.text = ""
        
        // ボタンの見た目
        confirm.setTitleColor(UIColor.black, for: .normal)
        confirm.backgroundColor = UIColor.white
        confirm.layer.cornerRadius = 20
        confirm.layer.borderWidth = 1
        confirm.layer.shadowOpacity = 0.5
        confirm.layer.shadowOffset = CGSize(width:2,height:2)
        
        // 入力フォームのバリデーション
        swiftCop?.addSuspect(Suspect(view: nameTxtF, sentence: "入力必須です。", trial: Trial.length(.minimum, 1)))
        swiftCop?.addSuspect(Suspect(view: telTxtF, sentence: "入力必須です。", trial: Trial.length(.minimum, 1)))
        swiftCop?.addSuspect(Suspect(view: emailTxtF, sentence: "入力必須です。", trial: Trial.length(.minimum, 1)))
        swiftCop?.addSuspect(Suspect(view: emailTxtF, sentence: "形式が不正です。", trial: Trial.email))
        swiftCop?.addSuspect(Suspect(view: passwordTxtF, sentence: "8文字以上の入力が必須です。", trial: Trial.length(.minimum, 8)))
        
        if userType == Constant.userTypeDoctor {
            swiftCop?.addSuspect(Suspect(view: clinicNameTxtF, sentence: "入力必須です。", trial: Trial.length(.minimum, 1)))
        }else {
            clinicNameSVConst.constant = 0
            clinicAddressSVConst.constant = 0
            topImgTitleLblConst.constant = 0
            topImgConst.constant = 0
//            scrollContentView.constant = view.frame.height
//            scrollContentView.constant = confirm.bounds.maxY + 40
        }
//        let imageCropVC = RSKImageCropViewController(image:topImgView.image!, cropMode: .circle)
//        imageCropVC.moveAndScaleLabel.text = "切り取り範囲を選択してください"
//        imageCropVC.cancelButton.setTitle("キャンセル", for: .normal)
//        imageCropVC.chooseButton.setTitle("完了", for: .normal)
//        imageCropVC.delegate = self
//        imageCropVC.dataSource = self
//        present(imageCropVC, animated:true)
        
//        let twk = PhotoTweaksViewController(image: topImgView.image!)
//        twk?.delegate = self
//        present(twk!, animated:true)
        
        if UserDefaultManager().getOwnUserId() == "" {
            setUpForEntry()
        } else {
            setUpForChange()
        }
    }
    
    func setUpForEntry() {
    }
    
    func setUpForChange() {
        let userDM = UserDefaultManager()
        let userMdl = RealmManager.getInstance().getUserModelByUserId(userId: userDM.getOwnUserId())
        
        // 初期設定
        nameTxtF.text = userMdl?.name
        telTxtF.text = userMdl?.tel
        emailTxtF.text = userMdl?.email
        emailTxtF.isEnabled = false
        passwordTxtF.text = userDM.getOwnPassword()
        passwordTxtF.isEnabled = false
        clinicNameTxtF.text = userMdl?.clinicName
        clinicAddressTxtF.text = userMdl?.clinicAddress
        iconImgView.image = userDM.loadImageForOwnIcon()
        
        if CommonUtils.isUserTypeUser() {
            
        } else {
            topImgView.image = userDM.loadImageForOwnTop()
        }
        termStack.isHidden = true
        
        //
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // 各フィールドが編集される都度、バリデーション
    @IBAction func validateName(_ sender: UITextField) {
        nameLbl.text = swiftCop?.isGuilty(sender)?.verdict()
    }
    
    @IBAction func validateTel(_ sender: UITextField) {
        telLbl.text = swiftCop?.isGuilty(sender)?.verdict()
    }
    
    @IBAction func validateEmail(_ sender: UITextField) {
        emailLbl.text = swiftCop?.isGuilty(sender)?.verdict()
    }
    @IBAction func validateEmail2(_ sender: UITextField) {
        emailLbl.text = swiftCop?.isGuilty(sender)?.verdict()
    }
    
    @IBAction func validatePassword(_ sender: UITextField) {
        passwordLbl.text = swiftCop?.isGuilty(sender)?.verdict()
    }
    
    @IBAction func validateClinicName(_ sender: UITextField) {
        clinicNameLbl.text = swiftCop?.isGuilty(sender)?.verdict()
    }
    @IBAction func validateTerm(_ sender: UISwitch) {
        validateTermImpl(sender)
    }
    
    func validateTermImpl(_ sender: UISwitch) -> Void{
        confirmLbl.text = termConfirmChkB.isOn ? "" : "利用規約に同意が必要です。"
    }
    
    // 医院トップ画像の選択 TapGestureReco
    @IBAction func selectTopImg(_ sender: UITapGestureRecognizer) {
        topOrIcon = "top"
        // PhotoLibraryから選択
        picker?.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        picker?.navigationBar.barTintColor = UIColor.lightGray
        picker?.navigationBar.tintColor = UIColor.white
        
        present(picker!, animated: true, completion: nil)
    }
    
    // チャットアイコンの選択 TapGestureReco
    @IBAction func selectIconImg(_ sender: UITapGestureRecognizer) {
        topOrIcon = "icon"
        // PhotoLibraryから選択
        picker?.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        picker?.navigationBar.barTintColor = UIColor.lightGray
        picker?.navigationBar.tintColor = UIColor.black
        
        present(picker!, animated: true, completion: nil)
    }
    
    // 画像が選択された時の動作
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage{
            if topOrIcon == "top" {
//                let imageCropVC = RSKImageCropViewController(image:image, cropMode: .square)
//                imageCropVC.moveAndScaleLabel.text = "切り取り範囲を選択してください"
//                imageCropVC.cancelButton.setTitle("キャンセル", for: .normal)
//                imageCropVC.chooseButton.setTitle("完了", for: .normal)
//                imageCropVC.delegate = self
                
                topImgView.image = image
                self.dismiss(animated: false, completion: nil)
//                present(imageCropVC, animated:true)
//                print("present")
            }else{
//                let imageCropVC = RSKImageCropViewController(image:image, cropMode: .circle)
//                imageCropVC.moveAndScaleLabel.text = "切り取り範囲を選択してください"
//                imageCropVC.cancelButton.setTitle("キャンセル", for: .normal)
//                imageCropVC.chooseButton.setTitle("完了", for: .normal)
//                imageCropVC.delegate = self
                
                iconImgView.image = image
                self.dismiss(animated: true, completion: nil)
//                present(imageCropVC, animated:true)
//                print("present")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // キーボード隠す
    @IBAction func tapAny(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    @IBAction func tapBtn(_ sender: UIButton) {
        
        // 入力チェック
        if !validate() {
            let alertV = SCLAlertView()
            alertV.showWarning("エラー", subTitle: "入力に誤りがあります")
            return
        }
        
        if UserDefaultManager().getOwnUserId() == "" {
            // 初回登録時は確認画面へ遷移
            performSegue(withIdentifier: "toConfirmSegue", sender: nil)
        } else {
            // 会員情報変更時はポップアップで確認
            // ポップアップを準備
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton:false
            )
            
            let confV = SCLAlertView(appearance: appearance)
            
            // 確認ボタン
            confV.addButton("はい"){
                let fbRTDM = FBRealTimeDataBaseManager.getInstance()
                let imgM = FBStorageManager()
                let realmDM = RealmManager.getInstance()
                let userDM = UserDefaultManager()
                
                // Realmに保存
                realmDM.updateUser(userId: userDM.getOwnUserId(), name: self.nameTxtF.text!, tel: self.telTxtF.text!, clinicName: self.clinicNameTxtF.text!, clinicAddress: self.clinicAddressTxtF.text!, iconImgUpdate: Date(), topImgUpdate: Date())
                
                // UserDefaultに保存 トップ、アイコン
                userDM.saveImageForOwnIcon(uiImage: self.iconImgView.image!)
                
                if self.userType == Constant.userTypeDoctor {
                    userDM.saveImageForOwnTop(uiImage: self.topImgView.image!)
                }
                
                // ユーザ情報をアップロード
                let userMdl = realmDM.getUserModelByUserId(userId: userDM.getOwnUserId())!
                fbRTDM.updateUserAndDoctor(userMdl: userMdl)
                
                // 画像データをアップロード トップ、アイコン
                if self.userType == Constant.userTypeDoctor {
                    imgM.upLoadImage(img: self.topImgView.image!, uid: userMdl.userId, mode: Constant.storageImgModeTOP, completion:  {(isSuccess)-> Void in
                        // 失敗した時どうする？
                        // ユーザ設定画面から再設定してもらうか
                    })
                }
                
                imgM.upLoadImage(img: self.iconImgView.image!, uid: userMdl.userId, mode: Constant.storageImgModeICON, completion:  {(isSuccess)-> Void in
                    // 失敗した時どうする？
                    // ユーザ設定画面から再設定してもらうか
                })
                
                confV.dismiss(animated: true, completion: {})
                
                
                // 完了ダイアログ
                let completeV = SCLAlertView(appearance: appearance)
                completeV.addButton("閉じる"){
                    // 自分自身も閉じる
                    completeV.dismiss(animated: true, completion: {})
                    self.navigationController?.popViewController(animated: true)
                }
                // 完了ダイアログ表示
                completeV.showSuccess("完了しました", subTitle: "")
            }
            
            // キャンセルボタン
            confV.addButton("いいえ"){
                confV.dismiss(animated: true, completion: {})
            }
            
            // ダイアログ表示
            confV.showNotice("確認", subTitle: "アカウント情報を変更しますか？")
            
        }
    }
    
    func validate() -> Bool{
        self.nameLbl.text = swiftCop?.isGuilty(self.nameTxtF)?.verdict()
        self.telLbl.text = swiftCop?.isGuilty(self.telTxtF)?.verdict()
        self.emailLbl.text = swiftCop?.isGuilty(self.emailTxtF)?.verdict()
        self.passwordLbl.text = swiftCop?.isGuilty(self.passwordTxtF)?.verdict()
        if userType == Constant.userTypeDoctor {
            self.clinicNameLbl.text = swiftCop?.isGuilty(self.clinicNameTxtF)?.verdict()
        }
        
        if UserDefaultManager().getOwnUserId() == ""{
            validateTermImpl(termConfirmChkB)
        }
        
        let name = self.nameLbl.text ?? ""
        let tel = self.telLbl.text ?? ""
        let email = self.emailLbl.text ?? ""
        let clinicName = self.clinicNameLbl.text ?? ""
        let confirmtmp = self.confirmLbl.text ?? ""
        let allWarn = name + tel + email + clinicName + confirmtmp
        
        if allWarn.count > 0{
            return false
        }
        
        return true
    }
    
    // 次画面への情報渡し
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toConfirmSegue" {
            let confirmController:AcountEntryConfirmViewController = segue.destination as! AcountEntryConfirmViewController
            
            confirmController.userType = userType
            confirmController.name = nameTxtF.text!
            confirmController.email = emailTxtF.text!
            confirmController.password = passwordTxtF.text!
            confirmController.clinicName = clinicNameTxtF.text!
            confirmController.tel = telTxtF.text!
            confirmController.clinicAddress = clinicAddressTxtF.text!
            confirmController.topImg = topImgView.image!
            confirmController.iconImg = iconImgView.image!
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AcountEntryViewController: RSKImageCropViewControllerDelegate {
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated:true, completion:nil)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        dismiss(animated: true, completion: nil)
        if controller.cropMode == .square {
            topImgView.image = croppedImage
        } else {
            iconImgView.image = croppedImage
        }
    }
}

extension AcountEntryViewController: RSKImageCropViewControllerDataSource {
    
    func imageCropViewControllerCustomMaskRect(_ controller: RSKImageCropViewController) -> CGRect {
        
        let viewWidth = controller.view.frame.width - 40
        let viewHeight = controller.view.frame.height - 30
        
        let maskWidth = viewWidth
        let maskHeight = maskWidth * 5 / 8
        
        return CGRect(x: (viewWidth - maskWidth + 40) * 0.5 , y: (viewHeight - maskHeight + 30) * 0.5, width: maskWidth, height: maskHeight)
        
    }
    
    func imageCropViewControllerCustomMaskPath(_ controller: RSKImageCropViewController) -> UIBezierPath {
        let rect = controller.maskRect
        
        let square: UIBezierPath = UIBezierPath()
        
        square.move(to:CGPoint(x:rect.minX, y:rect.maxY))
        square.addLine(to: CGPoint(x:rect.maxX, y:rect.maxY))
        square.addLine(to: CGPoint(x:rect.maxX, y:rect.minY))
        square.addLine(to: CGPoint(x:rect.minX, y:rect.minY))
        square.close()
        
        return square
    }
    
    func imageCropViewControllerCustomMovementRect(_ controller: RSKImageCropViewController) -> CGRect {
        return controller.maskRect
    }
    

}

// キーボード隠す
extension AcountEntryViewController:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
