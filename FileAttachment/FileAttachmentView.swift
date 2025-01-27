//
//  FileAttachmentView.swift
//  SocialFun
//
//  Created by Артем Малюгин on 04.10.2023.
//

import SwiftUI

struct FileAttachmentView: View {

    enum AttachmentType {
        case message(fileUrls: [String], text: String)
        case assets([AddedAsset])
    }

    @Environment(\.openURL) private var openURL: OpenURLAction
    @Environment(\.dismiss) private var dismiss: DismissAction

    @StateObject private var viewModel: FileAttachmentViewModel

    @State private var showFileImporter = false

    private let completion: ((AttachmentType) -> ())?

    init(
        viewModel: FileAttachmentViewModel,
        completion: ((AttachmentType) -> ())? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.completion = completion
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isAssetLoading {
                    LoadingView()
                } else {
                    PhotoAttachmentView(
                        stateAccess: viewModel.stateAccess,
                        firstBlockAssets: viewModel.firstBlockAssets,
                        secondBlockAssets: viewModel.secondBlockAssets,
                        cameraFrame: viewModel.frame,
                        cameraAppear: {
                            viewModel.configurateCamera()
                            viewModel.startCamera()
                        },
                        cameraDisappear: { viewModel.stopCamera() },
                        cameraAssetPicked: { asset in
                            if viewModel.selection == .chat {
                                viewModel.sendAssets([asset]) { urls in
                                    viewModel.saveImage(asset)
                                    completion?(.message(fileUrls: urls, text: ""))
                                    dismiss()
                                }
                            } else {
                                viewModel.saveImage(asset)
                                completion?(.assets([asset]))
                            }
                        },
                        imageTapped: {
                            if viewModel.selection == .single {
                                completion?(.assets([$0]))
                                dismiss()
                            } else {
                                viewModel.imageTapped($0)
                            }
                        },
                        imageSelected: { viewModel.isImageSelected(with: $0) }
                    )
                }
            }
            .background(Color.defaultTheme.backgroundMain)
            .toolbarBackground(Color.defaultTheme.backgroundMain, for: .bottomBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Закрыть")
                            .font(.semibold14)
                            .foregroundStyle(Color.defaultTheme.main)
                            .kerning(0.1)
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("Галерея")
                            .font(.semibold16)
                            .foregroundStyle(Color.defaultTheme.textMain)
                    }
                }

                if !viewModel.selectedAssets.isEmpty, viewModel.selection != .single {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("Выбрано: \(viewModel.selectedAssets.count)")
                            .font(.semibold14)
                            .foregroundStyle(Color.defaultTheme.main)
                            .kerning(0.1)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, content: {
                switch viewModel.selection {
                case .multiple:
                    HStack {
                        Spacer()
                        Button(action: {
                            completion?(.assets(viewModel.selectedAssets))
                            dismiss()
                        }) {
                            Text("Загрузить")
                                .font(.semibold14)
                                .foregroundStyle(Color.defaultTheme.backgroundMain)
                                .kerning(0.1)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 18)
                                .background(Color.defaultTheme.main)
                                .clipShape(.capsule)
                        }
                    }
                    .padding(16)
                    .fullWidth()
                    .background(Color.defaultTheme.backgroundMain)
                case .chat:
                    chatBottomView
                case .single:
                    EmptyView()
                }
            })
            .sheet(isPresented: $viewModel.errorLoadFiles) {
                ResultView(
                    icon: .smilebad,
                    title: "Ошибка при отправки сообщения",
                    message: "В процессе отправки сообщения произошла ошибка",
                    dismissButtonText: "Закрыть",
                    dismiss: {
                        viewModel.errorLoadFiles = false
                    }
                )
            }
            .alert("Можно выбрать максимум \(viewModel.selection.maxCount) фотографий", isPresented: $viewModel.isMaxAssetsSelected) {
                Button("Закрыть", role: .cancel) { }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.item, .diskImage],
                allowsMultipleSelection: true
            ) { results in
                switch results {
                case .success(let fileUrls):
                    viewModel.loadFiles(urls: fileUrls)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    // TODO: - Отображение галереи через CollectionView, удалить, если не будет проблем с LazyVGrid
//    private func thumbnailGridView(cameraPlaceholderNeeded: Bool) -> some View {
//        PhotoLibraryCollectionView(
//            selectedAssets: $viewModel.selectedAssets,
//            cameraPlaceholderNeeded: cameraPlaceholderNeeded,
//            firstBlockAssets: viewModel.firstBlockAssets,
//            secondBlockAssets: viewModel.secondBlockAssets,
//            cameraManager: viewModel.cameraManager,
//            photoLibraryManager: viewModel.photoLibraryManager,
//            onCameraPlaceholderTapped: { viewModel.alertCameraOpenSettingsShown = true },
//            onCameraTapped: { cameraShown = true }
//        )
//    }

    private var chatBottomView: some View {
        VStack {
            if viewModel.selectedAssets.isEmpty {
                HStack {
                    Spacer()
                    Button(action: {

                    }) {
                        VStack(spacing: 0) {
                            Image(.gallery)
                            Text("Фото/Видео")
                                .font(.medium10)
                                .foregroundStyle(Color.defaultTheme.main)
                        }
                    }

                    Spacer()

                    Button(action: {
                        showFileImporter = true
                    }) {
                        VStack(spacing: 0) {
                            Image(.file)
                            Text("Файл")
                                .font(.medium10)
                                .foregroundStyle(Color.defaultTheme.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            } else {
                MediaDescriptionInputView(
                    isLoading: viewModel.isLoading,
                    sendTapped: { messageText in
                        viewModel.sendAssets(viewModel.selectedAssets) { urls in
                            completion?(.message(fileUrls: urls, text: messageText))
                            dismiss()
                        }
                    }
                )
            }
        }
        .fullWidth()
        .background(Color.defaultTheme.backgroundMain)
        .animation(.default, value: viewModel.selectedAssets)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

//#if DEBUG
//struct FileAttachmentView_Previews: PreviewProvider {
//    static var previews: some View {
//        FileAttachmentView(viewModel: FileAttachmentViewModel())
//    }
//}
//#endif


