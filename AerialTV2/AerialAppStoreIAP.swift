//
//  AerialAppStoreIAP.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 25.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation
import StoreKit
import SwiftyStoreKit


public class AerialAppStoreIAP {

    public static let shared = AerialAppStoreIAP()

    private init() { }

    public private(set) var products: [SKProduct] = []

    private var purchasedProductIdentifiers: Set<String> = []

    public func initialize() {
        loadPurchasedProductIdentifiers()
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    self.purchasedProductIdentifiers.insert(purchase.productId)
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
            self.savePurchasedProductIdentifiers()
        }
    }

    private func loadPurchasedProductIdentifiers() {
        let defaultsValue = UserDefaults.standard.array(forKey: "purchasedProductIdentifiers") as? [String]
        purchasedProductIdentifiers = Set(defaultsValue ?? [])
    }

    private func savePurchasedProductIdentifiers() {
        UserDefaults.standard.set(Array(purchasedProductIdentifiers), forKey: "purchasedProductIdentifiers")
        UserDefaults.standard.synchronize()
    }

    public func update(productIdentifiers: [String]) {
        SwiftyStoreKit.retrieveProductsInfo(Set(productIdentifiers)) { result in
            self.products = Array(result.retrievedProducts)
        }
    }

    public func restorePurchases(completion: @escaping () -> Void) {
        SwiftyStoreKit.restorePurchases { _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    public func isPurchased(product: SKProduct?) -> Bool {
        // TODO: Implement method
        return false
    }

    public func purchase(product: SKProduct?, completion: @escaping () -> Void) {
        guard let product = product else { return }
        guard !product.productIdentifier.isEmpty else { return }
        SwiftyStoreKit.purchaseProduct(product) { _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

}
