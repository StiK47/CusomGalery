//
//  MediaGridView.swift
//  SocialFun
//
//  Created by Артем Малюгин on 09.10.2024.
//

import Photos
import SwiftUI

struct ThumbnailGridView<Content: View>: View {

    var firstBlockAssets: [PHAsset]
    var secondBlockAssets: [PHAsset]
    var imageSelected: (String) -> Bool?
    var imageTapped: (AddedAsset) -> ()
    @ViewBuilder var camera: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    HStack(alignment: .top, spacing: 2) {
                        camera()
                            .frame(width: abs(proxy.size.width - 4) / 3, height: abs(proxy.size.width - 4) * 2/3 + 2)

                        MediaGridView(
                            assets: firstBlockAssets,
                            imageSelected: imageSelected,
                            imageTapped: imageTapped
                        )
                    }

                    MediaGridView(
                        assets: secondBlockAssets,
                        imageSelected: imageSelected,
                        imageTapped: imageTapped
                    )
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct MediaGridView: View {

    var assets: [PHAsset]
    var imageSelected: (String) -> Bool?
    var imageTapped: (AddedAsset) -> ()

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 2)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(assets) { asset in
                PhotoThumbnailView(
                    asset: asset,
                    isSelected: imageSelected(asset.localIdentifier),
                    onImageTap: imageTapped
                )
            }
        }
    }
}
