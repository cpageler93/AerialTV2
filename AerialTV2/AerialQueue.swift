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

    public init() {
        loadItems()

        NotificationCenter.default.addObserver(forName: AerialCache.didUpdateCategoriesNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            self.loadItems()
        }
    }

    private func loadItems() {
        items = AerialCache.categories?.compactMap({ $0.videos }).reduce([], +) ?? []
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
        print("pop current and refresh")
        items.remove(at: 0)
    }

}
