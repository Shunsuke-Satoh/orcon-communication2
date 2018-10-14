//
//  DateUtils.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/20.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class DateUtils {
    static func dateFromString(_ string: String, format: String) -> Date {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.date(from: string)! as Date
    }
    
    static func stringFromDate(_ date: Date, format: String) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    static func dateFromString(_ string: String) -> Date {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = Constant.baseDateFormat
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.date(from: string)! as Date
    }
    
    static func stringFromDate(_ date: Date) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = Constant.baseDateFormat
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    static func stringYYYYMMddFromDate(_ date: Date) -> String {
        return stringFromDate(date, format: Constant.dateFormatYYYYMMdd)
    }
    
    static func stringMMddFromDate(_ date:Date) -> String {
        return stringFromDate(date, format: "MM/dd")
    }
    
    // 年の増減
    static func calcDateYear(year:Int,baseDate:String? = nil) -> Date {
        return DateUtils.calcDate(year:year,month:0,day:0,hour:0,minute:0,second:0,baseDate: baseDate)
    }
    
    // 月の増減
    static func calcDateMonth(month:Int,baseDate:String? = nil) -> Date {
        return DateUtils.calcDate(year:0,month:month,day:0,hour:0,minute:0,second:0,baseDate: baseDate)
    }
    
    // 日の増減
    static func calcDateDay(day:Int,baseDate:String? = nil) -> Date {
        return DateUtils.calcDate(year:0,month:0,day:day,hour:0,minute:0,second:0,baseDate: baseDate)
    }
    
    /**
     日付の計算
     
     - parameter year: 年の増減値。マイナス指定可能
     - parameter month: 月の増減値。マイナス指定可能
     - parameter day: 日の増減値。マイナス指定可能
     - parameter hour: 時の増減値。マイナス指定可能
     - parameter minute: 分の増減値。マイナス指定可能
     - parameter second: 秒の増減値。マイナス指定可能
     - parameter baseDate: 基準日（オプション）。指定した場合はこの日付を基準にする
     
     - returns: 計算結果の日付
     */
    
    static private func calcDate(year:Int ,month:Int ,day:Int ,hour:Int ,minute:Int ,second:Int ,baseDate:String? = nil) -> Date {
        
        let formatter = DateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "ja_JP") as Locale
        formatter.dateFormat = Constant.baseDateFormat
        
        var components = DateComponents()
        
        components.setValue(year,for: Calendar.Component.year)
        components.setValue(month,for: Calendar.Component.month)
        components.setValue(day,for: Calendar.Component.day)
        components.setValue(hour,for: Calendar.Component.hour)
        components.setValue(minute,for: Calendar.Component.minute)
        components.setValue(second,for: Calendar.Component.second)
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        let base:Date?
        
        if let _ = baseDate {
            if let _ = formatter.date(from: baseDate!) {
                base = formatter.date(from: baseDate!)!
            } else {
                print("baseDateの日付変換に失敗したので本日を使用します")
                base = Date()
            }
        } else {
            base = Date()
        }
        
        return calendar.date(byAdding: components, to: base!)!
    }

    // fromが未来ならマイナス
    static func differenceInDay(fromDate:Date, toDate: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let lhs = cal.dateComponents([.year, .month, .day], from: fromDate)
        let rhs = cal.dateComponents([.year, .month, .day], from: toDate)
        let components = cal.dateComponents([.day], from: lhs, to: rhs)
        return components.day!
    }
}


