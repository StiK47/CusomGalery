//
//  AddedAsset.swift
//  SocialFun
//
//  Created by Артем Малюгин on 06.05.2024.
//

import SwiftUI

enum AssetType {
    case image
    case video
}

struct AddedAsset: Identifiable {
    let id: String
    let image: UIImage
    let url: URL?
    let type: AssetType
}

extension AddedAsset: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
