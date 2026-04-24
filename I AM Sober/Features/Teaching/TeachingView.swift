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
import Combine

struct TeachingView: View {
    @Environment(AppState.self) private var appState

    /// Selected page index. Pages are ordered oldest → today, so the
    /// highest index is always today. Initialised in `.onAppear` once
    /// `appState` is available.
    @State private var selectedIndex: Int = 0
    /// Becomes true once the splash screen has finished and the teaching
    /// content is actually visible to the user. Drives the initial fade-in.
    @State private var initialAnimReady = false

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
                    TeachingPage(
                        date: dateForOffset(daysFromToday),
                        isSelected: index == selectedIndex,
                        initialAnimReady: initialAnimReady
                    )
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
            // Signal the initial page to start its fade-in after the
            // splash animation has fully completed (~3 s splash + 0.4 s fade).
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                initialAnimReady = true
            }
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
    let isSelected: Bool
    /// Passed down from TeachingView; becomes true once the splash is gone.
    let initialAnimReady: Bool

    @State private var isFavorited = false
    /// false = 35% opacity (passive/inactive); true = 100% (active).
    @State private var contentVisible = false
    /// Animates from 0 → real day number each time this page becomes active,
    /// giving the digit-roll effect via .contentTransition(.numericText()).
    @State private var displayDayNumber: Int = 0

    var body: some View {
        let teaching = appState.scheduler.teaching(for: date)
        let dayNumber = appState.scheduler.personalDayNumber(for: date)

        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                header(dayNumber: displayDayNumber, date: date)

                // Intention countdown — only on today's page, only when a
                // goal is active. The view manages its own 1-second timer.
                if Calendar.current.isDateInToday(date) {
                    IntentionCountdown()
                }

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
            // Inactive pages sit at 20% — barely present during the swipe gesture.
            // animateIn brightens to 100% only after the page fully settles.
            .opacity(contentVisible ? 1.0 : 0.20)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, 0, for: .scrollContent)
        .onAppear {
            checkFavorite(teachingId: teaching.id)
            // All pages start at 0.1 opacity (contentVisible = false).
            // Today's page waits for the initialAnimReady signal below.
            // Adjacent pages will animate in via onChange(of: isSelected)
            // when the user actually swipes to them.
        }
        // Fires when the user swipes to or away from this page.
        .onChange(of: isSelected) { _, nowSelected in
            if nowSelected {
                // selectedIndex updates at the 50% swipe mark, not at full
                // completion. Delay animateIn so the snap animation finishes
                // first — this keeps the page at 20% opacity until it's fully
                // within the frame, then brightens.
                if initialAnimReady {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        animateIn(dayNumber: dayNumber)
                    }
                }
            } else {
                // Dims to 20% off-screen so the next swipe-to gets a fresh
                // brighten. No animation needed — page is not visible.
                contentVisible = false
                displayDayNumber = 0
            }
        }
        // Fires once after the splash has fully dismissed. Kicks off the
        // very first fade-in on today's page and enables swipe animations.
        .onChange(of: initialAnimReady) { _, nowReady in
            if nowReady && isSelected { animateIn(dayNumber: dayNumber) }
        }
    }

    private func animateIn(dayNumber: Int) {
        // Brighten from 20% → 100%. Page was already at 20% (contentVisible
        // false), so no flash — just a smooth easeOut brightening.
        withAnimation(.easeOut(duration: 1.0)) {
            contentVisible = true
        }
        withAnimation(.spring(response: 0.65, dampingFraction: 0.7)) {
            displayDayNumber = dayNumber
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

            VStack(spacing: 14) {
                HStack(spacing: 5) {
                    Text("\u{201C}") // opening curly double-quote
                        .font(.system(size: 24, design: .serif))
                        .foregroundStyle(Theme.accentGold.opacity(0.75))
                        .offset(y: -2)
                    Text("TO CARRY WITH YOU")
                        .font(Theme.smallCaps(10))
                        .tracking(2.6)
                        .foregroundStyle(Theme.inkFaded)
                    Text("\u{201D}") // closing curly double-quote
                        .font(.system(size: 24, design: .serif))
                        .foregroundStyle(Theme.accentGold.opacity(0.75))
                        .offset(y: -2)
                }

                Text(text)
                    .font(Theme.bodyItalic())
                    .lineSpacing(Theme.reflectionLineSpacing)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
    }
}

// MARK: - Intention countdown

/// Live days · hours · minutes · seconds countdown shown on today's page
/// when the user has an active intention challenge. Owns its own 1-second
/// timer so it only ticks when visible. Color shifts to gold inside 24 hours
/// to signal the final stretch without being dramatic about it.
private struct IntentionCountdown: View {
    @Environment(AppState.self) private var appState
    @State private var now = Date()

    /// Exact moment the challenge expires, or nil if none is active.
    private var expiry: Date? {
        let prefs = appState.preferences
        guard prefs.intentionDurationDays > 0,
              let start = prefs.intentionStartDate else { return nil }
        return Calendar.current.date(
            byAdding: .day, value: prefs.intentionDurationDays, to: start
        )
    }

    var body: some View {
        if let expiry {
            let remaining  = max(0, expiry.timeIntervalSince(now))
            let total      = Int(remaining)
            let days       = total / 86_400
            let hours      = (total % 86_400) / 3_600
            let minutes    = (total % 3_600) / 60
            let seconds    = total % 60
            let finalDay   = days == 0
            let accent     = finalDay ? Theme.accentGold : Theme.inkFaded

            HStack(spacing: 10) {
                Rectangle()
                    .fill(accent.opacity(0.35))
                    .frame(height: 0.5)

                HStack(spacing: 7) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 11, weight: .bold))

                    Group {
                        if days > 0 {
                            Text("\(days)d · \(hours)h · \(minutes)m · \(String(format: "%02d", seconds))s")
                        } else {
                            Text("\(hours)h · \(minutes)m · \(String(format: "%02d", seconds))s")
                        }
                    }
                    .font(Theme.smallCaps(15))
                    .tracking(1.2)
                    .monospacedDigit()
                    .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(accent)

                Rectangle()
                    .fill(accent.opacity(0.35))
                    .frame(height: 0.5)
            }
            .onReceive(
                Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            ) { _ in
                now = Date()
            }
        }
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
        styledText
            .lineSpacing(Theme.bodyLineSpacing)
    }

    /// Builds the mixed-size text using AttributedString so we avoid the
    /// deprecated Text + Text concatenation operator flagged in Xcode 16+.
    private var styledText: Text {
        var cap = AttributedString(firstChar)
        cap[AttributeScopes.SwiftUIAttributes.FontAttribute.self] =
            .system(size: 35, weight: .bold, design: .serif)
        cap[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] =
            Theme.inkFadedDark

        var rest = AttributedString(remainder)
        rest[AttributeScopes.SwiftUIAttributes.FontAttribute.self] = Theme.body()
        rest[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = Theme.ink

        return Text(cap + rest)
    }
}

#Preview {
    TeachingView()
        .environment(AppState())
}
