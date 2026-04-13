//
//  IntentionSetupSheet.swift
//  I AM Sober
//
//  Sheet for setting a personal challenge/intention goal.
//  Presented from the "Set an Intention" row in Settings.
//

import SwiftUI

struct IntentionSetupSheet: View {
    @Binding var selectedDays: Int?
    var onBegin: () -> Void

    private let gridChallenges: [(label: String, days: Int)] = [
        ("1 Min ⚡",  -1),  // ⚠️ TODO: REMOVE BEFORE RELEASE — test only
        ("1 Yr ⚡",   -2),  // ⚠️ TODO: REMOVE BEFORE RELEASE — test only
        ("1 Day",    1),
        ("1 Week",   7),
        ("2 Weeks",  14),
        ("3 Weeks",  21),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.parchmentBackground

            ScrollView {
                VStack(alignment: .center, spacing: 0) {

                    // ── Ornament + header ─────────────────────────────────
                    VStack(spacing: 10) {
                        Text("\u{2766}")
                            .font(.system(size: 24, design: .serif))
                            .foregroundStyle(Theme.accentGold)

                        Text("SET AN INTENTION")
                            .font(Theme.smallCaps(10))
                            .tracking(3.5)
                            .foregroundStyle(Theme.inkFaded)
                    }
                    .padding(.top, 36)
                    .padding(.bottom, 20)

                    // ── Title ─────────────────────────────────────────────
                    Text("Set an Intention")
                        .font(Theme.display(26))
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 16)

                    // ── Subtext ───────────────────────────────────────────
                    Text("Set a small or big challenge for yourself! Only set a goal that you personally feel is reasonable and that you can achieve — and we will be here rooting for you all the way!")
                        .font(Theme.bodyItalic(16))
                        .lineSpacing(Theme.bodyLineSpacing)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 32)

                    // ── 3-column grid (first 6 challenges) ───────────────
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(gridChallenges, id: \.days) { challenge in
                            challengeBubble(label: challenge.label, days: challenge.days)
                        }
                    }
                    .padding(.bottom, 12)

                    // ── Full-width 90-day row ─────────────────────────────
                    challengeBubble(label: "90 Days", days: 90)
                        .padding(.bottom, 100) // room for pinned button
                }
                .padding(.horizontal, Theme.pageHorizontalPadding)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            // ── Pinned Begin button ───────────────────────────────────────
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.clear, Theme.parchmentDark.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 48)
                .allowsHitTesting(false)

                Button {
                    onBegin()
                } label: {
                    Text("Begin Challenge")
                        .font(Theme.smallCaps(13))
                        .tracking(2.2)
                        .foregroundStyle(Theme.parchmentLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            selectedDays != nil ? Theme.ink : Theme.ink.opacity(0.35),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedDays != nil
                                        ? Theme.accentGold.opacity(0.40)
                                        : Color.clear,
                                    lineWidth: 0.8
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedDays == nil)
                .padding(.horizontal, Theme.pageHorizontalPadding)
                .padding(.bottom, 40)
                .background(Theme.parchmentDark.opacity(0.96))
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Challenge Bubble

    private func challengeBubble(label: String, days: Int) -> some View {
        let isSelected = selectedDays == days

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedDays = days
            }
        } label: {
            Text(label)
                .font(Theme.smallCaps(13))
                .tracking(1.4)
                .foregroundStyle(isSelected ? Theme.parchmentLight : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isSelected ? Theme.ink : Theme.parchmentDark.opacity(0.35),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected
                                ? Theme.accentGold.opacity(0.55)
                                : Theme.accentGold.opacity(0.30),
                            lineWidth: isSelected ? 1.0 : 0.6
                        )
                )
                .scaleEffect(isSelected ? 1.07 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
