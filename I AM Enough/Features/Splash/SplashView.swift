//
//  SplashView.swift
//  I AM Enough
//

import SwiftUI

struct SplashView: View {
    @State private var breathing = false
    @State private var finished = false

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            Theme.parchmentBackground

            ZStack {
                // App logo clipped to circle, sits inside the ring
                Image("AppLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 282, height: 282)
                    .clipShape(Circle())

                // Serpent ring on top of the logo edge
                SerpentRingView()
                    .frame(width: 300, height: 300)
            }
            .scaleEffect(breathing ? 1.09 : 0.91)
            .opacity(breathing ? 1.0 : 0.60)
            .shadow(
                color: Theme.accentGold.opacity(breathing ? 0.45 : 0.0),
                radius: breathing ? 20 : 0
            )
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathing)
        }
        .opacity(finished ? 0 : 1)
        .task {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
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

private struct SerpentRingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.78)
            .stroke(
                AngularGradient(
                    stops: [
                        .init(color: .clear,                          location: 0.00),
                        .init(color: Theme.accentGold.opacity(0.15), location: 0.25),
                        .init(color: Theme.accentGold.opacity(0.48), location: 0.78),
                        .init(color: Theme.accentGold.opacity(0.48), location: 1.00),
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            .rotationEffect(.degrees(rotation - 90))
            .onAppear {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
