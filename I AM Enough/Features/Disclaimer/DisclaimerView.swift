//
//  DisclaimerView.swift
//  I AM Enough
//
//  Shown once on first install, after the splash screen and before the
//  welcome letter. The user must explicitly tap "I Agree & Continue" —
//  the sheet cannot be swiped away or dismissed. Once accepted, it never
//  appears again unless the app is deleted and reinstalled.
//

import SwiftUI

struct DisclaimerView: View {
    var onAccept: () -> Void

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

                        Text("BEFORE YOU BEGIN")
                            .font(Theme.smallCaps(11))
                            .tracking(4.5)
                            .foregroundStyle(Theme.inkFaded)
                    }
                    .padding(.top, 48)
                    .padding(.bottom, 28)

                    // ── Hero ──────────────────────────────────────────────
                    Text("A few things\nto know.")
                        .font(Theme.bodyItalic(28))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 36)

                    divider

                    // ── Disclaimer body ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 20) {

                        disclaimerBlock(
                            icon: "heart.text.square",
                            title: "For Inspiration Only",
                            body: "I AM Enough is designed for personal growth and inspirational purposes only. The teachings and content in this app do not constitute professional medical, psychological, or therapeutic advice."
                        )

                        disclaimerBlock(
                            icon: "cross.circle",
                            title: "Not a Medical Tool",
                            body: "This app is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease, mental health condition, or addiction."
                        )

                        disclaimerBlock(
                            icon: "person.fill.checkmark",
                            title: "Your Responsibility",
                            body: "The developers of I AM Enough assume no responsibility or liability for any actions taken, decisions made, or outcomes experienced as a result of using this app. You are solely responsible for your own choices and wellbeing."
                        )

                        disclaimerBlock(
                            icon: "staroflife",
                            title: "Seek Professional Help",
                            body: "If you are struggling with addiction, mental health, or any medical condition, please seek guidance from a qualified healthcare professional."
                        )
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 36)

                    divider

                    // ── Agreement note ────────────────────────────────────
                    Text("By tapping \"I Agree & Continue\" you acknowledge that you have read and understood the above and agree to use this app for personal growth and inspirational purposes only.")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                        .padding(.bottom, 120)
                }
                .padding(.horizontal, Theme.pageHorizontalPadding)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            // ── Pinned agree button ───────────────────────────────────────
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.clear, Theme.parchmentDark.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 52)
                .allowsHitTesting(false)

                Button {
                    onAccept()
                } label: {
                    HStack(spacing: 10) {
                        Text("I Agree & Continue")
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
                .background(Theme.parchmentDark.opacity(0.65))
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

    private func disclaimerBlock(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.accentGold)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.bodyItalic(14))
                    .foregroundStyle(Theme.inkFaded)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
    }
}
