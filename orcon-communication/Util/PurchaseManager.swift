//
//  PurchaseManager.swift
//  orcon-communication
//
//  Created by ONE NATION on 2018/10/06.
//  Copyright © 2018年 ONE NATION. All rights reserved.
//

import SwiftyStoreKit

class PurchaseManager {

    static func purchaseGetInfo() {
        
        SwiftyStoreKit.retrieveProductsInfo(["orcon_doctor_1"]) { result in
            if let product = result.retrievedProducts.first {
                print("valid" + product.localizedDescription)
                
            } else {
                print(result.invalidProductIDs)
            }
        }
    }
}
