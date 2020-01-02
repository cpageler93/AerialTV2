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

    private var hideTabbarTimer: Timer?

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return tabBar.preferredFocusEnvironments
        if firstFocus {
            firstFocus = false
            return selectedViewController?.preferredFocusEnvironments ?? []
        } else {
            return super.preferredFocusEnvironments
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        let tapGestureMenu = UITapGestureRecognizer(target: self, action: #selector(gestureTapMenu))
        tapGestureMenu.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(tapGestureMenu)

        let swipeGestureDown = UISwipeGestureRecognizer(target: self, action: #selector(gestureSwipeDown))
        swipeGestureDown.direction = .down
        view.addGestureRecognizer(swipeGestureDown)

        let swipeGestureUp = UISwipeGestureRecognizer(target: self, action: #selector(gestureSwipeUp))
        swipeGestureUp.direction = .up
        view.addGestureRecognizer(swipeGestureUp)

        tabBar.alpha = 0

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.tabBar.items?[safe: 0]?.title = "Screensaver".localized()
            self.tabBar.items?[safe: 1]?.title = "Categories".localized()
            self.tabBar.items?[safe: 2]?.title = "Settings".localized()
        }
    }

    @objc private func gestureTapMenu(_ gesture: UITapGestureRecognizer) {
        tabBar.alpha = 1
        view.setNeedsFocusUpdate()
    }

    @objc private func gestureSwipeDown(_ gesture: UITapGestureRecognizer) {
        if selectedIndex == 0 {
            tabBar.alpha = 0
        }
    }

    @objc private func gestureSwipeUp(_ gesture: UITapGestureRecognizer) {
        if selectedIndex == 0 {
            tabBar.alpha = 1
            view.setNeedsFocusUpdate()
        }
    }

    private func startHideTabbarTimer() {
        hideTabbarTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
            timer.invalidate()
            if self.selectedIndex == 0 {
                self.tabBar.alpha = 0
            }
        })
    }

    private func endHideTabbarTimer() {
        hideTabbarTimer?.invalidate()
        hideTabbarTimer = nil
    }

}


extension AerialTabBarController: UITabBarControllerDelegate {

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let selectIndex = tabBar.items?.firstIndex(of: item) ?? 0
        if selectIndex == 0 && selectedIndex != 0 {
            startHideTabbarTimer()
        } else {
            endHideTabbarTimer()
        }
    }

}
