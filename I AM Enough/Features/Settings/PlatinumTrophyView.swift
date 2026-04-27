//
//  PlatinumTrophyView.swift
//  I AM Sober
//
//  Large animated platinum trophy shown as a featured hero in the
//  Achievements page when a 365-day challenge has been completed.
//  Three pulsing glow rings, a rotating diamond orbit, sweeping shimmer,
//  and a glowing trophy icon inside a deep parchment inset.
//

import SwiftUI

struct PlatinumTrophyView: View {
    let challenge: CompletedChallenge

    @State private var animRotate  = false
    @State private var animGlow    = false
    @State private var animShimmer: Double = -55

    private let orbitRadius: CGFloat = 76
    private let diamondCount         = 10

    var body: some View {
        VStack(spacing: 14) {

            ZStack {

                // ── Outer glow layers (3 rings, pulsing) ──────────────────

                Circle()
                    .fill(glow.opacity(0.10))
                    .frame(width: 210, height: 210)
                    .blur(radius: 22)
                    .scaleEffect(animGlow ? 1.14 : 0.90)

                Circle()
                    .fill(glow.opacity(0.20))
                    .frame(width: 170, height: 170)
                    .blur(radius: 12)
                    .scaleEffect(animGlow ? 1.08 : 0.95)

                Circle()
                    .fill(glow.opacity(0.32))
                    .frame(width: 140, height: 140)
                    .blur(radius: 5)
                    .scaleEffect(animGlow ? 1.04 : 0.98)

                // ── Rotating diamond orbit ring ────────────────────────────

                ZStack {
                    ForEach(0..<diamondCount, id: \.self) { i in
                        let angle = Double(i) / Double(diamondCount) * 2.0 * .pi
                        Text("◆")
                            .font(.system(size: i.isMultiple(of: 2) ? 9 : 5.5))
                            .foregroundStyle(
                                i.isMultiple(of: 2)
                                    ? Color.white.opacity(0.92)
                                    : highlight.opacity(0.68)
                            )
                            .shadow(color: glow, radius: 5, x: 0, y: 0)
                            .offset(
                                x: cos(angle) * orbitRadius,
                                y: sin(angle) * orbitRadius
                            )
                    }
                }
                .rotationEffect(.degrees(animRotate ? 360 : 0))

                // ── Main platinum circle ───────────────────────────────────

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [highlight, primary, deep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 118, height: 118)
                    .shadow(color: glow.opacity(0.55), radius: 16, x: 0, y: 6)

                // ── Sweeping shimmer gleam ─────────────────────────────────

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.28), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(animShimmer))

                // ── Fine stroke rim ────────────────────────────────────────

                Circle()
                    .strokeBorder(highlight.opacity(0.85), lineWidth: 1.5)
                    .frame(width: 118, height: 118)

                // ── Parchment inset ────────────────────────────────────────

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.parchmentLight, Theme.parchmentDark.opacity(0.90)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 38
                        )
                    )
                    .frame(width: 82, height: 82)

                // ── Trophy + "1 YEAR" label ────────────────────────────────

                VStack(spacing: 0) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [highlight, primary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: glow.opacity(0.65), radius: 5, x: 0, y: 1)
                    Text("1 YEAR")
                        .font(Theme.smallCaps(8))
                        .tracking(1.8)
                        .foregroundStyle(primary.opacity(0.90))
                }
            }
            .frame(width: 180, height: 180)

            // ── Labels below the badge ─────────────────────────────────────

            Text("Platinum")
                .font(Theme.display(22))
                .foregroundStyle(primary)
                .shadow(color: glow.opacity(0.40), radius: 5, x: 0, y: 1)

            Text("365-Day Challenge")
                .font(Theme.smallCaps(11))
                .tracking(1.4)
                .foregroundStyle(Theme.inkFaded)

            if !challenge.goalName.isEmpty {
                Text(challenge.goalName.capitalized)
                    .font(Theme.bodyItalic(14))
                    .foregroundStyle(primary.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            Text(challenge.completedAt, format: .dateTime.month(.wide).day().year())
                .font(Theme.bodyItalic(13))
                .foregroundStyle(Theme.inkFaded.opacity(0.7))
        }
        .onAppear {
            withAnimation(.linear(duration: 13).repeatForever(autoreverses: false)) {
                animRotate = true
            }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                animGlow = true
            }
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                animShimmer = 55
            }
        }
    }

    // MARK: - Platinum colour palette

    private var primary:   Color { Color(red: 0.68, green: 0.73, blue: 0.90) }
    private var highlight: Color { Color(red: 0.96, green: 0.97, blue: 1.00) }
    private var deep:      Color { Color(red: 0.48, green: 0.54, blue: 0.78) }
    private var glow:      Color { Color(red: 0.42, green: 0.56, blue: 0.98) }
}

#Preview {
    ZStack {
        Theme.parchmentBackground
        PlatinumTrophyView(
            challenge: CompletedChallenge(days: 365, completedAt: Date())
        )
    }
    .preferredColorScheme(.light)
}
