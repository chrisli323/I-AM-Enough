//
//  LegalDisclaimerView.swift
//  I AM Enough
//
//  In-app disclaimer page. The user accepts this once on first launch via
//  DisclaimerView; this page keeps the same legal language available from
//  Settings without expanding inline inside the Settings list.
//

import SwiftUI

struct LegalDisclaimerView: View {

    var body: some View {
        ZStack {
            Theme.parchmentBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    VStack(spacing: 10) {
                        Text("\u{2766}")
                            .font(.system(size: 24, design: .serif))
                            .foregroundStyle(Theme.accentGold)

                        Text("DISCLAIMER")
                            .font(Theme.smallCaps(10))
                            .tracking(3.5)
                            .foregroundStyle(Theme.inkFaded)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    Text("I AM Enough is designed for personal growth and inspirational purposes only.")
                        .font(Theme.body(16))
                        .lineSpacing(Theme.bodyLineSpacing)
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 24)

                    divider

                    disclaimerSection(
                        icon: "heart.text.square",
                        title: "For Inspiration Only",
                        body: "The teachings and content in this app do not constitute professional medical, psychological, or therapeutic advice."
                    )

                    divider

                    disclaimerSection(
                        icon: "cross.circle",
                        title: "Not a Medical Tool",
                        body: "This app is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease, mental health condition, or addiction."
                    )

                    divider

                    disclaimerSection(
                        icon: "person.fill.checkmark",
                        title: "Your Responsibility",
                        body: "The developers of I AM Enough assume no responsibility or liability for any actions taken, decisions made, or outcomes experienced as a result of using this app. You are solely responsible for your own choices and wellbeing."
                    )

                    divider

                    disclaimerSection(
                        icon: "staroflife",
                        title: "Seek Professional Help",
                        body: "If you are struggling with addiction, mental health, or any medical condition, please seek guidance from a qualified healthcare professional."
                    )

                    divider

                    Text("By using I AM Enough, you acknowledge that you have read and understood this disclaimer and agree to use the app for personal growth and inspirational purposes only.")
                        .font(Theme.bodyItalic(14))
                        .lineSpacing(Theme.reflectionLineSpacing)
                        .foregroundStyle(Theme.inkFaded)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 32)

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
                Text("Disclaimer")
                    .font(Theme.display(18))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.accentGold.opacity(0.25))
            .frame(height: 0.5)
            .padding(.bottom, 22)
    }

    private func disclaimerSection(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.accentGold)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)

                Text(body)
                    .font(Theme.body(15))
                    .lineSpacing(Theme.reflectionLineSpacing)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 22)
    }
}
