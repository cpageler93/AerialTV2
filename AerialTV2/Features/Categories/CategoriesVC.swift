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

    private var categories: [AerialAPI.Category] = []
    private var visibleCategory: AerialAPI.Category?

    @IBOutlet var activityIndicatorViewRestore: UIActivityIndicatorView!
    @IBOutlet var buttonRestore: UIButton!

    @IBOutlet var labelVisibleCategoryTitle: UILabel!
    @IBOutlet var labelVisibleCategorySubtitle: UILabel!
    @IBOutlet var activityIndicatorBecomePro: UIActivityIndicatorView!
    @IBOutlet var captionButtonViewBecomePro: TVCaptionButtonView!

    override func viewDidLoad() {
        super.viewDidLoad()

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
            self.updateBecomeProButton()
        }
        reloadCategories()
        reloadVisibleCategory()
        updateBecomeProButton()
    }

    private func reloadCategories() {
        categories = AerialCache.categories ?? []
        tableView.reloadData()
    }

    private func updateBecomeProButton() {
        guard let proProduct = AerialAppStoreIAP.shared.proProduct else {
            captionButtonViewBecomePro.isHidden = true
            return
        }

        captionButtonViewBecomePro.contentText = "BecomePro".localized()
        captionButtonViewBecomePro.title = proProduct.localizedPrice
        captionButtonViewBecomePro.subtitle = nil

        if AerialAppStoreIAP.shared.isPurchased(product: proProduct) {
            captionButtonViewBecomePro.isHidden = true
        } else {
            captionButtonViewBecomePro.isHidden = false
        }
    }

    private func reloadVisibleCategory() {
        guard let visibleCategory = visibleCategory else {
            labelVisibleCategoryTitle.text = ""
            labelVisibleCategorySubtitle.text = ""

            collectionView.isHidden = true
            return
        }

        labelVisibleCategoryTitle.text = visibleCategory.titleForCurrentLocale()
        labelVisibleCategorySubtitle.text = "\(visibleCategory.videos.count) \("Videos".localized())"

        collectionView.isHidden = false
        collectionView.reloadData()
    }

    // MARK: - Actions

    @IBAction func actionRestorePurchases(_ sender: UIButton) {
        activityIndicatorViewRestore.startAnimating()
        AerialAppStoreIAP.shared.restorePurchases {
            self.activityIndicatorViewRestore.stopAnimating()
            self.reloadCategories()
        }
    }

    @IBAction func actionBecomePro(_ sender: TVCaptionButtonView) {
        guard let proProduct = AerialAppStoreIAP.shared.proProduct else { return }

        activityIndicatorBecomePro.startAnimating()
        AerialAppStoreIAP.shared.purchase(product: proProduct) {
            self.activityIndicatorBecomePro.stopAnimating()

            self.updateBecomeProButton()
            self.reloadVisibleCategory()
            self.reloadCategories()
        }
    }

}

// MARK: - UITableViewDataSource

extension CategoriesVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let category = categories[safe: indexPath.row]
        cell.textLabel?.text = category?.titleForCurrentLocale()
//        let isPurchased = AerialAppStoreIAP.shared.isPurchased(product: categoryProduct?.product)
//        let canBePurchased = categoryProduct?.product != nil
        let isVisible = AerialSettings.shared.isVisible(category: category)
        let showCheckmark = isVisible
//        let showCheckmark = (isPurchased && isVisible) || (!canBePurchased && isVisible)
        cell.accessoryType = showCheckmark ? .checkmark : .none

        return cell
    }

}

// MARK: - UITableViewDelegate

extension CategoriesVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didUpdateFocusIn context: UITableViewFocusUpdateContext,
                   with coordinator: UIFocusAnimationCoordinator) {
        guard let indexPath = context.nextFocusedIndexPath else { return }
        guard let newVisibleCategory = categories[safe: indexPath.row] else { return }
        let newProductID = newVisibleCategory.info.productIdentifier
        let oldProductID = visibleCategory?.info.productIdentifier ?? ""
        guard oldProductID != newProductID else { return }
        visibleCategory = newVisibleCategory
        reloadVisibleCategory()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let category = categories[safe: indexPath.row] else { return }

        func toggleAndReload() {
            AerialSettings.shared.toggleVisibility(category: category)
            reloadCategories()
            AerialSettings.shared.sendDidUpdateVisibilityNotification()
        }

        if category.info.isProContent {
            if AerialAppStoreIAP.shared.isPro() {
                toggleAndReload()
            } else {
                AerialAppStoreIAP.shared.purchase(product: AerialAppStoreIAP.shared.proProduct) {
                    // check if user purchased product
                    if AerialAppStoreIAP.shared.isPro() {
                        toggleAndReload()
                    }
                }
            }
        } else {
            toggleAndReload()
        }

//        let canBePurchased = categoryProduct.product != nil
//        if AerialAppStoreIAP.shared.isPurchased(product: categoryProduct.product) || !canBePurchased {
//            AerialSettings.shared.toggleVisibility(category: categoryProduct.category)
//            reloadCategories()
//        } else {
//            AerialAppStoreIAP.shared.purchase(product: categoryProduct.product) {
//                // check if user purchased product
//                if AerialAppStoreIAP.shared.isPurchased(product: categoryProduct.product) {
//                    AerialSettings.shared.toggleVisibility(category: categoryProduct.category)
//                    self.reloadCategories()
//                }
//                self.reloadVisibleCategory()
//            }
//        }
//        AerialSettings.shared.sendDidUpdateVisibilityNotification()
    }

}

// MARK: - UICollectionViewDataSource

extension CategoriesVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategory?.videos.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoPosterCollectionViewCell",
                                                      for: indexPath) as! VideoPosterCollectionViewCell

        let video = visibleCategory?.videos[safe: indexPath.row]
        cell.posterView.title = video?.title
        cell.posterView.subtitle = video?.author
        cell.posterView.image = AerialImageProvider.shared.image(for: video)

        return cell
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

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

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    // vertical
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 50
    }

    // horizonal
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 50
    }

}
