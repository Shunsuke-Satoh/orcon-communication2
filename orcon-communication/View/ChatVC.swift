//
//  ChatViewController.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/18.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit
import MessageKit
import SCLAlertView

class ChatViewController: MessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    @IBOutlet weak var naviBar: UINavigationBar!
    
    let OWN_CHAT_COLOR = UIColor.white
    let OTHER_CHAT_COLOR = UIColor.black
    let userDM = UserDefaultManager()
    let imgM = FBStorageManager()
    let fbRDBM = FBRealTimeDataBaseManager.getInstance()
    
    var roomId: String?
    var messageList: [MockMessage] = []
    let realmManager = RealmManager.getInstance()
    var chatRoomModel: ChatRoomModel?
    var messageModelList: [MessageModel] = []
    var otherUserModel: UserModel?
    
    var myInputBar: MessageInputBar!
    var reserveMessage: String? // いきなり予約画面から来た時用,普通はnil
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    let picker: UIImagePickerController! = UIImagePickerController()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        messagesCollectionView.backgroundView = UIImageView(image: UIImage(named: "background_img_chat"))
        
        ChatDataManager.getInstance().delegate = self
        FBUserManager.getInstance().delegateImg = self
        FBUserManager.getInstance().delegate = self
        
        // roomIdから Realm、UserDefaultから相手のアイコン、ユーザID、名前を格納
        chatRoomModel = realmManager.getChatRoomModelByRoomId(roomId: roomId!)
        otherUserModel = chatRoomModel?.otherUser
        messageModelList = realmManager.getMessagesByRoomId(roomId: roomId!)
        
        // roomIdから Realm、UserDefaultからメッセージを取得してmessageListに格納
        slack()
        
        // 下までスクロール
        self.setMessages{
            DispatchQueue.main.async() {
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom()
                
                // 他者の未読の数を数えてバッジを更新
                CommonUtils.setBadge()
                
                if self.otherUserModel != nil {
                    if CommonUtils.isUserTypeDoctor() {
                        self.navigationItem.title = self.otherUserModel!.name + " とのトーク"
                    }
                    else if CommonUtils.isUserTypeUser() {
                        self.navigationItem.title = self.otherUserModel!.clinicName + " とのトーク"
                    }
                }
                
                if self.reserveMessage != nil {
                    self.myInputBar.inputTextView.text = self.reserveMessage
                }
            }
        }
        
        
       
        messagesCollectionView.messagesDataSource = self as MessagesDataSource
        messagesCollectionView.messagesLayoutDelegate = self as MessagesLayoutDelegate
        messagesCollectionView.messagesDisplayDelegate = self as MessagesDisplayDelegate
        messagesCollectionView.messageCellDelegate = self as MessageCellDelegate
        
        // メッセージ送信ボタン
        messageInputBar.delegate = self as MessageInputBarDelegate
        
        // メッセージ入力時に一番下までスクロール
        scrollsToBottomOnKeybordBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
    }
    
    func setMessages(callback:@escaping ()->Void) -> Void{
        for msgModel in messageModelList {
            createMessage(msgModel:msgModel)
        }
        callback()
    }
    
    func createMessage(msgModel: MessageModel) -> Void {
        var textColor = OWN_CHAT_COLOR
        var sender = currentSender()
        if msgModel.senderId != userDM.getOwnUserId() {
            textColor = OTHER_CHAT_COLOR
            sender = otherSender()
        }
        
        if msgModel.messageType == Constant.msgTypeText {
            let attributedText = NSAttributedString(string:msgModel.contents, attributes: [.font:UIFont.systemFont(ofSize: 15), .foregroundColor: textColor])
            let ret = MockMessage(attributedText: attributedText, sender: sender, messageId: msgModel.messageId, date: msgModel.entryDate, isRead:msgModel.read)
            messageList.append(ret)
        } else if msgModel.messageType == Constant.msgTypeImage {
            // 画像ロード
            var image = userDM.getImageForMessage(messageId: msgModel.messageId)
            if image == nil {
                image = UIImage()
            }
            
            let imageMessage = MockMessage(image: image!, sender: sender, messageId: msgModel.messageId, date: msgModel.entryDate, isRead:msgModel.read)
            messageList.append(imageMessage)
        }
        
        // 既読更新
        if !msgModel.read && msgModel.senderId != userDM.getOwnUserId() {
            ChatDataManager.getInstance().updateRead(roomId: roomId!, messageModel: msgModel)
            realmManager.updateMessageRead(msg:msgModel)
        }
        
    }
    
    func createMessage(text: String) -> MockMessage {
        let attributedText = NSAttributedString(string:text, attributes: [.font:UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.black])
        return MockMessage(attributedText: attributedText, sender: otherSender(), messageId: roomId! + "_" + UUID().uuidString, date: Date(), isRead:false)
    }
    
    // MARK: - Keyboard Style
    
    func slack() {
//        defaultStyle()
        let newMessageInputBar = MessageInputBar()
        newMessageInputBar.sendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        
        newMessageInputBar.delegate = self
        messageInputBar = newMessageInputBar
        
        messageInputBar.backgroundView.backgroundColor = .white
        messageInputBar.isTranslucent = false
        messageInputBar.inputTextView.backgroundColor = .white
        messageInputBar.inputTextView.layer.borderWidth = 1
        messageInputBar.inputTextView.layer.borderColor = UIColor.lightGray.cgColor
        messageInputBar.inputTextView.layer.cornerRadius = 20
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 0)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 13, bottom: 8, right: 5)
        messageInputBar.inputTextView.placeholderTextColor = UIColor.lightGray
        messageInputBar.inputTextView.placeholder = "メッセージを入力する"
        messageInputBar.inputTextView.textColor = UIColor.lightGray
        messageInputBar.inputTextView.delegate = self
        
        myInputBar = messageInputBar
        
        let items = [
            makeButton(named: "icon_library"),
            makeButton2(named: "icon_calendar")
        ]
        items.forEach { $0.tintColor = .lightGray }
        
        let sendBtn = [messageInputBar.sendButton
            .configure {
                $0.setTitle(" > ", for: .normal)
                $0.layer.cornerRadius = 20
                $0.layer.borderWidth = 1.5
                $0.layer.borderColor = $0.titleColor(for: .disabled)?.cgColor
                $0.setTitleColor(.white, for: .normal)
                $0.setTitleColor(.white, for: .highlighted)
                $0.setSize(CGSize(width: 40, height: 40), animated: true)
            }.onDisabled {
                $0.layer.borderColor = $0.titleColor(for: .disabled)?.cgColor
                $0.backgroundColor = .white
            }.onEnabled {
                $0.backgroundColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
                $0.layer.borderColor = UIColor.clear.cgColor
            }.onSelected {
                // We use a transform becuase changing the size would cause the other views to relayout
                $0.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }.onDeselected {
                $0.transform = CGAffineTransform.identity
            }]
        
        // Finally set the items
        messageInputBar.setLeftStackViewWidthConstant(to: 90, animated: true)
        messageInputBar.setStackViewItems(items, forStack: .left, animated: true)
        messageInputBar.leftStackView.alignment = .center
        
        messageInputBar.setRightStackViewWidthConstant(to: 42, animated: true)
        messageInputBar.setStackViewItems(sendBtn, forStack: .right, animated: true)
        messageInputBar.rightStackView.alignment = .center
        
    }
    
    // MARK: - Helpers
    
    func makeButton(named: String) -> InputBarButtonItem {
        return InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                $0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 30, height: 30), animated: true)
            }.onSelected {
                $0.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
            }.onDeselected {
                $0.tintColor = UIColor.lightGray
            }.onTouchUpInside { _ in
                // PhotoLibraryから選択
                self.picker.sourceType = UIImagePickerController.SourceType.photoLibrary
                
                self.picker.delegate = self
                
                self.picker.navigationBar.barTintColor = UIColor.lightGray
                self.picker.navigationBar.tintColor = UIColor.black
                
                self.present(self.picker, animated: true, completion: nil)
        }
    }
    
    func makeButton2(named: String) -> InputBarButtonItem {
        return InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                $0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 30, height: 30), animated: true)
            }.onSelected {
                $0.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
            }.onDeselected {
                $0.tintColor = UIColor.lightGray
            }.onTouchUpInside { _ in
                // push
                self.performSegue(withIdentifier: "toChatReserveSegue", sender: nil)
        }
    }
    
    // 画像が選択された時の動作
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage{
            let imgMsg = MockMessage(image: image, sender: currentSender(), messageId: roomId! + "_" + UUID().uuidString, date: Date(), isRead:false)
            
            saveMessage(mockMsg: imgMsg, msgType: Constant.msgTypeImage, callback: {(isSuccess) in
                if isSuccess {
                    self.messageList.append(imgMsg)
                    self.messagesCollectionView.insertSections([self.messageList.count - 1])
                    self.messagesCollectionView.scrollToBottom()
                }
            })
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
    }

    
    
    // メッセージのセーブ
    ///
    /// - Parameters:
    ///   - mockMsg: メッセージ
    ///   - msgType: メッセージタイプ
    func saveMessage(mockMsg:MockMessage, msgType:String, callback:@escaping (Bool)->Void){
        let realmManager = RealmManager.getInstance()
        let userDM = UserDefaultManager()

        // Realmに保存
        let messageModel = realmManager.insertMessage(chatRoomModel: chatRoomModel!, mockMsg: mockMsg, msgType:msgType)
        
        // 画像だったらUserDefaults,FireStorageに保存
        if msgType == Constant.msgTypeImage {
            // UserDefaultsに保存
            userDM.saveImageForMessage(messageId: messageModel.messageId, uiImage: mockMsg.innerImage)
            // FireStorageに保存
            imgM.upLoadImageForMessage(roomId: roomId!, message: messageModel, uiImage: mockMsg.innerImage, completion:  {(isSuccess)-> Void in
                
                if isSuccess {
                    // FireBaseに保存
                    ChatDataManager.getInstance().uploadMessage(roomId: self.roomId!, messageModel: messageModel)
                    
                    let topicName = CommonUtils.getChatTopicName(roomId: self.roomId!)
                    CommonUtils.postDataMessage(topicName: topicName, title: self.currentSender().displayName + " からのメッセージ", body: "画像のメッセージ", callback: {_ in})
                    callback(true)
                } else {
                    realmManager.deleteMessage(msgId: messageModel.messageId)
                    callback(false)
                    let alert = SCLAlertView()
                    alert.showError("エラー", subTitle: "画像のアップロードに失敗しました")
                }
            })
        } else {
            // FireBaseに保存
            ChatDataManager.getInstance().uploadMessage(roomId: self.roomId!, messageModel: messageModel)
            callback(true)
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// --------------------------------
// extensions
// --------------------------------
extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        var name = ""
        if let temp = realmManager.getUserModelByUserId(userId: userDM.getOwnUserId())?.name{
            name = temp
        }
        return Sender(id: userDM.getOwnUserId(), displayName: name)
    }
    
    func otherSender() -> Sender {
        return Sender(id: (otherUserModel?.userId)!, displayName: (otherUserModel?.name)!)
    }
    
    func numberOfSections(in messageCollectionView: MessagesCollectionView) -> Int{
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType{
        return messageList[indexPath.section]
    }
    
    // メッセージの上に文字を表示 メッセージ全体の日付
    func cellTopLabelAttributedText(for message: MessageType, at indexPath:IndexPath) -> NSAttributedString? {
        // MARK: - 日付けを出す頻度
        if indexPath.section % 3 == 0 {
            
            let dateString = formatter.string(from: message.sentDate)
            return NSAttributedString(
                string: dateString,
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                             NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            )
        }
        return nil
    }
    
    // メッセージの上に文字を表示（名前）
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    // メッセージの下に文字を表示（日付）
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let dateString = formatter.string(from: message.sentDate)
        var readString = "未読   "
        let msgMdl = realmManager.getMessage(msgId: message.messageId)!
        if msgMdl.read {
            readString = "既読   "
        }
        
        return NSAttributedString(string: readString + dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
}

extension ChatViewController: MessageDelegate{
    
    // 相手メッセージの一件追加
    func messageUpdated(msgModel:MessageModel) {
        
//        if let topViewController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController{
//
//            if (topViewController.topViewController as? ChatViewController?) != nil {
            // 既読更新
            realmManager.updateMessageRead(msg: msgModel)
    
    
            var mockMsg:MockMessage?
            if msgModel.messageType == Constant.msgTypeText {
                let attributedText = NSAttributedString(string: msgModel.contents, attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.white])
                mockMsg = MockMessage(attributedText: attributedText, sender: otherSender(),messageId: msgModel.messageId, date: msgModel.entryDate, isRead: msgModel.read)
            } else {
                var image = userDM.getImageForMessage(messageId: msgModel.messageId)
                
                if image == nil {
                    image = UIImage()
                }
                
                mockMsg = MockMessage(image: image!, sender: otherSender(), messageId: msgModel.messageId, date: msgModel.entryDate, isRead:msgModel.read)
            }
        
            messageList.append(mockMsg!)
            messagesCollectionView.insertSections([messageList.count - 1])
            messagesCollectionView.scrollToBottom()
        // 既読更新　少し遅らせることで相手に反映させる
        ChatDataManager.getInstance().updateRead(roomId: roomId!, messageModel: msgModel)
                
//            }
//        }
    }
    
    // 自分のメッセージが既読になる
    func messageReaded(msgModel: MessageModel) {
        
        messageModelList = RealmManager.getInstance().getMessagesByRoomId(roomId:roomId!)
        if msgModel.senderId == userDM.getOwnUserId() {
            for (i,mockMsg) in messageList.enumerated() {
                if mockMsg.messageId == msgModel.messageId {
                    var newMockMsg:MockMessage?
                    if msgModel.messageType == Constant.msgTypeText {
                        let attributedText = NSAttributedString(string: msgModel.contents, attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.white])
                        newMockMsg = MockMessage(attributedText: attributedText, sender: currentSender(),messageId: msgModel.messageId, date: msgModel.entryDate, isRead: msgModel.read)
                    } else {
                        var image = userDM.getImageForMessage(messageId: msgModel.messageId)
                        
                        if image == nil {
                            image = UIImage()
                        }
                        
                        newMockMsg = MockMessage(image: image!, sender: currentSender(), messageId: msgModel.messageId, date: msgModel.entryDate, isRead:msgModel.read)
                    }
                    
                    messageList[i] = newMockMsg!
                    self.messagesCollectionView.reloadData()

                }
            }
        }
    }
}

// Messageのdelegate
extension ChatViewController: MessagesDisplayDelegate {
    // メッセージの色を変更（デフォルトは自分：白、相手：黒）
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if message.sender.id == userDM.getOwnUserId() {
            return .white
        }
        return .darkText
//        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    // メッセージの背景色を変更している（デフォルトは自分：みどり、相手：グレー）
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    // メッセージを吹き出しにする
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    // アイコン
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView){
        let sender = message.sender
        var avatar = Avatar(image: userDM.loadImageForOwnIcon(), initials: String(sender.displayName.prefix(0)))
        if sender.id != userDM.getOwnUserId() {
            avatar = Avatar(image: userDM.loadImageIcon(userId: sender.id), initials: String(sender.displayName.prefix(0)))
        }
        avatarView.set(avatar: avatar)
    }
}

// 各ラベルの高さを設定（デフォルト0なので必須）
extension ChatViewController: MessagesLayoutDelegate {
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return (self.navigationController?.navigationBar.frame.size)!
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section % 3 == 0 { return 10 }
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}

extension ChatViewController: MessageCellDelegate {
    // メッセージなどををタップした時の挙動
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("Top message label tapped")
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
        messageInputBar.inputTextView.resignFirstResponder()
    }
}


// MARK: - MessageLabelDelegate

extension ChatViewController: MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }
}

extension ChatViewController: MessageInputBarDelegate {
    // メッセージ送信ボタンをタップした時の挙動
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        for component in inputBar.inputTextView.components {
            if let text = component as? String {
                let attributedText = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 15),
                                                                                   .foregroundColor: UIColor.white])
                let message = MockMessage(attributedText: attributedText, sender: currentSender(),messageId: roomId! + "_" + UUID().uuidString, date: Date(), isRead:false)
                saveMessage(mockMsg: message, msgType: Constant.msgTypeText, callback:{_ in})
                
                messageList.append(message)
                messagesCollectionView.insertSections([messageList.count - 1])
                
                let topicName = CommonUtils.getChatTopicName(roomId: roomId!)
                CommonUtils.postDataMessage(topicName: topicName, title: currentSender().displayName + " からのメッセージ", body: text, callback: {_ in})
            }
        }
        messagesCollectionView.scrollToBottom()
        inputBar.inputTextView.text = String()
    }
}

// メッセージのインプットが始まったらアイコン群を隠す。終わったら戻す
extension ChatViewController:UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        myInputBar.setLeftStackViewWidthConstant(to: 0, animated: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        myInputBar.setLeftStackViewWidthConstant(to: 90, animated: true)
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

extension ChatViewController: FBUserManagerImageDelegate, FBUserManagerDelegate {
    func compTopImg(userId: String) {
        self.messagesCollectionView.reloadData()
    }
    
    func compIconImg(userId: String) {
        self.messagesCollectionView.reloadData()
    }
    
    func userUpdated(userModel: UserModel) {
        self.messagesCollectionView.reloadData()    }
    
}
