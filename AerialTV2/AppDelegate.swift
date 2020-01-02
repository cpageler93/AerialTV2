//
//  AppDelegate.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 24.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initializeNotifications()

        AerialCache.update()
        AerialAppStoreIAP.shared.initialize()

        return true
    }

    private func initializeNotifications() {
        NotificationCenter.default.addObserver(forName: AerialCache.didUpdateCategoriesNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            guard let categories = AerialCache.categories else { return }
            let allVideos = categories.compactMap({ $0.videos }).reduce([], +)

            AerialAppStoreIAP.shared.update(productIdentifiers: categories.compactMap({ $0.info.productIdentifier }))
            AerialImageProvider.shared.preloadImages(for: allVideos)
        }

        NotificationCenter.default.addObserver(forName: AerialAppStoreIAP.didUpdateProductsNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            // check if we need to initialize the visible categories with all free categories
            if AerialSettings.shared.numberOfVisibleCategories() == 0 {
                let categories = AerialCache.categories ?? []
                let freeCategories = categories.filter({ !$0.info.isProContent })
                for category in freeCategories {
                    AerialSettings.shared.setVisible(true, category: category)
                }
                AerialSettings.shared.sendDidUpdateVisibilityNotification()
            }
        }
    }

}

