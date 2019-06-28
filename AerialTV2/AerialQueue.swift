//
//  AerialQueue.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 26.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation


public class AerialQueue {

    public var items: [AerialAPI.Video] = []

    private var allQueueableItems: [AerialAPI.Video] = []

    public init() {
        NotificationCenter.default.addObserver(forName: AerialCache.didUpdateCategoriesNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            self.reloadData()
        }

        NotificationCenter.default.addObserver(forName: AerialSettings.didUpdateCategoryVisibiliyNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            self.reloadData()
        }

        reloadData()
    }

    private func reloadData() {
        let availableCagegories = AerialCache.categories?.filter { category in
            let isVisible = AerialSettings.shared.isVisible(category: category)
            let isPurchased = AerialAppStoreIAP.shared.isPurchased(productIdentifier: category.info.productIdentifier)
            return isVisible && isPurchased
        } ?? []
        allQueueableItems = availableCagegories.compactMap({ $0.videos }).reduce([], +)
        if items.count == 0 {
            items = allQueueableItems
        }
    }

    public func currentItem() -> AerialAPI.Video? {
        return items.first
    }

    public func nextItem() -> AerialAPI.Video? {
        guard let currentItem = currentItem() else { return nil }
        guard let index = items.firstIndex(of: currentItem) else { return nil }
        return items[safe: index + 1]
    }

    public func popCurrent() {
        items.remove(at: 0)
        guard items.count <= 2 else { return }
        items.append(contentsOf: allQueueableItems)
    }

}
