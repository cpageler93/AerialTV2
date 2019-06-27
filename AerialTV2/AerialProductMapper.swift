//
//  AerialProductMapper.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 26.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation
import StoreKit


public class AerialProductMapper {

    public struct CategoryProduct {

        public let category: AerialAPI.Category
        public let product: SKProduct

        public func title() -> String {
            if product.productIdentifier.isEmpty {
                return category.info.productIdentifier
            } else {
                return product.localizedTitle
            }
        }

        public func localizedPrice() -> String? {
            if product.productIdentifier.isEmpty {
                return "315€"
            } else {
                return product.localizedPrice
            }
        }

    }

    public func map(categories: [AerialAPI.Category]) -> [CategoryProduct] {
        let products = AerialAppStoreIAP.shared.products
        var categoryProducts: [CategoryProduct] = []
        for category in categories {
            if let product = products.first(where: { $0.productIdentifier == category.info.productIdentifier }) {
                categoryProducts.append(CategoryProduct(category: category, product: product))
            } else {
                // tvOS on Simulator cant fetch SKProducts so we fake them
                #if targetEnvironment(simulator)
                let fakeProduct = SKProduct()
                categoryProducts.append(CategoryProduct(category: category, product: fakeProduct))
                #endif
            }
        }
        return categoryProducts
    }

}
