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

    private let proProductIdentifier = "de.pageler.christoph.aerialtv2.pro.year"
    public private(set) var proProduct: SKProduct?

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
        var identifiers = Set(productIdentifiers)
        identifiers.insert(proProductIdentifier)
        SwiftyStoreKit.retrieveProductsInfo(identifiers) { result in
            self.products = Array(result.retrievedProducts)
            self.proProduct = result.retrievedProducts.first(where: { $0.productIdentifier == self.proProductIdentifier })
            NotificationCenter.default.post(name: AerialAppStoreIAP.didUpdateProductsNotification, object: nil)
        }
    }

    public func restorePurchases(completion: @escaping () -> Void) {
        SwiftyStoreKit.restorePurchases { result in
            for productID in result.restoredPurchases.compactMap({ $0.productId }) {
                self.purchasedProductIdentifiers.insert(productID)
            }
            self.savePurchasedProductIdentifiers()
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    public func isPurchased(product: SKProduct?) -> Bool {
        guard let product = product else { return false }
        return isPurchased(productIdentifier: product.productIdentifier)
    }

    public func isPurchased(productIdentifier: String) -> Bool {
        #if targetEnvironment(simulator)
        return true
        #endif
        let purchasedProduct = purchasedProductIdentifiers.contains(productIdentifier)
        let purchasedPro = purchasedProductIdentifiers.contains(proProductIdentifier)
        return purchasedProduct || purchasedPro
    }

    public func purchase(product: SKProduct?, completion: @escaping () -> Void) {
        guard let product = product else { return }
        guard !product.productIdentifier.isEmpty else { return }
        SwiftyStoreKit.purchaseProduct(product) { result in
            switch result {
            case .success(let purchase):
                self.purchasedProductIdentifiers.insert(purchase.productId)
                self.savePurchasedProductIdentifiers()
            default:
                break
            }

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    public static var didUpdateProductsNotification = Notification.Name("AerialAppStoreIAP.didUpdateProductsNotification")

}
