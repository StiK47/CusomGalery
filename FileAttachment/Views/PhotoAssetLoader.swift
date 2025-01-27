//
//  PhotoAssetLoader.swift
//  SocialFun
//
//  Created by Артем Малюгин on 05.10.2023.
//

import Combine
import Foundation
import Photos
import SwiftUI

enum AsyncImagePhase {
    case empty
    case success(UIImage)
    case failure(AnyUnifiedError)
}

final class PhotoAssetLoader: ObservableObject {

    @Published private(set) var phase = AsyncImagePhase.empty

    private var imageRequestId: PHImageRequestID?
    private let imageCachingManager = PHCachingImageManager()

    deinit {
        cancel()
    }

    func load(source: PHAsset) {
        fetchImage(asset: source) { [weak self] image in
            if let image {
                self?.phase = .success(image)
            } else {
                self?.phase = .failure(PhotoLibraryError.notFound.anyUnifiedError)
            }
        }
    }

    func cancel() {
        if let requestId = imageRequestId {
            imageCachingManager.cancelImageRequest(requestId)
            imageRequestId = nil
        }
        phase = .empty
    }

    private func fetchImage(
        asset: PHAsset,
        deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic,
        targetSize: CGSize = PHImageManagerMaximumSize,
        contentMode: PHImageContentMode = .default,
        completion: @escaping (UIImage?) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.deliveryMode = deliveryMode
        options.isNetworkAccessAllowed = true

        imageRequestId = imageCachingManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options,
            resultHandler: { image, _ in
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        )
    }
}
