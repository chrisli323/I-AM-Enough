//
//  TeachingView.swift
//  I AM Sober
//
//  Phase 2 — Visual design pass.
//
//  Parchment background, serif typography (Apple's New York via .serif
//  design), and a swipe-back-only page navigation: today is the rightmost
//  page, swiping right reveals previous days, and there is no future
//  page to swipe to. The user can only revisit teachings they've already
//  earned.
//

import SwiftUI
import SwiftData

struct TeachingView: View {
    @Environment(AppState.self) private var appState

    /// Selected page index. Pages are ordered oldest → today, so the
    /// highest index is always today. Initialised in `.onAppear` once
    /// `appState` is available.
    @State private var selectedIndex: Int = 0

    var body: some View {
        // TODO: 🔒 FINAL BUILD — Remove previewDays and lock pageRange
        // back to `Array(0...todayIndex)` so users can only swipe backward.
        let previewDays = 90
        let pageRange = Array(0...(maxBackDays + previewDays))

        ZStack {
            Theme.parchmentBackground

            TabView(selection: $selectedIndex) {
                ForEach(pageRange, id: \.self) { index in
                    let daysFromToday = index - maxBackDays
                    TeachingPage(date: dateForOffset(daysFromToday))
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Fixed audio toggle — anchored to the view, not the page content
            audioToggle
        }
        // Soft tap each time the user crosses to another day. Uses the
        // modern SwiftUI sensoryFeedback API (iOS 17+) so it respects the
        // user's haptics settings automatically.
        .sensoryFeedback(.selection, trigger: selectedIndex)
        .onAppear {
            // Snap to today on first appearance. Re-snap on subsequent
            // appearances too — we want opening the app to always land
            // on today's teaching, never on a stale historical page.
            selectedIndex = maxBackDays // snap to today (not the end)
        }
    }

    // MARK: - Fixed Audio Toggle

    private var audioToggle: some View {
        VStack {
            Spacer().frame(height: 148)
            HStack {
                Spacer()
                Button {
                    appState.audioService.isEnabled.toggle()
                } label: {
                    Image(systemName: appState.audioService.isEnabled
                          ? "speaker.wave.2"
                          : "speaker.slash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(width: 36, height: 28)
                        .background(.thinMaterial.opacity(0.45), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Theme.accentGold.opacity(0.25), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .padding(.trailing, Theme.pageHorizontalPadding)
            }
            Spacer()
        }
        .allowsHitTesting(true)
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    /// How many full days of history exist behind today, capped at the
    /// install date so the very first day shows only one page.
    private var maxBackDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: appState.preferences.firstOpenDate)
        let today = calendar.startOfDay(for: Date())
        return max(calendar.dateComponents([.day], from: start, to: today).day ?? 0, 0)
    }

    /// Positive = future, negative = past, zero = today.
    private func dateForOffset(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
    }
}

// MARK: - Single page

private struct TeachingPage: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    let date: Date

    @State private var isFavorited = false
    @State private var contentVisible = false

    var body: some View {
        let teaching = appState.scheduler.teaching(for: date)
        let dayNumber = appState.scheduler.personalDayNumber(for: date)

        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                header(dayNumber: dayNumber, date: date)

                // Top gold hairline — frames the teaching body like a printed page
                Rectangle()
                    .fill(Theme.accentGold.opacity(0.28))
                    .frame(height: 0.4)

                DropCapBody(text: teaching.body)

                // Bottom gold hairline
                Rectangle()
                    .fill(Theme.accentGold.opacity(0.28))
                    .frame(height: 0.4)

                reflectionBlock(teaching.reflection)

                HStack {
                    reflectInJournalButton
                    Spacer()
                    favoriteButton(teachingId: teaching.id)
                    shareButton(teaching: teaching)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, Theme.pageHorizontalPadding)
            .padding(.top, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Reveal animation — each page slides up and fades in when swiped to
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 12)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 0, for: .scrollContent)
        .onAppear {
            checkFavorite(teachingId: teaching.id)
            contentVisible = false
            withAnimation(.easeOut(duration: 0.38).delay(0.05)) {
                contentVisible = true
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func header(dayNumber: Int, date: Date) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(date, format: .dateTime.month(.wide).day())
                    .font(Theme.smallCaps())
                    .textCase(.uppercase)
                    .tracking(2.4)
                    .foregroundStyle(Theme.inkFaded)

                // Digit-roll animation when swiping between days
                Text("Day \(dayNumber)")
                    .font(Theme.display())
                    .foregroundStyle(Theme.inkFadedDark)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.4), value: dayNumber)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("I AM SOBER")
                    .font(Theme.smallCaps())
                    .tracking(2.4)
                    .foregroundStyle(Theme.inkFaded)
                Text("one day at a time")
                    .font(Theme.bodyItalic(12))
                    .foregroundStyle(Theme.inkFaded.opacity(0.6))
            }
            .padding(.top, 2)
        }
    }

    private var reflectInJournalButton: some View {
        Button {
            appState.router.openJournal(for: date)
        } label: {
            HStack(spacing: 6) {
                Text("Reflect in Journal")
                    .font(Theme.smallCaps(11))
                    .tracking(2.0)
                Image(systemName: "arrow.right")
                    .font(.caption2)
            }
            .foregroundStyle(Theme.inkSecondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .stroke(Theme.accentGold.opacity(0.5), lineWidth: 0.7)
            )
        }
        .buttonStyle(.plain)
    }

    private func shareButton(teaching: Teaching) -> some View {
        ShareLink(item: shareText(for: teaching)) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18))
                .foregroundStyle(Theme.inkFaded)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 16)
    }

    private func shareText(for teaching: Teaching) -> String {
        // TODO: 🔗 FINAL BUILD — Add App Store link before packaging.
        """
        "\(teaching.body)"

        — To Carry With You —
        "\(teaching.reflection)"

        Shared from I AM Sober
        """
    }

    private func favoriteButton(teachingId: Int) -> some View {
        Button {
            toggleFavorite(teachingId: teachingId)
        } label: {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundStyle(isFavorited ? .red : Theme.inkFaded)
                .symbolEffect(.bounce, value: isFavorited)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isFavorited)
    }

    private func checkFavorite(teachingId: Int) {
        let descriptor = FetchDescriptor<FavoriteTeaching>(
            predicate: #Predicate { $0.teachingId == teachingId }
        )
        isFavorited = (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }

    private func toggleFavorite(teachingId: Int) {
        let descriptor = FetchDescriptor<FavoriteTeaching>(
            predicate: #Predicate { $0.teachingId == teachingId }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            isFavorited = false
        } else {
            modelContext.insert(FavoriteTeaching(teachingId: teachingId))
            isFavorited = true
        }
        try? modelContext.save()
    }

    @ViewBuilder
    private func reflectionBlock(_ text: String) -> some View {
        VStack(alignment: .center, spacing: 16) {
            // Ornament-style divider — small fleuron flanked by hairlines,
            // a classic device from old printed books.
            HStack(spacing: 14) {
                Rectangle()
                    .fill(Theme.accentGold.opacity(0.55))
                    .frame(height: 0.6)
                Text("\u{2766}") // ❦ FLORAL HEART
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Theme.accentGold)
                Rectangle()
                    .fill(Theme.accentGold.opacity(0.55))
                    .frame(height: 0.6)
            }
            .padding(.vertical, 4)

            // Quote mark watermark behind the reflection text
            ZStack {
                Text("\u{201C}") // opening curly double-quote
                    .font(.system(size: 100, design: .serif))
                    .foregroundStyle(Theme.accentGold.opacity(0.09))
                    .allowsHitTesting(false)

                VStack(spacing: 14) {
                    Text("TO CARRY WITH YOU")
                        .font(Theme.smallCaps(10))
                        .tracking(2.6)
                        .foregroundStyle(Theme.inkFaded)

                    Text(text)
                        .font(Theme.bodyItalic())
                        .lineSpacing(Theme.reflectionLineSpacing)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
    }
}

// MARK: - Drop cap body

/// Renders the first character of a teaching as a large display-size drop cap
/// with the remaining text flowing beside and below it — a classic manuscript
/// typesetting device that signals "this is worth reading slowly."
private struct DropCapBody: View {
    let text: String

    private var firstChar: String { String(text.prefix(1)) }
    private var remainder: String { String(text.dropFirst()) }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(firstChar)
                .font(.system(size: 54, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.inkFadedDark)
                .padding(.trailing, 3)
                .padding(.top, -3) // align cap-height with the body first line
                .frame(width: 40, alignment: .leading)

            Text(remainder)
                .font(Theme.body())
                .lineSpacing(Theme.bodyLineSpacing)
                .foregroundStyle(Theme.ink)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    TeachingView()
        .environment(AppState())
}
