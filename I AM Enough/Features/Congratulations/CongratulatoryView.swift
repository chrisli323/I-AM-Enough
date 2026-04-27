//
//  CongratulatoryView.swift
//  I AM Sober
//
//  Shown when the user's Set an Intention challenge has fully elapsed.
//  Appears automatically on next app open if the notification was missed,
//  or immediately when the app is opened via the completion notification.
//  Dismissing clears the completed intention and returns to Today.
//

import SwiftUI

struct CongratulatoryView: View {
    let challengeDays: Int
    let challengeName: String
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {

            Theme.parchmentBackground

            ScrollView {
                VStack(alignment: .center, spacing: 0) {

                    // ── Top ornament ──────────────────────────────────────
                    VStack(spacing: 10) {
                        Text("\u{2766}")
                            .font(.system(size: 28, design: .serif))
                            .foregroundStyle(Theme.accentGold)

                        Text("CHALLENGE COMPLETE")
                            .font(Theme.smallCaps(11))
                            .tracking(4)
                            .foregroundStyle(Theme.inkFaded)
                    }
                    .padding(.top, 44)
                    .padding(.bottom, 24)

                    // ── Challenge badge ───────────────────────────────────
                    Text("\(challengeDays)-Day Challenge")
                        .font(Theme.smallCaps(13))
                        .tracking(2)
                        .foregroundStyle(Theme.parchmentLight)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.ink, in: Capsule())
                        .overlay(Capsule().strokeBorder(Theme.accentGold.opacity(0.45), lineWidth: 0.8))
                        .padding(.bottom, 28)

                    // ── Hero line ─────────────────────────────────────────
                    VStack(spacing: 10) {
                        Text("You did it!")
                            .font(Theme.bodyItalic(32))
                            .foregroundStyle(Theme.ink)

                        if !challengeName.isEmpty {
                            Text("\(challengeDays) days · \(challengeName.capitalized)")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundStyle(Theme.inkSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 32)

                    // ── Body ─────────────────────────────────────────────
                    Text("You set a goal and you kept your word.\nThat's not nothing — that's everything.")
                        .font(Theme.body(17))
                        .lineSpacing(Theme.bodyLineSpacing)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 28)

                    divider

                    Text("Day after day, you showed up. You chose to return even when it was hard. You proved something to yourself that no one can take away — that you are capable, that you follow through, and that the person you are becoming is someone worth betting on.")
                        .font(Theme.body(17))
                        .lineSpacing(Theme.bodyLineSpacing)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 28)

                    divider

                    Text("What comes next is up to you.\nSet a new challenge. Rest in this one.\nOr simply keep showing up — one day at a time.")
                        .font(Theme.body(17))
                        .lineSpacing(Theme.bodyLineSpacing)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 32)

                    // ── Closing affirmation ───────────────────────────────
                    VStack(spacing: 8) {
                        Text("Be proud of yourself.")
                            .font(Theme.bodyItalic(18))
                            .foregroundStyle(Theme.inkSecondary)
                        Text("We are proud of you.")
                            .font(Theme.bodyItalic(18))
                            .foregroundStyle(Theme.inkFaded)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 36)

                    Text("\u{2767}")
                        .font(.system(size: 18, design: .serif))
                        .foregroundStyle(Theme.accentGold.opacity(0.7))
                        .padding(.bottom, 120)
                }
                .padding(.horizontal, Theme.pageHorizontalPadding)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            // ── Pinned dismiss button ─────────────────────────────────────
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.clear, Theme.parchmentDark.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 52)
                .allowsHitTesting(false)

                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 10) {
                        Text("Back to Today")
                            .font(Theme.smallCaps(13))
                            .tracking(2.2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.parchmentLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Theme.ink, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Theme.accentGold.opacity(0.35), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.pageHorizontalPadding)
                .padding(.bottom, 40)
                .background(Theme.parchmentDark.opacity(0.96))
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Subviews

    private var divider: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(Theme.accentGold.opacity(0.50))
                .frame(height: 0.6)
            Text("\u{2766}")
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Theme.accentGold)
            Rectangle()
                .fill(Theme.accentGold.opacity(0.50))
                .frame(height: 0.6)
        }
        .padding(.vertical, 4)
        .padding(.bottom, 28)
    }
}
