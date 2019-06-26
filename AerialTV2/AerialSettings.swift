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
        setVisible(!isVisible(category: category), category: category)
    }

    public func setVisible(_ visible: Bool, category: AerialAPI.Category) {
        if visible {
            visibleCategoryProductIdentifier.insert(category.info.productIdentifier)
        } else {
            visibleCategoryProductIdentifier.remove(category.info.productIdentifier)
        }
        saveVisibleCategoryProductIdentifiers()
    }

}
