//
//  CategoriesVC.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 26.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import UIKit
import TVUIKit


class CategoriesVC: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!

    private var categories: [AerialProductMapper.CategoryProduct] = []
    private var visibleCategory: AerialProductMapper.CategoryProduct?

    @IBOutlet var activityIndicatorViewRestore: UIActivityIndicatorView!
    @IBOutlet var buttonRestore: UIButton!

    @IBOutlet var labelVisibleCategoryTitle: UILabel!
    @IBOutlet var labelVisibleCategorySubtitle: UILabel!
    @IBOutlet var captionButtonViewVisibleCategoryBuy: TVCaptionButtonView!

    override func viewDidLoad() {
        super.viewDidLoad()

        labelVisibleCategoryTitle.text = ""
        labelVisibleCategorySubtitle.text = ""
        captionButtonViewVisibleCategoryBuy.isHidden = true

        buttonRestore.setTitle("RestorePurchases".localized(), for: .normal)

        NotificationCenter.default.addObserver(forName: AerialCache.didUpdateCategoriesNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            self.reloadCategories()
        }
        NotificationCenter.default.addObserver(forName: AerialAppStoreIAP.didUpdateProductsNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            self.reloadCategories()
        }
        reloadCategories()
    }

    private func reloadCategories() {
        let productMapper = AerialProductMapper()
        categories = productMapper.map(categories: AerialCache.categories ?? [])
        tableView.reloadData()
    }

    private func reloadVisibleCategory() {
        labelVisibleCategoryTitle.text = visibleCategory?.title()
        labelVisibleCategorySubtitle.text = "\(visibleCategory?.category.videos.count ?? 0) \("Videos".localized())"

        captionButtonViewVisibleCategoryBuy.contentText = "Buy".localized()
        captionButtonViewVisibleCategoryBuy.title = visibleCategory?.localizedPrice()
        let isPurchased = AerialAppStoreIAP.shared.isPurchased(product: visibleCategory?.product)
        let canBePurchased = visibleCategory?.product != nil
        let showBuy = !isPurchased && canBePurchased
        captionButtonViewVisibleCategoryBuy.isHidden = !showBuy

        collectionView.reloadData()
    }

    @IBAction func actionRestorePurchases(_ sender: UIButton) {
        activityIndicatorViewRestore.startAnimating()
        AerialAppStoreIAP.shared.restorePurchases {
            self.activityIndicatorViewRestore.stopAnimating()
            self.reloadCategories()
        }
    }

    @IBAction func actionBuyVisibleCategory(_ sender: TVCaptionButtonView) {
        guard let visibleCategory = visibleCategory else { return }
        AerialAppStoreIAP.shared.purchase(product: visibleCategory.product) {
            self.reloadCategories()
            self.reloadVisibleCategory()
        }
    }

}


extension CategoriesVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let categoryProduct = categories[safe: indexPath.row]
        cell.textLabel?.text = categoryProduct?.title()
        let isPurchased = AerialAppStoreIAP.shared.isPurchased(product: categoryProduct?.product)
        let canBePurchased = visibleCategory?.product != nil
        let isVisible = AerialSettings.shared.isVisible(category: categoryProduct?.category)
        let showCheckmark = (isPurchased && isVisible) || (!canBePurchased && isVisible)
        cell.accessoryType = showCheckmark ? .checkmark : .none

        return cell
    }

}


extension CategoriesVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didUpdateFocusIn context: UITableViewFocusUpdateContext,
                   with coordinator: UIFocusAnimationCoordinator) {
        guard let indexPath = context.nextFocusedIndexPath else { return }
        guard let newVisibleCategory = categories[safe: indexPath.row] else { return }
        let newProductID = newVisibleCategory.category.info.productIdentifier
        let oldProductID = visibleCategory?.category.info.productIdentifier ?? ""
        guard oldProductID != newProductID else { return }
        visibleCategory = newVisibleCategory
        reloadVisibleCategory()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let categoryProduct = categories[safe: indexPath.row] else { return }

        let canBePurchased = categoryProduct.product != nil
        if AerialAppStoreIAP.shared.isPurchased(product: categoryProduct.product) || !canBePurchased {
            AerialSettings.shared.toggleVisibility(category: categoryProduct.category)
            reloadCategories()
        } else {
            AerialAppStoreIAP.shared.purchase(product: categoryProduct.product) {
                // check if user purchased product
                if AerialAppStoreIAP.shared.isPurchased(product: categoryProduct.product) {
                    AerialSettings.shared.toggleVisibility(category: categoryProduct.category)
                    self.reloadCategories()
                }
                self.reloadVisibleCategory()
            }
        }
    }

}


extension CategoriesVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategory?.category.videos.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoPosterCollectionViewCell",
                                                      for: indexPath) as! VideoPosterCollectionViewCell

        let video = visibleCategory?.category.videos[safe: indexPath.row]
        cell.posterView.title = video?.title
        cell.posterView.subtitle = video?.author
        cell.posterView.image = AerialImageProvider.shared.image(for: video)

        return cell
    }

}


extension CategoriesVC: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let interitemSpacing = self.collectionView(collectionView,
                                                   layout: collectionViewLayout,
                                                   minimumInteritemSpacingForSectionAt: indexPath.section)
        let itemsInRow = 2
        let itemsWithSpacing = itemsInRow - 1
        let totalInterItemSpacing = CGFloat(itemsWithSpacing) * interitemSpacing
        let itemWidth = (collectionView.frame.size.width - totalInterItemSpacing) / CGFloat(itemsInRow)
        let ratio = 4.0 / 3.0
        let itemHeight = itemWidth / CGFloat(ratio)

        return CGSize(width: itemWidth, height: itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    // vertical
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 50
    }

    // horizonal
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 50
    }

}
