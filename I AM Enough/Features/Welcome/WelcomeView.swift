//
//  WelcomeView.swift
//  I AM Sober
//
//  First-launch welcome letter. Presented as a large sheet so ~95% of the
//  screen is covered and the user glimpses the Today page peeking behind.
//  The sheet cannot be swiped away — the user must tap "Begin My Journey."
//

import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    /// Pass `true` when opened from Settings so the button reads "Close"
    /// instead of "Begin My Journey."
    var isRevisit: Bool = false
    var onBegin: () -> Void

    @State private var showingPaywallSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {

            // Full parchment background
            Theme.parchmentBackground

            // Scrollable letter content
            ScrollView {
                VStack(alignment: .center, spacing: 0) {

                    // ── Dismiss "×" button ────────────────────────────────
                    HStack {
                        Spacer()
                        Button {
                            onBegin()
                        } label: {
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

                    // ── Top ornament ──────────────────────────────────────
                    VStack(spacing: 10) {
                        Text("\u{2766}")
                            .font(.system(size: 28, design: .serif))
                            .foregroundStyle(Theme.accentGold)

                        Text("WELCOME")
                            .font(Theme.smallCaps(11))
                            .tracking(4.5)
                            .foregroundStyle(Theme.inkFaded)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                    // ── Hero line ─────────────────────────────────────────
                    Text("You took\nthe first step.")
                        .font(Theme.bodyItalic(30))
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 32)

                    // ── Opening ───────────────────────────────────────────
                    Text("That takes more courage than most people will ever understand. Whether this is Day 1 or you're returning after a hard stretch — you chose to be here today, and that matters more than you know.")
                        .font(Theme.body(17))
                        .lineSpacing(Theme.bodyLineSpacing)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 36)

                    divider

                    // ── Section 1 ─────────────────────────────────────────
                    sectionBlock(
                        title: "YOUR DAILY TEACHING",
                        body: "Each morning, a new teaching waits for you on this page. One reflection. One truth to carry through your day.\n\nShort enough to sit with over your first cup of coffee — deep enough to return to when things get hard. The teachings build quietly, one upon the other, like pages of a book written just for you."
                    )

                    divider

                    // ── Section 2 ─────────────────────────────────────────
                    sectionBlock(
                        title: "THE PRACTICE",
                        body: "Lasting change doesn't come from a single breakthrough moment. It comes from the small, steady act of returning — every day — to something true.\n\nWhen a teaching moves you, write it out in the journal. When one speaks directly to your heart, save it to Favorites. Over time, these small choices compound into something real."
                    )

                    divider

                    // ── Closing affirmation ───────────────────────────────
                    VStack(spacing: 10) {
                        Text("You don't have to have it all figured out.")
                            .font(Theme.bodyItalic(18))
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)

                        Text("You just have to keep coming back.")
                            .font(Theme.bodyItalic(18))
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)

                        Text("One day at a time.")
                            .font(Theme.bodyItalic(16))
                            .foregroundStyle(Theme.inkFaded)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 36)

                    // Trial / unlock note — hidden forever after purchase
                    if !appState.purchaseManager.isUnlocked {
                        trialNote
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                    }

                    // Bottom fleuron
                    Text("\u{2767}")
                        .font(.system(size: 18, design: .serif))
                        .foregroundStyle(Theme.accentGold.opacity(0.7))
                        .padding(.bottom, 120) // room for the pinned button
                }
                .padding(.horizontal, Theme.pageHorizontalPadding)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            // ── Pinned "Begin" button ─────────────────────────────────────
            VStack(spacing: 0) {
                // Soft fade so content dissolves into the button area
                LinearGradient(
                    colors: [Color.clear, Theme.parchmentDark.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 52)
                .allowsHitTesting(false)

                Button {
                    onBegin()
                } label: {
                    HStack(spacing: 10) {
                        Text(isRevisit ? "Close" : "Begin My Journey")
                            .font(Theme.smallCaps(13))
                            .tracking(2.2)
                        if !isRevisit {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .medium))
                        }
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

    // MARK: - Trial Note

    @ViewBuilder
    private var trialNote: some View {
        let unlocked  = appState.purchaseManager.isUnlocked
        let active    = appState.preferences.isTrialActive
        let remaining = appState.preferences.trialDaysRemaining

        if !unlocked {
            VStack(spacing: 10) {
                HStack(spacing: 14) {
                    Rectangle().fill(Theme.accentGold.opacity(0.25)).frame(height: 0.5)
                    Image(systemName: "sun.max")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accentGold.opacity(0.6))
                    Rectangle().fill(Theme.accentGold.opacity(0.25)).frame(height: 0.5)
                }

                if !isRevisit {
                    // First open — explain the model simply
                    Text("Your first 7 teachings are free. Unlock all 365 for $4.99 — one time, no subscription.")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else if active {
                    // Revisiting during trial
                    let countText = remaining == 1 ? "1 free teaching remaining." : "\(remaining) free teachings remaining."
                    Text("\(countText) Unlock all 365 for $4.99 — one time, no subscription.")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // Revisiting after trial ended
                    Text("Your free trial has ended. Unlock all 365 teachings for $4.99 — one time, no subscription.")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Unlock link — always shown alongside the trial note.
                if true {
                    Button { showingPaywallSheet = true } label: {
                        Text("Unlock forever →")
                            .font(Theme.bodyItalic(13))
                            .foregroundStyle(Theme.accentGold.opacity(0.85))
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                    .sheet(isPresented: $showingPaywallSheet) {
                        PaywallView(isEarlyUpgrade: true, onDismiss: { showingPaywallSheet = false })
                            .environment(appState)
                            .presentationDetents([.large])
                            .presentationCornerRadius(28)
                            .presentationDragIndicator(.hidden)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
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

    private func sectionBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Theme.smallCaps(10))
                .tracking(2.8)
                .foregroundStyle(Theme.inkFaded)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(body)
                .font(Theme.body(17))
                .lineSpacing(Theme.bodyLineSpacing)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
        .padding(.bottom, 32)
    }
}
