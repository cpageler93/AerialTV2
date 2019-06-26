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
    }

}

