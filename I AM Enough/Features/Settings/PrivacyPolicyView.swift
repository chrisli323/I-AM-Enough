//
//  PrivacyPolicyView.swift
//  I AM Enough
//
//  In-app privacy policy. Pushed via NavigationLink from SettingsView
//  so the user gets the standard back button. The external GitHub page
//  (chrisli323.github.io/I-AM-Enough/privacy.html) remains the
//  canonical public-facing version; this view mirrors its content.
//

import SwiftUI

struct PrivacyPolicyView: View {

    var body: some View {
        ZStack {
            Theme.parchmentBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Top ornament ──────────────────────────────────────
                    VStack(spacing: 10) {
                        Text("\u{2766}")
                            .font(.system(size: 24, design: .serif))
                            .foregroundStyle(Theme.accentGold)

                        Text("PRIVACY POLICY")
                            .font(Theme.smallCaps(10))
                            .tracking(3.5)
                            .foregroundStyle(Theme.inkFaded)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    // ── Last updated ──────────────────────────────────────
                    Text("Last updated: April 28, 2026")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded)
                        .padding(.bottom, 16)

                    // ── Intro ─────────────────────────────────────────────
                    Text("I AM Enough (\"the App\") is a personal growth and daily challenge app built by Chris Lee. Your privacy is important. This policy explains what data the App collects, how it is used, and your rights.")
                        .font(Theme.body(15))
                        .lineSpacing(Theme.bodyLineSpacing)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 24)

                    divider

                    // ── Sections ──────────────────────────────────────────
                    policySection(
                        number: "1",
                        title: "Data We Collect",
                        body: "The App stores all data locally on your device only. We do not operate servers, create user accounts, or transmit any personal information over the internet.",
                        bullets: [
                            ("Challenge & journal data", "Your challenge start date, daily progress, journal entries, and any photos you attach. Stored using Apple's SwiftData framework, on your device only."),
                            ("Photos", "Only accessed when you choose to attach a photo to a journal entry or save a photo to your camera roll. Photos are never uploaded or shared.")
                        ]
                    )

                    divider

                    policySection(
                        number: "2",
                        title: "Camera & Photo Library Access",
                        body: "You can revoke these permissions at any time in your iPhone's Settings app.",
                        bullets: [
                            ("Camera", "Used only when you tap to take a photo for a journal entry. The App will request permission before accessing your camera."),
                            ("Photo Library", "Used only when you choose to save a journal photo to your camera roll. The App will request permission before writing to your library.")
                        ]
                    )

                    divider

                    policySection(
                        number: "3",
                        title: "Data Sharing",
                        body: "We do not sell, share, or transmit your data to any third party. The App contains no advertising, no analytics SDKs, and no third-party tracking of any kind.",
                        bullets: []
                    )

                    divider

                    policySection(
                        number: "4",
                        title: "Data Retention & Deletion",
                        body: "All data lives on your device. To delete all App data, simply delete the App from your iPhone. This permanently removes all challenge progress, journal entries, and associated photos stored by the App.",
                        bullets: []
                    )

                    divider

                    policySection(
                        number: "5",
                        title: "Children's Privacy",
                        body: "The App is rated 4+ and does not knowingly collect data from children. Since no data leaves your device, there is no risk of children's data being shared with third parties.",
                        bullets: []
                    )

                    divider

                    policySection(
                        number: "6",
                        title: "Changes to This Policy",
                        body: "If we make material changes to this privacy policy, we will update the \"Last updated\" date at the top of this page. Continued use of the App after changes constitutes acceptance of the updated policy.",
                        bullets: []
                    )

                    divider

                    policySection(
                        number: "7",
                        title: "Disclaimer",
                        body: "I AM Enough is designed for personal growth and inspirational purposes only. It is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease, mental health condition, or addiction. The teachings and content in this app do not constitute professional medical, psychological, or therapeutic advice. The developers of I AM Enough assume no responsibility or liability for any actions taken, decisions made, or outcomes experienced as a result of using this app. You are solely responsible for your own choices and wellbeing. If you are struggling with addiction, mental health, or any medical condition, please seek guidance from a qualified healthcare professional.",
                        bullets: []
                    )

                    divider

                    // ── Contact ───────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("8. Contact")
                            .font(Theme.body(16))
                            .foregroundStyle(Theme.ink)

                        Text("If you have questions about this privacy policy, please contact:")
                            .font(Theme.body(15))
                            .lineSpacing(Theme.bodyLineSpacing)
                            .foregroundStyle(Theme.ink)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Chris Lee")
                                .font(Theme.body(15))
                                .foregroundStyle(Theme.ink)
                            Text("chrisli323@gmail.com")
                                .font(Theme.body(15))
                                .foregroundStyle(Theme.accentGold)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 32)

                    // ── Footer ────────────────────────────────────────────
                    Text("\u{2767}")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(Theme.accentGold.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)

                    Text("© 2026 Chris Lee. All rights reserved.")
                        .font(Theme.smallCaps(9))
                        .tracking(1)
                        .foregroundStyle(Theme.inkFaded.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, Theme.pageHorizontalPadding)
            }
            .scrollIndicators(.hidden)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Privacy Policy")
                    .font(Theme.display(18))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    // MARK: - Subviews

    private var divider: some View {
        Rectangle()
            .fill(Theme.accentGold.opacity(0.25))
            .frame(height: 0.5)
            .padding(.vertical, 16)
    }

    private func policySection(
        number: String,
        title: String,
        body: String,
        bullets: [(String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(number). \(title)")
                .font(Theme.body(16))
                .foregroundStyle(Theme.ink)

            if !body.isEmpty {
                Text(body)
                    .font(Theme.body(15))
                    .lineSpacing(Theme.bodyLineSpacing)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !bullets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(bullets, id: \.0) { bold, detail in
                        HStack(alignment: .top, spacing: 10) {
                            Text("·")
                                .font(Theme.body(15))
                                .foregroundStyle(Theme.accentGold)
                                .frame(width: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bold)
                                    .font(Theme.body(15))
                                    .foregroundStyle(Theme.ink)
                                Text(detail)
                                    .font(Theme.bodyItalic(14))
                                    .lineSpacing(3)
                                    .foregroundStyle(Theme.inkFaded)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.bottom, 4)
    }
}
