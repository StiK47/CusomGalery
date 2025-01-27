//
//  GridPlaceholderView.swift
//  SocialFun
//
//  Created by Артем Малюгин on 11.10.2023.
//

import SwiftUI

struct GridPlaceholderView: View {

    let icon: ImageResource
    let title: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(icon)
                .padding(10)
                .background(Color.defaultTheme.secondaryLight)
                .clipShape(Circle())
            Text(title)
                .font(.semibold14)
                .foregroundColor(Color.defaultTheme.main)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .fullFrame()
        .background(Color.defaultTheme.backgroundSecondary)
        .clipped()
    }
}

#if DEBUG
struct GridPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        GridPlaceholderView(icon: .cameraPlaceholder, title: "Доступ к камере")
    }
}
#endif
