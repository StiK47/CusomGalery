//
//  PhotoThumbnailView.swift
//  SocialFun
//
//  Created by Артем Малюгин on 05.10.2023.
//

import Combine
import Photos
import SwiftUI

struct PhotoThumbnailView: View {

    @StateObject var loader = PhotoAssetLoader()
    
    let asset: PHAsset
    let isSelected: Bool?
    let onImageTap: (AddedAsset) -> Void

    var body: some View {
        GeometryReader { proxy in
            switch loader.phase {
            case let .success(image):
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.width)
                        .clipped()

                    if let isSelected {
                        Image(isSelected ? .checkBoxActive : .checkBoxInactive)
                            .padding(10)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onImageTap(
                        AddedAsset(
                            id: asset.localIdentifier,
                            image: image,
                            url: nil,
                            type: .image
                        )
                    )
                }
            case .failure:
                Image(.placeholderFun)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.width)
                    .clipped()
            case .empty:
                Rectangle()
                    .frame(width: proxy.size.width, height: proxy.size.width)
                    .shimmer()
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .onAppear { loader.load(source: asset) }
        .onDisappear { loader.cancel() }
    }
}
