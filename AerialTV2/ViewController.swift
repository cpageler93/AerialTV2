//
//  ViewController.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 24.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import UIKit
import SwiftyStoreKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            SwiftyStoreKit.purchaseProduct("de.pageler.christoph.aerialtv2.forest", completion: { (result) in
                
            })
        }
    }


}

