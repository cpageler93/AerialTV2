//
//  String.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 27.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation


public extension String {

    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }

}
