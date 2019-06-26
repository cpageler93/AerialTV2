//
//  ScreensaverVC.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 26.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import UIKit
import AVKit


class ScreensaverVC: UIViewController {

    private var playerController1: AVPlayerViewController?
    private var playerController2: AVPlayerViewController?

    private weak var playerControllerActive: AVPlayerViewController?
    private weak var playerControllerInactive: AVPlayerViewController? {
        guard let playerControllerActive = playerControllerActive else {
            return playerController1
        }

        switch playerControllerActive {
        case playerController1: return playerController2
        case playerController2: return playerController1
        default: return nil
        }
    }
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!

    private var timerLoadNextVideo: Timer?

    private let queue = AerialQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

        playerController1?.player = nil
        playerController1?.view?.alpha = 0
        playerController2?.player = nil
        playerController2?.view?.alpha = 0

        NotificationCenter.default.addObserver(forName: AerialCache.didUpdateCategoriesNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            if self.playerController1?.player == nil && self.playerController2?.player == nil {
                self.prepareInitialVideo()
            }
        }
        prepareInitialVideo()
    }

    private func prepareInitialVideo() {
        guard let playerController = playerControllerInactive else { return }
        guard let video = queue.currentItem() else { return }
        guard let (player, asset) = player(for: video) else { return }
        play(player: player, asset: asset, for: playerController)
        activityIndicatorView.stopAnimating()
    }

    private func player(for video: AerialAPI.Video) -> (AVPlayer, AVAsset)? {
        guard let url = URL(string: video.url) else { return nil }

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true

        return (player, asset)
    }

    private func prepareTimerForNextVideo(currentItemDuration: TimeInterval) {
        guard let playerControllerInactive = playerControllerInactive else { return }
        guard let nextItem = queue.nextItem() else { return }
        let preloadDurationInSeconds = 5.0
        let startIn = max(currentItemDuration - preloadDurationInSeconds, 0)

        timerLoadNextVideo?.invalidate()
        timerLoadNextVideo = Timer.scheduledTimer(withTimeInterval: startIn, repeats: false) { _ in
            guard let (player, asset) = self.player(for: nextItem) else { return }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (preloadDurationInSeconds - 1)) {
                self.queue.popCurrent()
                self.play(player: player, asset: asset, for: playerControllerInactive)
            }
        }
    }

    private func play(player: AVPlayer, asset: AVAsset, for playerController: AVPlayerViewController) {
        player.playImmediately(atRate: 0.7)

        playerControllerActive = playerController
        playerController.player = player
        UIView.animate(withDuration: 1) {
            playerController.view.alpha = 1
            self.playerControllerInactive?.view.alpha = 0
        }

        prepareTimerForNextVideo(currentItemDuration: asset.duration.seconds / Double(player.rate))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embeddedAVPlayerViewController1",
            let playerController = segue.destination as? AVPlayerViewController
        {
            self.playerController1 = playerController
        }

        if segue.identifier == "embeddedAVPlayerViewController2",
            let playerController = segue.destination as? AVPlayerViewController
        {
            self.playerController2 = playerController
        }
    }

}
