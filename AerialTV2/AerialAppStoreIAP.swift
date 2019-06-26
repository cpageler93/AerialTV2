//
//  AerialAppStoreIAP.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 25.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation
import SwiftyStoreKit


public class AerialAppStoreIAP {

    public static let shared = AerialAppStoreIAP()

    private init() { }

    public func initialize() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break
                }
            }
        }
    }

    public func update(productIdentifiers: [String]) {
        SwiftyStoreKit.retrieveProductsInfo(Set(productIdentifiers)) { result in

        }
    }

}
