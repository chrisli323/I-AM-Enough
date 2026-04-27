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

            // Serpent ring — sits behind the title, same width as A→E in "I AM SOBER"
            SerpentRingView()
                .frame(width: 230, height: 230)
                .opacity(breathing ? 1.0 : 0.55)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathing)

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
                Text("I AM ENOUGH")
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

// MARK: - Serpent ring

/// A continuously rotating arc that fades from transparent at its tail
/// to solid at its head — a snake-chasing-its-tail loading indicator.
private struct SerpentRingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.78)
            .stroke(
                AngularGradient(
                    stops: [
                        .init(color: .clear,                            location: 0.00),
                        .init(color: Theme.accentGold.opacity(0.15),   location: 0.25),
                        .init(color: Theme.accentGold.opacity(0.48),   location: 0.78),
                        // Hold the head colour to the seam so there is
                        // no bleed across the invisible gap.
                        .init(color: Theme.accentGold.opacity(0.48),   location: 1.00),
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            // Start the arc at 12 o'clock so the head is visually at the top
            // when the animation begins.
            .rotationEffect(.degrees(rotation - 90))
            .onAppear {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
