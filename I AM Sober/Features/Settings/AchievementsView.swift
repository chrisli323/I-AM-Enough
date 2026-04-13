//
//  AchievementsView.swift
//  I AM Sober
//
//  Full-screen achievements page. Platinum badges are featured as a glowing
//  hero at the top; all other earned badges sit in a 3-column grid below.
//  A badge guide explains every tier and how it is earned.
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query(sort: \CompletedChallenge.completedAt, order: .reverse) private var completedChallenges: [CompletedChallenge]

    private var platinumBadges: [CompletedChallenge] {
        completedChallenges.filter { $0.tier == .platinum }
    }

    private var regularBadges: [CompletedChallenge] {
        completedChallenges.filter { $0.tier != .platinum }
    }

    var body: some View {
        ZStack {
            Theme.parchmentBackground

            ScrollView {
                VStack(spacing: 32) {

                    // ── Platinum hero section ──────────────────────────────
                    if !platinumBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PLATINUM")
                                .font(Theme.smallCaps(10))
                                .tracking(2.6)
                                .foregroundStyle(Color(red: 0.68, green: 0.73, blue: 0.90))
                                .padding(.leading, 4)
                                .padding(.bottom, 10)

                            VStack(spacing: 28) {
                                ForEach(platinumBadges) { badge in
                                    PlatinumTrophyView(challenge: badge)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 28)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Theme.parchmentLight.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        Color(red: 0.68, green: 0.73, blue: 0.90).opacity(0.40),
                                        lineWidth: 0.8
                                    )
                            )
                            .shadow(
                                color: Color(red: 0.42, green: 0.56, blue: 0.98).opacity(0.12),
                                radius: 18, x: 0, y: 4
                            )
                        }
                    }

                    // ── Regular earned badges grid ─────────────────────────
                    if completedChallenges.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "medal")
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.inkFaded.opacity(0.3))
                            Text("No badges yet")
                                .font(Theme.display(20))
                                .foregroundStyle(Theme.inkFaded)
                            Text("Complete your first challenge to earn a badge.")
                                .font(Theme.bodyItalic(15))
                                .foregroundStyle(Theme.inkFaded.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else if !regularBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("EARNED")
                                .font(Theme.smallCaps(10))
                                .tracking(2.6)
                                .foregroundStyle(Theme.inkFaded)
                                .padding(.leading, 4)
                                .padding(.bottom, 10)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 24
                            ) {
                                ForEach(regularBadges) { challenge in
                                    BadgeView(challenge: challenge)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Theme.parchmentLight.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.accentGold.opacity(0.25), lineWidth: 0.6)
                            )
                        }
                    }

                    // ── Badge guide ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        Text("BADGE GUIDE")
                            .font(Theme.smallCaps(10))
                            .tracking(2.6)
                            .foregroundStyle(Theme.inkFaded)
                            .padding(.leading, 4)
                            .padding(.bottom, 10)

                        VStack(spacing: 0) {
                            tierRow(tier: .bronze,
                                    range: "1 – 13 days",
                                    description: "Every journey starts with a single day. Bronze honours the courage of beginnings.")
                            guideDivider
                            tierRow(tier: .silver,
                                    range: "14 – 59 days",
                                    description: "Two weeks to two months of commitment. Silver recognises real momentum and discipline.")
                            guideDivider
                            tierRow(tier: .gold,
                                    range: "60 – 364 days",
                                    description: "Sixty days to nearly a year. Gold is reserved for those who have truly proven themselves.")
                            guideDivider
                            platinumGuideRow
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.parchmentLight.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.accentGold.opacity(0.25), lineWidth: 0.6)
                        )
                    }

                    // ── Footer ornament ────────────────────────────────────
                    Text("❦")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.inkFaded.opacity(0.3))
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
        }
        .toolbarBackground(Theme.parchmentLight, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("My Achievements")
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    // MARK: - Tier Row (Bronze / Silver / Gold)

    private func tierRow(tier: BadgeTier, range: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Mini badge swatch
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tier.highlightColor, tier.primaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: tier.shadowColor, radius: 4, x: 0, y: 2)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.parchmentLight, Theme.parchmentDark.opacity(0.85)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 13
                        )
                    )
                    .frame(width: 30, height: 30)

                Text(tier.name.prefix(1))
                    .font(Theme.display(13))
                    .foregroundStyle(tier.primaryColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(tier.name)
                        .font(Theme.body(15))
                        .foregroundStyle(tier.primaryColor)
                    Text("·")
                        .foregroundStyle(Theme.inkFaded)
                    Text(range)
                        .font(Theme.smallCaps(10))
                        .tracking(0.8)
                        .foregroundStyle(Theme.inkFaded)
                }
                Text(description)
                    .font(Theme.bodyItalic(12))
                    .foregroundStyle(Theme.inkFaded)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Platinum Guide Row (special — static mini trophy)

    private var platinumGuideRow: some View {
        let platPrimary   = Color(red: 0.68, green: 0.73, blue: 0.90)
        let platHighlight = Color(red: 0.96, green: 0.97, blue: 1.00)
        let platDeep      = Color(red: 0.48, green: 0.54, blue: 0.78)
        let platGlow      = Color(red: 0.42, green: 0.56, blue: 0.98)

        return HStack(alignment: .center, spacing: 16) {
            // Mini trophy swatch
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [platHighlight, platPrimary, platDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: platGlow.opacity(0.40), radius: 6, x: 0, y: 2)

                Circle()
                    .strokeBorder(platHighlight.opacity(0.75), lineWidth: 1)
                    .frame(width: 44, height: 44)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.parchmentLight, Theme.parchmentDark.opacity(0.85)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 13
                        )
                    )
                    .frame(width: 30, height: 30)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [platHighlight, platPrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: platGlow.opacity(0.5), radius: 2)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Platinum")
                        .font(Theme.body(15))
                        .foregroundStyle(platPrimary)
                    Text("·")
                        .foregroundStyle(Theme.inkFaded)
                    Text("365 days · 1 Year")
                        .font(Theme.smallCaps(10))
                        .tracking(0.8)
                        .foregroundStyle(Theme.inkFaded)
                }
                Text("A full year of sobriety. Platinum is the rarest badge — a testament to extraordinary strength, dedication, and self-belief.")
                    .font(Theme.bodyItalic(12))
                    .foregroundStyle(Theme.inkFaded)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .padding(.vertical, 12)
    }

    private var guideDivider: some View {
        Rectangle()
            .fill(Theme.accentGold.opacity(0.15))
            .frame(height: 0.5)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(for: CompletedChallenge.self, inMemory: true)
    .preferredColorScheme(.light)
}
