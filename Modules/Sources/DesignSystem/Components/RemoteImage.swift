//
//  RemoteImage.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Kingfisher
import SwiftUI

/// Remote image with memory + disk cache, downsampling and fade-in.
/// Wraps Kingfisher so features never import it directly.
///
///     RemoteImage(url: event.thumbnailURL)
///         .frame(width: 80, height: 80)
///         .cornerRadius(.s)
public struct RemoteImage: View {
    private let url: URL?
    private let contentMode: SwiftUI.ContentMode
    @Environment(\.displayScale) private var displayScale

    /// - Parameter contentMode: `.fill` (default, cropped) or `.fit`.
    public init(url: URL?, contentMode: SwiftUI.ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
    }

    public var body: some View {
        // Downsample to the rendered size: decoding a 4000px photo for an
        // 80pt thumbnail wastes memory and scroll performance.
        Color.skeleton
            .overlay {
                GeometryReader { proxy in
                    KFImage(url)
                        .setProcessor(DownsamplingImageProcessor(size: proxy.size))
                        .scaleFactor(displayScale)
                        .cacheOriginalImage(false)
                        .fade(duration: 0.2)
                        .cancelOnDisappear(true)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .clipped()
    }
}

public extension UIImageView {
    /// UIKit / Storyboard counterpart of `RemoteImage`.
    func setRemoteImage(_ url: URL?, placeholder: UIImage? = nil) {
        let size = bounds.size == .zero ? CGSize(width: 300, height: 300) : bounds.size
        kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .processor(DownsamplingImageProcessor(size: size)),
                .scaleFactor(traitCollection.displayScale),
                .transition(.fade(0.2)),
            ]
        )
    }

    /// Call from `prepareForReuse()` so recycled cells don't show old images.
    func cancelRemoteImage() {
        kf.cancelDownloadTask()
        image = nil
    }
}

/// Image cache controls (e.g. call `clearMemory()` on memory warning).
public enum ImageCache {
    /// Call once at launch (done in `AppAssembly`).
    public static func configure(memoryLimitMB: Int = 100, diskLimitMB: UInt = 300) {
        let cache = KingfisherManager.shared.cache
        cache.memoryStorage.config.totalCostLimit = memoryLimitMB * 1024 * 1024
        cache.diskStorage.config.sizeLimit = diskLimitMB * 1024 * 1024
    }

    /// Frees decoded images (memory warning, background processing).
    public static func clearMemory() {
        KingfisherManager.shared.cache.clearMemoryCache()
    }
}
