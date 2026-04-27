//
//  BadgeView.swift
//  I AM Sober
//
//  Individual achievement badge rendered in the My Achievements grid.
//  Platinum challenges get a fully animated glowing version;
//  all other tiers use the static gradient ring.
//

import SwiftUI

struct BadgeView: View {
    let challenge: CompletedChallenge

    // Platinum animation state
    @State private var animRotate  = false
    @State private var animGlow    = false
    @State private var animShimmer: Double = -45

    private var tier: BadgeTier { challenge.tier }

    var body: some View {
        if tier == .platinum {
            platinumBadge
        } else {
            regularBadge
        }
    }

    // MARK: - Regular Badge

    private var regularBadge: some View {
        VStack(spacing: 6) {

            ZStack {
                // Outer gradient ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tier.highlightColor, tier.primaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: tier.shadowColor, radius: 5, x: 0, y: 3)

                // Thin inner stroke for depth
                Circle()
                    .strokeBorder(tier.highlightColor.opacity(0.6), lineWidth: 1)
                    .frame(width: 64, height: 64)

                // Parchment inset
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.parchmentLight, Theme.parchmentDark.opacity(0.85)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 46, height: 46)

                // Days count
                VStack(spacing: -1) {
                    Text("\(challenge.days)")
                        .font(Theme.display(17))
                        .foregroundStyle(tier.primaryColor)
                    Text(challenge.days == 1 ? "DAY" : "DAYS")
                        .font(Theme.smallCaps(6))
                        .tracking(1.2)
                        .foregroundStyle(tier.primaryColor.opacity(0.75))
                }
            }

            Text(challenge.label)
                .font(Theme.smallCaps(9))
                .tracking(1)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            Text(challenge.completedAt, format: .dateTime.month(.abbreviated).year())
                .font(Theme.smallCaps(8))
                .tracking(0.6)
                .foregroundStyle(Theme.inkFaded)

            if !challenge.goalName.isEmpty {
                Text(challenge.goalName.capitalized)
                    .font(Theme.bodyItalic(9))
                    .foregroundStyle(Theme.inkFaded.opacity(0.75))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Platinum Badge (animated)

    private var platinumBadge: some View {
        VStack(spacing: 6) {

            ZStack {
                // Pulsing glow halo
                Circle()
                    .fill(tier.glowColor.opacity(0.20))
                    .frame(width: 84, height: 84)
                    .blur(radius: 12)
                    .scaleEffect(animGlow ? 1.20 : 0.88)

                Circle()
                    .fill(tier.glowColor.opacity(0.30))
                    .frame(width: 68, height: 68)
                    .blur(radius: 6)
                    .scaleEffect(animGlow ? 1.10 : 0.94)

                // Rotating diamond orbit ring
                ZStack {
                    ForEach(0..<8, id: \.self) { i in
                        let angle = Double(i) / 8.0 * 2.0 * .pi
                        Text("◆")
                            .font(.system(size: i.isMultiple(of: 2) ? 5.5 : 3.5))
                            .foregroundStyle(
                                i.isMultiple(of: 2)
                                    ? Color.white.opacity(0.90)
                                    : tier.highlightColor.opacity(0.65)
                            )
                            .shadow(color: tier.glowColor, radius: 2)
                            .offset(
                                x: cos(angle) * 35,
                                y: sin(angle) * 35
                            )
                    }
                }
                .rotationEffect(.degrees(animRotate ? 360 : 0))

                // Main platinum circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tier.highlightColor, tier.primaryColor,
                                     Color(red: 0.50, green: 0.56, blue: 0.80)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: tier.glowColor.opacity(0.50), radius: 6, x: 0, y: 2)

                // Sweeping shimmer gleam
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.26), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(animShimmer))

                // Fine stroke rim
                Circle()
                    .strokeBorder(tier.highlightColor.opacity(0.80), lineWidth: 1)
                    .frame(width: 64, height: 64)

                // Parchment inset
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.parchmentLight, Theme.parchmentDark.opacity(0.85)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 46, height: 46)

                // Trophy icon
                VStack(spacing: -2) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [tier.highlightColor, tier.primaryColor],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: tier.glowColor.opacity(0.6), radius: 3)
                    Text("1 YR")
                        .font(Theme.smallCaps(6))
                        .tracking(1.2)
                        .foregroundStyle(tier.primaryColor.opacity(0.88))
                }
            }

            Text(challenge.label)
                .font(Theme.smallCaps(9))
                .tracking(1)
                .foregroundStyle(tier.primaryColor)
                .lineLimit(1)

            Text(challenge.completedAt, format: .dateTime.month(.abbreviated).year())
                .font(Theme.smallCaps(8))
                .tracking(0.6)
                .foregroundStyle(Theme.inkFaded)

            if !challenge.goalName.isEmpty {
                Text(challenge.goalName.capitalized)
                    .font(Theme.bodyItalic(9))
                    .foregroundStyle(Theme.inkFaded.opacity(0.75))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                animRotate = true
            }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                animGlow = true
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                animShimmer = 55
            }
        }
    }
}
