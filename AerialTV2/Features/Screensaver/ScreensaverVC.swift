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

    @IBOutlet var labelDate: UILabel!
    private var dateFormatter = DateFormatter()
    private var timerUpdateDate: Timer?

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

    private var queue = AerialQueue()

    private var firstAppear: Bool = true

    private var playerRate: Float = 0.9

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

        NotificationCenter.default.addObserver(forName: AerialSettings.didUpdateSettingsNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            self.prepareUIFromSettings()
        }
        NotificationCenter.default.addObserver(forName: AerialSettings.didUpdateCategoryVisibilityNotification,
                                               object: nil,
                                               queue: .main)
        { _ in
            // reset all players and simulate new run
            self.playerController1?.player?.pause()
            self.playerController1?.player = nil
            self.playerController2?.player?.pause()
            self.playerController2?.player = nil
            self.playerControllerActive = nil
            self.timerLoadNextVideo?.invalidate()
            self.timerLoadNextVideo = nil
            self.queue = AerialQueue()

            self.prepareInitialVideo()
        }
        prepareUIFromSettings()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        timerUpdateDate?.invalidate()

        timerLoadNextVideo?.invalidate()
        playerControllerActive?.player?.pause()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard !firstAppear else {
            firstAppear = false
            return
        }

        prepareUIFromSettings()
        playerControllerActive?.player?.playImmediately(atRate: playerRate)
        let currentSeconds = playerControllerActive?.player?.currentTime().seconds ?? 0
        let totalSeconds = playerControllerActive?.player?.currentItem?.duration.seconds ?? 0
        let remainingSeconds = totalSeconds - currentSeconds
        prepareTimerForNextVideo(currentItemDuration: remainingSeconds / Double(playerRate))
    }

    private func prepareUIFromSettings() {
        // Date
        let showDateOrTime = AerialSettings.shared.showDate || AerialSettings.shared.showTime
        labelDate.isHidden = !showDateOrTime
        dateFormatter.dateStyle = AerialSettings.shared.showDate ? .medium : .none
        dateFormatter.timeStyle = AerialSettings.shared.showTime ? .medium : .none

        timerUpdateDate?.invalidate()
        if showDateOrTime {
            timerUpdateDate = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                self.updateLabelWithCurrentDate()
            })
            updateLabelWithCurrentDate()
        }
    }

    private func updateLabelWithCurrentDate() {
        labelDate.text = dateFormatter.string(from: Date())
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
        player.playImmediately(atRate: playerRate)

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
