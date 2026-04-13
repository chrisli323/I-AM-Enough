//
//  SplashView.swift
//  I AM Sober
//
//  Full-bleed animated splash with a pronounced breathing animation:
//  all text elements pulse in scale, opacity, and a warm golden shadow.
//  Holds for ~2.5s, then dissolves into the main content.
//

import SwiftUI

struct SplashView: View {
    @State private var breathing = false
    @State private var finished = false

    /// Called when the splash is done and the main app should appear.
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            Theme.parchmentBackground

            VStack(spacing: 22) {
                // Fleuron
                Text("\u{2766}")
                    .font(.system(size: 30, design: .serif))
                    .foregroundStyle(Theme.accentGold)
                    .scaleEffect(breathing ? 1.19 : 0.83)
                    .opacity(breathing ? 1.0 : 0.49)
                    .shadow(
                        color: Theme.accentGold.opacity(breathing ? 0.51 : 0.0),
                        radius: breathing ? 10 : 0
                    )

                // Title
                Text("I AM SOBER")
                    .font(Theme.display(38))
                    .tracking(6)
                    .foregroundStyle(Theme.ink)
                    .scaleEffect(breathing ? 1.085 : 0.915)
                    .opacity(breathing ? 1.0 : 0.66)
                    .shadow(
                        color: Theme.accentGold.opacity(breathing ? 0.38 : 0.0),
                        radius: breathing ? 15 : 0
                    )

                // Tagline
                Text("one day at a time")
                    .font(Theme.bodyItalic(17))
                    .foregroundStyle(Theme.inkSecondary)
                    .scaleEffect(breathing ? 1.07 : 0.93)
                    .opacity(breathing ? 1.0 : 0.49)
                    .shadow(
                        color: Theme.accentGold.opacity(breathing ? 0.30 : 0.0),
                        radius: breathing ? 8.5 : 0
                    )
            }
        }
        .opacity(finished ? 0 : 1)
        .task {
            withAnimation(
                .easeInOut(duration: 1.6)
                .repeatForever(autoreverses: true)
            ) {
                breathing = true
            }

            try? await Task.sleep(for: .seconds(2.5))

            withAnimation(.easeIn(duration: 0.5)) {
                finished = true
            }

            try? await Task.sleep(for: .seconds(0.5))
            onFinished()
        }
    }
}
