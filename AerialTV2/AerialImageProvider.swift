//
//  AerialImageProvider.swift
//  AerialTV2
//
//  Created by Christoph Pageler on 26.06.19.
//  Copyright © 2019 Christoph Pageler. All rights reserved.
//


import Foundation
import UIKit
import AVKit


public class AerialImageProvider {

    private static var cacheURL: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory().appending("images.cache"))
    }

    public static let shared = AerialImageProvider()

    private var imageCache: [AerialAPI.Video: UIImage] = [:]

    /// The preferred way to collect an cached image
    ///
    /// - Parameter video: the video
    /// - Returns: an image from cache or asset generator
    public func image(for video: AerialAPI.Video?) -> UIImage? {
        guard let video = video else { return nil }
        if let imageFromCache = imageCache[video] {
            return imageFromCache
        }

        if let image = imageFromTempDirectory(for: video) {
            imageCache[video] = image
            return image
        }

        if let image = imageFromAssetGenerator(for: video) {
            imageCache[video] = image
            saveImageToTempDirectory(for: video, image: image)
            return image
        }

        return nil
    }

    private func imageFromTempDirectory(for video: AerialAPI.Video) -> UIImage? {
        guard let url = cacheURL(for: video) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func saveImageToTempDirectory(for video: AerialAPI.Video, image: UIImage) {
        guard let url = cacheURL(for: video) else { return }
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        if !FileManager.default.fileExists(atPath: AerialImageProvider.cacheURL.path) {
            try? FileManager.default.createDirectory(atPath: AerialImageProvider.cacheURL.path,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
        do {
            try data.write(to: url)
        } catch {
            print("failed")
        }
    }

    private func cacheURL(for video: AerialAPI.Video) -> URL? {
        guard let base64URL = video.url.data(using: .utf8)?.base64EncodedString() else { return nil }
        return AerialImageProvider.cacheURL.appendingPathComponent(base64URL)
    }

    /// generates an image from the given video with the AVAssetImageGenerator
    ///
    /// - Parameter video: video to generate the image from
    /// - Returns: image when the generation was successfull
    private func imageFromAssetGenerator(for video: AerialAPI.Video) -> UIImage? {
        guard let url = URL(string: video.url) else { return nil }
        let asset = AVAsset(url: url)

        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        if let cgImage = try? assetImageGenerator.copyCGImage(at: CMTime(value: 0, timescale: 1), actualTime: nil) {
            let image = UIImage(cgImage: cgImage)
            return image
        } else {
            return nil
        }
    }

    /// Checks if image is missing in temp directory, if the image is missing this method tries to generate the images
    /// with the asset generator. If the generation was successfull this method writes the image to the temp directory.
    ///
    /// - Parameter videos: videos to cache images
    public func preloadImages(for videos: [AerialAPI.Video]) {
        DispatchQueue.global(qos: .background).async {
            for video in videos {
                if self.imageFromTempDirectory(for: video) == nil {
                    if let image = self.imageFromAssetGenerator(for: video) {
                        self.saveImageToTempDirectory(for: video, image: image)
                    }
                }
            }
        }
    }

}
