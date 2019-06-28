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
        public let product: SKProduct?

        public func title() -> String {
            let language = Locale.current.languageCode ?? "en"
            return category.title(languageCode: language) ?? category.info.productIdentifier
        }

        public func localizedPrice() -> String? {
            return product?.localizedPrice
        }

    }

    public func map(categories: [AerialAPI.Category]) -> [CategoryProduct] {
        let products = AerialAppStoreIAP.shared.products
        var categoryProducts: [CategoryProduct] = []
        for category in categories {
            let product = products.first(where: { $0.productIdentifier == category.info.productIdentifier })
            categoryProducts.append(CategoryProduct(category: category, product: product))
        }
        return categoryProducts
    }

}
