//
//  PhotoAttachmentView.swift
//  SocialFun
//
//  Created by Артем Малюгин on 09.10.2024.
//

import Photos
import SwiftUI

struct PhotoAttachmentView: View {
    @Environment(\.openURL) private var openURL: OpenURLAction

    var stateAccess: StateAccess
    var firstBlockAssets: [PHAsset]
    var secondBlockAssets: [PHAsset]
    var cameraFrame: CGImage?
    var cameraAppear: () -> Void
    var cameraDisappear: () -> Void
    var cameraAssetPicked: (AddedAsset) -> Void
    var imageTapped: (AddedAsset) -> Void
    var imageSelected: (String) -> Bool?

    @State private var cameraShown = false
    @State private var alertCameraOpenSettingsShown = false
    @State private var alertPhotoLibraryOpenSettingsShown = false

    var body: some View {
        VStack {
            switch stateAccess {
            case let .all(limited):
                VStack(spacing: 0) {
                    if limited {
                        provideFullAccessPhotosView
                    }
                    ThumbnailGridView(
                        firstBlockAssets: firstBlockAssets,
                        secondBlockAssets: secondBlockAssets,
                        imageSelected: imageSelected,
                        imageTapped: imageTapped,
                        camera: { cameraView }
                    )
                }
            case .onlyCamera:
                GeometryReader { proxy in
                    HStack(spacing: 2) {
                        cameraView
                            .frame(width: abs(proxy.size.width - 4) / 3)
                        GridPlaceholderView(icon: .gallery, title: "Доступ к галерее")
                            .frame(width: abs(proxy.size.width - 4) / 3)
                            .onTapGesture {
                                alertPhotoLibraryOpenSettingsShown = true
                            }
                    }
                    .frame(height: (proxy.size.width - 4) * 2/3)
                }
            case let .onlyPhotoLibrary(limited):
                VStack(spacing: 0) {
                    if limited {
                        provideFullAccessPhotosView
                    }

                    ThumbnailGridView(
                        firstBlockAssets: firstBlockAssets,
                        secondBlockAssets: secondBlockAssets,
                        imageSelected: imageSelected,
                        imageTapped: imageTapped,
                        camera: {
                            GridPlaceholderView(icon: .cameraPlaceholder, title: "Доступ к камере")
                                .onTapGesture {
                                    alertCameraOpenSettingsShown = true
                                }
                        }
                    )
                }
            case .nothing:
                GeometryReader { proxy in
                    HStack(spacing: 2) {
                        GridPlaceholderView(icon: .cameraPlaceholder, title: "Доступ к камере")
                            .frame(width: abs(proxy.size.width - 4) / 3)
                            .onTapGesture {
                                alertCameraOpenSettingsShown = true
                            }
                        GridPlaceholderView(icon: .gallery, title: "Доступ к галерее")
                            .frame(width: abs(proxy.size.width - 4) / 3)
                            .onTapGesture {
                                alertPhotoLibraryOpenSettingsShown = true
                            }
                    }
                    .frame(height: abs(proxy.size.width - 4) / 3)
                }
            }
        }
        .sheet(isPresented: $cameraShown) {
            ImagePickerView(
                sourceType: .camera,
                assetPicked: cameraAssetPicked
            )
            .background(.black)
        }
        .sheet(isPresented: $alertCameraOpenSettingsShown) {
            ResultView(
                icon: .smilegood,
                title: "Разрешите использовать вашу камеру?",
                message: "Разрешите использовать вашу камеру",
                buttonText: "Открыть настройки",
                dismissButtonText: "Закрыть",
                completion: {
                    alertCameraOpenSettingsShown = false
                    openSettings()
                },
                dismiss: {
                    alertCameraOpenSettingsShown = false
                }
            )
        }
        .sheet(isPresented: $alertPhotoLibraryOpenSettingsShown) {
            ResultView(
                icon: .smilegood,
                title: "Разрешите использовать галерею устройства?",
                message: "Разрешите использовать фото из галереи",
                buttonText: "Открыть настройки",
                dismissButtonText: "Закрыть",
                completion: {
                    alertPhotoLibraryOpenSettingsShown = false
                    openSettings()
                },
                dismiss: {
                    alertPhotoLibraryOpenSettingsShown = false
                }
            )
        }
    }

    private var cameraView: some View {
        ZStack(alignment: .topTrailing) {
            CameraFrameView(image: cameraFrame)

            Image(.camera)
                .padding(10)
        }
        .onAppear { cameraAppear() }
        .onDisappear { cameraDisappear() }
        .onTapGesture { cameraShown = true }
    }

    var provideFullAccessPhotosView: some View {
        HStack(spacing: 0) {
            Text("Ты не предоставил доступ ко всем фотографиям")
                .font(.regular14)
                .foregroundStyle(Color.defaultTheme.textSecondary)

            Spacer(minLength: 8)

            Button(action: {
                openSettings()
            }) {
                Text("Предоставить")
                    .font(.medium12)
                    .foregroundStyle(Color.defaultTheme.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
            .frame(height: 28)
            .background(Color.defaultTheme.main)
            .clipShape(.capsule)
        }
        .padding(16)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}
