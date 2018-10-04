//
//  DateUtils.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/09/20.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import UIKit

class DateUtils {
    class func dateFromString(_ string: String, format: String) -> Date {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.date(from: string)! as Date
    }
    
    class func stringFromDate(_ date: Date, format: String) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    class func dateFromString(_ string: String) -> Date {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = Constant.baseDateFormat
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.date(from: string)! as Date
    }
    
    class func stringFromDate(_ date: Date) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = Constant.baseDateFormat
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    class func stringYYYYMMddFromDate(_ date: Date) -> String {
        return stringFromDate(date, format: Constant.dateFormatYYYYMMdd)
    }
    
    class func stringMMddFromDate(_ date:Date) -> String {
        return stringFromDate(date, format: "MM/dd")
    }
}


