//
//  PaywallView.swift
//  I AM Enough
//
//  Two modes:
//  • isEarlyUpgrade = false (default) — shown when the 7-day trial has ended.
//    Header celebrates how far they've come before presenting the unlock.
//  • isEarlyUpgrade = true — shown when the user taps "Unlock forever →"
//    during their trial. No "journey complete" framing — just a clean
//    upgrade page that feels like an opportunity, not an ending.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppState.self) private var appState

    /// true  → early upgrade (tapped link during trial)
    /// false → trial expired gate (default)
    var isEarlyUpgrade: Bool = false

    /// Called when the user taps X or "Maybe later."
    var onDismiss: () -> Void = {}

    @State private var isPurchasing = false
    @State private var isRestoring  = false
    @State private var errorMessage: String?

    private var priceString: String {
        appState.purchaseManager.product?.displayPrice ?? "$4.99"
    }

    var body: some View {
        ZStack {
            Theme.parchmentBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: 0) {

                    // ── Dismiss button ────────────────────────────────────
                    HStack {
                        Spacer()
                        Button { onDismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.inkFaded)
                                .frame(width: 32, height: 32)
                                .background(Theme.parchmentDark.opacity(0.7), in: Circle())
                                .overlay(Circle().strokeBorder(Theme.accentGold.opacity(0.30), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 4)

                    // ── Header — changes based on mode ────────────────────
                    if isEarlyUpgrade {
                        earlyUpgradeHeader
                    } else {
                        trialEndedHeader
                    }

                    ornamentDivider

                    // ── Value props (same in both modes) ──────────────────
                    VStack(alignment: .leading, spacing: 22) {
                        valueProp(
                            icon: "sun.max",
                            title: "365 Daily Teachings",
                            body: "A full year of unique reflections — one every morning, no repeats."
                        )
                        valueProp(
                            icon: "book",
                            title: "Journal & Favorites",
                            body: "Everything you've written stays yours. Nothing is ever taken away."
                        )
                        valueProp(
                            icon: "medal",
                            title: "Badges & Milestones",
                            body: "Keep earning. Bronze, Silver, Gold, and the rare Platinum at one year."
                        )
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 36)
                    .padding(.top, 4)

                    ornamentDivider

                    // ── Price label ───────────────────────────────────────
                    Text("\(priceString) · One-Time · Yours Forever")
                        .font(Theme.smallCaps(11))
                        .tracking(1.4)
                        .foregroundStyle(Theme.inkFaded)
                        .padding(.top, 4)
                        .padding(.bottom, 24)

                    // ── Buy button ────────────────────────────────────────
                    Button {
                        Task { await purchase() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(Theme.parchmentLight)
                            } else {
                                HStack(spacing: 8) {
                                    Text(isEarlyUpgrade ? "Unlock Forever" : "Continue My Journey")
                                        .font(Theme.smallCaps(13))
                                        .tracking(2.2)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                        }
                        .foregroundStyle(Theme.parchmentLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Theme.ink, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Theme.accentGold.opacity(0.40), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing || isRestoring)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    // ── Restore button ────────────────────────────────────
                    Button {
                        Task { await restore() }
                    } label: {
                        if isRestoring {
                            ProgressView()
                                .tint(Theme.inkFaded)
                                .scaleEffect(0.8)
                                .frame(height: 20)
                        } else {
                            Text("Restore Previous Purchase")
                                .font(Theme.body(14))
                                .foregroundStyle(Theme.inkFaded)
                                .underline()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing || isRestoring)
                    .padding(.bottom, 16)

                    // ── Error message ─────────────────────────────────────
                    if let error = errorMessage {
                        Text(error)
                            .font(Theme.bodyItalic(13))
                            .foregroundStyle(.red.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 12)
                    }

                    // ── Maybe later ───────────────────────────────────────
                    Button { onDismiss() } label: {
                        Text("Maybe later")
                            .font(Theme.bodyItalic(13))
                            .foregroundStyle(Theme.inkFaded.opacity(0.55))
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 16)

                    // ── Fine print ────────────────────────────────────────
                    VStack(spacing: 5) {
                        Text("No subscription. Pay once, unlock forever.")
                            .font(Theme.bodyItalic(12))
                            .foregroundStyle(Theme.inkFaded.opacity(0.55))

                        Text("Your journal, badges, and first 7 days\nremain accessible regardless of purchase.")
                            .font(Theme.bodyItalic(12))
                            .foregroundStyle(Theme.inkFaded.opacity(0.45))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 56)
                }
                .padding(.horizontal, Theme.pageHorizontalPadding)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Headers

    /// Shown when the user taps "Unlock forever →" during their free trial.
    private var earlyUpgradeHeader: some View {
        VStack(spacing: 10) {
            Text("\u{2766}")
                .font(.system(size: 26, design: .serif))
                .foregroundStyle(Theme.accentGold)

            Text("UNLOCK YOUR FULL JOURNEY")
                .font(Theme.smallCaps(10))
                .tracking(2.8)
                .foregroundStyle(Theme.inkFaded)

            Text("Every teaching. Every milestone.\nEvery day for a full year.")
                .font(Theme.bodyItalic(18))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
        .padding(.top, 52)
        .padding(.bottom, 36)
    }

    /// Shown when the 7-day trial has ended and the user hasn't purchased yet.
    private var trialEndedHeader: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text("\u{2766}")
                    .font(.system(size: 26, design: .serif))
                    .foregroundStyle(Theme.accentGold)

                Text("YOUR FREE JOURNEY IS COMPLETE")
                    .font(Theme.smallCaps(10))
                    .tracking(2.8)
                    .foregroundStyle(Theme.inkFaded)
            }
            .padding(.top, 52)
            .padding(.bottom, 28)

            VStack(spacing: 8) {
                Text("Day \(appState.scheduler.personalDayNumber())")
                    .font(Theme.display(52))
                    .foregroundStyle(Theme.ink)

                Text("You showed up. Every single day.")
                    .font(Theme.bodyItalic(17))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 36)
        }
    }

    // MARK: - Actions

    private func purchase() async {
        isPurchasing = true
        errorMessage = nil
        do {
            try await appState.purchaseManager.purchase()
        } catch {
            errorMessage = "Purchase could not be completed. Please try again."
        }
        isPurchasing = false
    }

    private func restore() async {
        isRestoring = true
        errorMessage = nil
        await appState.purchaseManager.restorePurchases()
        isRestoring = false
        if !appState.purchaseManager.isUnlocked {
            errorMessage = "No previous purchase found for this Apple ID."
        }
    }

    // MARK: - Subviews

    private var ornamentDivider: some View {
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

    private func valueProp(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.accentGold)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.bodyItalic(14))
                    .foregroundStyle(Theme.inkFaded)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
