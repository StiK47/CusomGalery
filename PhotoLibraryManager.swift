//
//  PhotoLibraryManager.swift
//  SocialFun
//
//  Created by Артем Малюгин on 05.10.2023.
//

import Combine
import Foundation
import Photos
import UIKit

final class PhotoLibraryManager: NSObject, ObservableObject {

    enum Status {
        case authorized(limited: Bool)
        case denied
    }

    @Published private(set) var assets: PHFetchResult<PHAsset>?

    var authorizationStatus: AnyPublisher<Status, Never> {
        Future<Status, Never> { [weak self] promise in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                switch status {
                case .notDetermined, .restricted, .denied:
                    promise(.success(.denied))
                case .authorized:
                    promise(.success(.authorized(limited: false)))
                    self?.fetchAllPhotos()
                case .limited:
                    promise(.success(.authorized(limited: true)))
                    self?.fetchAllPhotos()
                @unknown default:
                    promise(.success(.denied))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private let lock = NSLock()
    private let mediaTypeForLoad: PHAssetMediaType
    private let imageCachingManager: PHCachingImageManager
    private var requestImageIds: [String: PHImageRequestID] = [:]

    init(
        mediaTypeForLoad: PHAssetMediaType = .image,
        imageCachingManager: PHCachingImageManager = PHCachingImageManager()
    ) {
        self.mediaTypeForLoad = mediaTypeForLoad
        self.imageCachingManager = imageCachingManager
        self.imageCachingManager.allowsCachingHighQualityImages = false
        super.init()

        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func fetchImage(
        asset: PHAsset,
        deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic,
        targetSize: CGSize = PHImageManagerMaximumSize,
        contentMode: PHImageContentMode = .default,
        completion: @escaping (UIImage?) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.deliveryMode = deliveryMode
        options.isNetworkAccessAllowed = true

        let requestId = imageCachingManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options,
            resultHandler: { image, info in
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        )

        lock.lock()
        requestImageIds[asset.localIdentifier] = requestId
        lock.unlock()
    }

    func fetchImageData(asset: PHAsset, completion: @escaping (Data?) -> Void) {
        fetchImage(asset: asset, deliveryMode: .highQualityFormat) {
            completion($0?.pngData())
        }
    }

    func cancelImageRequest(byLocalIdentifier localId: String) {
        lock.lock()
        if let requestId = requestImageIds.removeValue(forKey: localId) {
            imageCachingManager.cancelImageRequest(requestId)
        }
        lock.unlock()
    }

    func saveImage(asset: AddedAsset) {
        UIImageWriteToSavedPhotosAlbum(asset.image, nil, nil, nil)
    }

    private func fetchAllPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(keyPath: \PHAsset.creationDate, ascending: false)]
        fetchOptions.includeHiddenAssets = false

        let assets = PHAsset.fetchAssets(with: self.mediaTypeForLoad, options: fetchOptions)

        DispatchQueue.main.async { [weak self] in
            self?.assets = assets
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension PhotoLibraryManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let assets = assets, let changeDetails = changeInstance.changeDetails(for: assets) else {
            return
        }
        self.assets = changeDetails.fetchResultAfterChanges
    }
}

extension Photos.PHAsset: Swift.Identifiable {
    public var id: String {
        localIdentifier
    }
}
