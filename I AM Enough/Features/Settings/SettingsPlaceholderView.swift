//
//  SettingsPlaceholderView.swift
//  I AM Sober
//
//  Placeholder for the Settings tab. The full settings shell ships in
//  Phase 5 — for now this just exists so the tab bar has three real
//  destinations.
//

import SwiftUI

struct SettingsPlaceholderView: View {
    var body: some View {
        ZStack {
            Theme.parchmentBackground

            VStack(spacing: 16) {
                Image(systemName: "gearshape")
                    .font(.system(size: 44, design: .serif))
                    .foregroundStyle(Theme.inkFaded)
                Text("Settings")
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)
                Text("Coming soon — fonts, audio, notifications,\nsobriety tracking, and more.")
                    .font(Theme.bodyItalic(15))
                    .foregroundStyle(Theme.inkFaded)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
    }
}
