//
//  PurchaseManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/06.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import SwiftyStoreKit

class PurchaseManager {
    static let id1 = "orcon_doctor_1"
    static let id2 = "orcon_doctor_3"
    static let id3 = "orcon_doctor_6"
    static let productIds :Set<String> = [id1,id2,id3]
    
    static let productIdstr = "productId"
    static let titlestr = "title"
    static let descstr = "desc"
    static let pricestr = "price"
    
    private static var own:PurchaseManager?
    var delegate:PurchaseManagerDelegate?
    
    private init(){
        
    }
    
    static func getInstance() -> PurchaseManager {
        if own == nil {
            own = PurchaseManager.init()
        }
        return own!
    }
    
    func getPath(productId:String ,_ any:String) -> String {
        return "product_" + productId + "_" + any
    }

    // 初回で課金情報は取得する
    func purchaseGetInfo(){
        SwiftyStoreKit.retrieveProductsInfo(PurchaseManager.productIds) { result in
            for product in result.retrievedProducts {
                self.setProduct(product.productIdentifier, titleVal: product.localizedTitle, descVal: product.localizedDescription, priceVal: product.localizedPrice!)
            }
        }
    }
    
    
    func setProduct(_ productIdVal:String, titleVal:String, descVal:String, priceVal:String) {
        UserDefaults.standard.set(titleVal, forKey: getPath(productId:productIdVal, PurchaseManager.titlestr))
        UserDefaults.standard.set(descVal, forKey: getPath(productId:productIdVal, PurchaseManager.descstr))
        UserDefaults.standard.set(priceVal, forKey: getPath(productId:productIdVal, PurchaseManager.pricestr))
    }
    
    func getProducts() -> Dictionary<String,Any> {
        var ret = Dictionary<String,Dictionary<String,String>>()
        for id in PurchaseManager.productIds {
            ret[id] = getProduct(id)
        }
        
        return ret
    }
    
    func getProduct(_ productIdVal:String) -> Dictionary<String,String> {
        var ret = Dictionary<String, String>()
        
        ret[PurchaseManager.titlestr] = UserDefaults.standard.string(forKey: getPath(productId:productIdVal, PurchaseManager.titlestr))
        ret[PurchaseManager.descstr] = UserDefaults.standard.string(forKey: getPath(productId:productIdVal,PurchaseManager.descstr))
        ret[PurchaseManager.pricestr] = UserDefaults.standard.string(forKey: getPath(productId:productIdVal,PurchaseManager.pricestr))
        ret[PurchaseManager.productIdstr] = productIdVal
        
        return ret
    }
    
    func buy(_ id : String) {
        SwiftyStoreKit.purchaseProduct(id, quantity: 1, atomically: true) {result in
            switch result {
            case.success(_):
                self.delegate?.success(id: id)

            case.error(_):
                self.delegate?.fail(id: id)
            }
        }
    }
}

protocol PurchaseManagerDelegate {
    func success(id:String)
    func fail(id:String)
}

