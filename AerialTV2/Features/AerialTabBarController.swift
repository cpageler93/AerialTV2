//
//  AerialTabBarController.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 26.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import UIKit


class AerialTabBarController: UITabBarController {

    private var firstFocus: Bool = true

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if firstFocus {
            firstFocus = false
            return selectedViewController?.preferredFocusEnvironments ?? []
        } else {
            return super.preferredFocusEnvironments
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.tabBar.alpha = 1
        }
    }

}
