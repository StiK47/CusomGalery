//
//  MediaDescriptionInputView.swift
//  SocialFun
//
//  Created by Артем Малюгин on 22.10.2024.
//

import SwiftUI

struct MediaDescriptionInputView: View {

    var isLoading: Bool
    var sendTapped: (String) -> Void

    @State private var messageText: String = ""

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Добавить сообщение...", text: $messageText, axis: .vertical)
                .font(.regular14)
                .foregroundStyle(Color.defaultTheme.textMain)
                .lineLimit(1...6)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.defaultTheme.backgroundSecondary)
                .clipShape(.rect(cornerRadius: 16))
                .disabled(isLoading)

            Button(action: { sendTapped(messageText) }) {
                Text("Отправить")
                    .font(.semibold14)
                    .foregroundStyle(isLoading ? Color.defaultTheme.main : Color.defaultTheme.backgroundMain)
                    .kerning(0.1)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 18)
                    .background(Color.defaultTheme.main)
                    .clipShape(.capsule)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(Color.defaultTheme.backgroundMain)
                }
            }
            .disabled(isLoading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}
