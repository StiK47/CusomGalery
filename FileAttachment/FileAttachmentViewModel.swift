//
//  FileAttachmentViewModel.swift
//  SocialFun
//
//  Created by Артем Малюгин on 04.10.2023.
//

import Combine
import Foundation
import Photos

enum StateAccess {
    case all(limited: Bool)
    case onlyCamera
    case onlyPhotoLibrary(limited: Bool)
    case nothing
}

final class FileAttachmentViewModel: ObservableObject {

    enum SelectionType: Hashable {
        case single
        case multiple(maxCount: Int)
        case chat

        var maxCount: Int {
            switch self {
            case .single:
                return 1
            case let .multiple(maxCount):
                return maxCount
            case .chat:
                return 10
            }
        }
    }

    @Published var frame: CGImage?
    @Published var isAssetLoading = true
    @Published var stateAccess: StateAccess = .nothing

    @Published var isMaxAssetsSelected = false
    @Published var errorLoadFiles = false

    @Published private(set) var selection: SelectionType
    @Published private(set) var isLoading = false
    @Published private(set) var selectedAssets: [AddedAsset] = []
    @Published private(set) var firstBlockAssets: [PHAsset] = []
    @Published private(set) var secondBlockAssets: [PHAsset] = []

    var session: AVCaptureSession {
        cameraManager.captureSession
    }

    private(set) var photoLibraryManager: PhotoLibraryManager

    private let context = CIContext()
    private let cameraManager: CameraManager
    private let frameManager: FrameManager
    private let mediaService: IMediaService
    private var cancellables = Set<AnyCancellable>()

    private var canAddAdditionalAsset: Bool {
        selectedAssets.count < selection.maxCount
    }

    init(
        selectedAssests: [AddedAsset] = [],
        selection: SelectionType,
        cameraManager: CameraManager = .shared,
        frameManager: FrameManager = .shared,
        photoLibraryManager: PhotoLibraryManager = PhotoLibraryManager(),
        mediaService: IMediaService = MediaService()
    ) {
        self.selectedAssets = selectedAssests
        self.selection = selection
        self.cameraManager = cameraManager
        self.frameManager = frameManager
        self.mediaService = mediaService
        self.photoLibraryManager = photoLibraryManager

        bind()
    }

    func loadFiles(urls: [URL]) {
        print(urls.count)

        for url in urls {
            print(url.path)
        }
    }

    func imageTapped(_ asset: AddedAsset) {
        if selectedAssets.contains(asset) {
            selectedAssets.remove(asset)
        } else if canAddAdditionalAsset {
            selectedAssets.append(asset)
        } else {
            isMaxAssetsSelected = true
        }
    }

    func isImageSelected(with id: String) -> Bool? {
        guard selection != .single else { return nil }

        for image in selectedAssets {
            if image.id == id {
                return true
            }
        }
        return false
    }

    func sendAssets(_ assets: [AddedAsset], completion: @escaping ([String]) -> ()) {
        isLoading = true
        mediaService.upload(assets: assets)
            .asLoadable()
            .sink { [weak self] output in
                self?.isLoading = output.isLoading
                if let urls = output.payload {
                    completion(urls)
                } else {
                    self?.errorLoadFiles = true
                }
            }
            .store(in: &cancellables)
    }

    private func bind() {
        frameManager.$current
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] buffer in
                guard let image = CGImage.create(from: buffer) else {
                    return nil
                }

                let ciImage = CIImage(cgImage: image)
                return self?.context.createCGImage(ciImage, from: ciImage.extent)
            }
            .weakAssign(to: \.frame, on: self)
            .store(in: &cancellables)

        photoLibraryManager.$assets
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] assets in
                self?.isAssetLoading = false
                self?.firstBlockAssets = assets.objects(at: IndexSet(0..<4))
                self?.secondBlockAssets = assets.objects(at: IndexSet(4..<assets.count))
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(photoLibraryManager.authorizationStatus, cameraManager.authorizationStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photoLibraryStatus, isCameraAuthorized in
                switch photoLibraryStatus {
                case let .authorized(limited):
                    self?.stateAccess = isCameraAuthorized ? .all(limited: limited) : .onlyPhotoLibrary(limited: limited)
                case .denied:
                    self?.stateAccess = isCameraAuthorized ? .onlyCamera : .nothing
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Camera methods

extension FileAttachmentViewModel {
    func configurateCamera() {
        cameraManager.configure()
    }
    
    func startCamera() {
        cameraManager.start()
    }

    func stopCamera() {
        cameraManager.stop()
    }

    func saveImage(_ asset: AddedAsset) {
        photoLibraryManager.saveImage(asset: asset)
    }
}
