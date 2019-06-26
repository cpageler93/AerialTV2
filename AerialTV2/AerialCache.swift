//
//  AerialCache.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 25.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation


public class AerialCache {

    public static var categories: [AerialAPI.Category]?

    private static var cacheURL: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory().appending("categories.cache"))
    }

    public static func update() {
        // load cache from file
        if let data = try? Data(contentsOf: cacheURL) {
            if let categories = try? JSONDecoder().decode([AerialAPI.Category].self, from: data) {
                self.categories = categories
            }
        }

        // refresh cache
        let api = AerialAPI()
        api.getCategoriesFromContent { categories in
            guard let categories = categories else { return }
            AerialCache.categories = categories
            NotificationCenter.default.post(name: AerialCache.didUpdateCategoriesNotification, object: nil)

            // write cache
            guard let data = try? JSONEncoder().encode(categories) else { return }
            try? data.write(to: cacheURL)
        }
    }

    public static var didUpdateCategoriesNotification = Notification.Name("AerialCache.didUpdateCategoriesNotification")

}
