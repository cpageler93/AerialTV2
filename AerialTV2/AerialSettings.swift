//
//  AerialSettings.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 26.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation


public class AerialSettings {

    public static let shared = AerialSettings()

    private init() {
        UserDefaults.standard.register(defaults: [
            "showDate" : true,
            "showTime": false
        ])
        loadVisibleCategoryProductIdentifiers()
    }

    private var visibleCategoryProductIdentifier: Set<String> = []

    private func loadVisibleCategoryProductIdentifiers() {
        let defaultsValue = UserDefaults.standard.array(forKey: "visibleCategoryProductIdentifier") as? [String]
        visibleCategoryProductIdentifier = Set(defaultsValue ?? [])
    }

    private func saveVisibleCategoryProductIdentifiers() {
        UserDefaults.standard.set(Array(visibleCategoryProductIdentifier), forKey: "visibleCategoryProductIdentifier")
        UserDefaults.standard.synchronize()
    }

    public func isVisible(category: AerialAPI.Category?) -> Bool {
        guard let category = category else { return false }
        return visibleCategoryProductIdentifier.contains(category.info.productIdentifier)
    }

    public func toggleVisibility(category: AerialAPI.Category) {
        let newVisibility = !isVisible(category: category)

        // prevent 0 visible categories
        if newVisibility == false && numberOfVisibleCategories() == 1 {
            return
        }

        setVisible(newVisibility, category: category)
    }

    public func setVisible(_ visible: Bool, category: AerialAPI.Category) {
        if visible {
            visibleCategoryProductIdentifier.insert(category.info.productIdentifier)
        } else {
            visibleCategoryProductIdentifier.remove(category.info.productIdentifier)
        }
        saveVisibleCategoryProductIdentifiers()
    }

    public func sendDidUpdateVisibilityNotification() {
        NotificationCenter.default.post(name: AerialSettings.didUpdateCategoryVisibilityNotification, object: nil)
    }

    public func numberOfVisibleCategories() -> Int {
        return visibleCategoryProductIdentifier.count
    }

    public var showDate: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "showDate")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: AerialSettings.didUpdateSettingsNotification, object: nil)
        }
        get {
            return UserDefaults.standard.bool(forKey: "showDate")
        }
    }

    public var showTime: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "showTime")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: AerialSettings.didUpdateSettingsNotification, object: nil)
        }
        get {
            return UserDefaults.standard.bool(forKey: "showTime")
        }
    }

    public static var didUpdateSettingsNotification = Notification.Name("AerialSettings.didUpdateSettingsNotification")
    public static var didUpdateCategoryVisibilityNotification = Notification.Name("AerialSettings.didUpdateCategoryVisibilityNotification")

}
