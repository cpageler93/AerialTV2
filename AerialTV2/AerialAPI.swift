//
//  AerialAPI.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 24.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation


public class AerialAPI {

    public let contentURL = URL(string: "https://aerialtv.fra1.cdn.digitaloceanspaces.com/content.json")!

    public func getCategoriesFromContent(completion: @escaping ([Category]? ) -> Void) {
        getContent { content in
            guard let content = content else {
                completion(nil)
                return
            }
            self.getCategories(from: content, completion: completion)
        }
    }

    public func getContent(completion: @escaping (Content?) -> Void) {
        URLSession.shared.dataTask(with: contentURL) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }
            guard let content = try? JSONDecoder().decode(Content.self, from: data) else {
                completion(nil)
                return
            }
            completion(content)
        }.resume()
    }

    public func getCategories(from content: Content, completion: @escaping ([Category]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var categories: [Category] = []
            let dispatchGroup = DispatchGroup()
            for categoryURL in content.categories {
                dispatchGroup.enter()
                self.getCategory(from: categoryURL) { category in
                    if let category = category {
                        categories.append(category)
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.wait()
            DispatchQueue.main.async {
                completion(categories)
            }
        }
    }

    private func getCategory(from categoryURL: String, completion: @escaping (Category?) -> Void) {
        guard let url = URL(string: categoryURL) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }
            guard let category = try? JSONDecoder().decode(Category.self, from: data) else {
                completion(nil)
                return
            }
            completion(category)
        }.resume()
    }

}

// MARK: - Content

public extension AerialAPI {

    struct Content: Codable {

        public let categories: [String]

    }

}

// MARK: - Category

public extension AerialAPI {

    struct Category: Codable {

        public struct Info: Codable {

            public let productIdentifier: String

            enum CodingKeys: String, CodingKey {
                case productIdentifier = "product_identifier"
            }

        }

        public let info: Info
        public let videos: [Video]

    }

}

// MARK: - Video

public extension AerialAPI {

    struct Video: Codable, Hashable, Equatable {

        public let title: String
        public let url: String
        public let duration: Int
        public let fps: Int
        public let resolution: String
        public let author: String

    }

}
