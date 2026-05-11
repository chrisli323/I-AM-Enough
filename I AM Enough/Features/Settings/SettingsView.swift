//
//  SettingsView.swift
//  I AM Sober
//
//  Phase 5 — Full settings screen. Parchment-styled sections for
//  journey management, future feature toggles, and app info.
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    private let privacyPolicyURL = URL(string: "https://chrisli323.github.io/I-AM-Enough/privacy.html")!
    @Query(sort: \CompletedChallenge.completedAt, order: .reverse) private var completedChallenges: [CompletedChallenge]

    @State private var showingSobrietySetup = false
    @State private var showingSobrietyResetConfirm = false
    @State private var sobrietyDate = Date()
    @State private var showingWelcome = false
    @State private var showingIntentionSetup = false
    @State private var selectedChallengeDays: Int? = nil
    @State private var intentionNameText: String = ""
    @State private var showingCancelIntentionConfirm = false
    @State private var isRestoringPurchases = false
    @State private var restoreMessage: String?
    @State private var showingRestoreAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.parchmentBackground
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {

                        // MARK: - Your Journey
                        settingsSection(title: "YOUR JOURNEY") {
                            journeyRow
                            divider
                            sobrietySection
                            divider
                            intentionRow
                            if appState.preferences.intentionDurationDays > 0 &&
                               appState.preferences.intentionDaysRemaining > 0 {
                                divider
                                cancelIntentionRow
                            }
                            divider
                            welcomeRow
                        }

                        // MARK: - My Achievements
                        settingsSection(title: "MY ACHIEVEMENTS") {
                            achievementsSection
                        }

                        // MARK: - App Access
                        settingsSection(title: "APP ACCESS") {
                            appAccessSection
                        }

                        // MARK: - Audio
                        settingsSection(title: "AMBIENT AUDIO") {
                            audioToggleRow
                            if appState.audioService.isEnabled {
                                divider
                                audioVolumeRow
                                if !appState.audioService.availableTracks.isEmpty {
                                    divider
                                    audioTrackRow
                                }
                            }
                        }

                        // MARK: - Notifications
                        settingsSection(title: "DAILY REMINDER") {
                            notificationToggleRow
                            if appState.notificationService.isEnabled {
                                divider
                                notificationTimeRow
                            }
                        }
                        .id("notifications")

                        // MARK: - About
                        settingsSection(title: "ABOUT") {
                            aboutRow(
                                icon: "info.circle",
                                title: "Version",
                                value: appVersion
                            )
                            divider
                            aboutRow(
                                icon: "doc.text",
                                title: "Teachings",
                                value: "\(appState.teachingStore.count) available"
                            )
                            divider
                            Button {
                                openURL(privacyPolicyURL)
                            } label: {
                                HStack(spacing: 14) {
                                    settingsIcon("lock.shield", color: Theme.inkFaded)
                                    Text("Privacy Policy")
                                        .font(Theme.body(16))
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.inkFaded.opacity(0.6))
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }

                        // Footer
                        VStack(spacing: 6) {
                            Text("I AM Enough")
                                .font(Theme.smallCaps(10))
                                .tracking(3)
                                .foregroundStyle(Theme.inkFaded)
                            Text("one day at a time")
                                .font(Theme.bodyItalic(12))
                                .foregroundStyle(Theme.inkFaded.opacity(0.6))
                            Text("© 2026 Chris Lee. All rights reserved.")
                                .font(Theme.smallCaps(9))
                                .tracking(1)
                                .foregroundStyle(Theme.inkFaded.opacity(0.45))
                                .padding(.top, 4)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    if appState.router.scrollToNotifications {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo("notifications", anchor: .center)
                            }
                            appState.router.scrollToNotifications = false
                        }
                    }
                }
                } // ScrollViewReader
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .sheet(isPresented: $showingSobrietySetup) {
            sobrietySetupSheet
        }
        .sheet(isPresented: $showingIntentionSetup) {
            IntentionSetupSheet(selectedDays: $selectedChallengeDays,
                               intentionName: $intentionNameText,
                               isIntentionActive: appState.preferences.intentionDurationDays > 0) {
                if let days = selectedChallengeDays {
                    if days == -1 {
                        // ⚠️ TODO: REMOVE BEFORE RELEASE — 1-minute test mode (Bronze)
                        appState.preferences.setIntention(days: 1, name: intentionNameText)
                        appState.preferences.intentionExpiryDate = Date().addingTimeInterval(60)
                    } else if days == -2 {
                        // ⚠️ TODO: REMOVE BEFORE RELEASE — 1-minute test mode (Platinum)
                        appState.preferences.setIntention(days: 365, name: intentionNameText)
                        appState.preferences.intentionExpiryDate = Date().addingTimeInterval(60)
                    } else {
                        appState.preferences.setIntention(days: days, name: intentionNameText)
                        appState.notificationService.scheduleIntentionCompletion(in: days)
                    }
                }
                intentionNameText = ""
                showingIntentionSetup = false
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
            .presentationDragIndicator(.hidden)
        }
        .alert("Reset Journey?", isPresented: $showingSobrietyResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset to Day 1", role: .destructive) {
                appState.preferences.resetJourney()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showingWelcome = true
                }
            }
            Button("Turn Off Tracking", role: .destructive) {
                appState.preferences.clearSobrietyTracking()
            }
        } message: {
            Text("This will reset your day counter and progress tracker back to Day 1, or you can turn off tracking entirely. Your journal entries and teachings will not be affected.")
        }
    }

    // MARK: - App Access Section

    @ViewBuilder
    private var appAccessSection: some View {
        if appState.purchaseManager.isUnlocked {
            // ── Unlocked state ────────────────────────────────────────────
            HStack(spacing: 14) {
                settingsIcon("checkmark.seal.fill", color: .green.opacity(0.7))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Full Access Unlocked")
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.ink)
                    Text("All 365 teachings · Thank you ✦")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded)
                }
                Spacer()
            }
            .padding(.vertical, 4)

        } else if appState.preferences.isTrialActive {
            // ── Trial active ──────────────────────────────────────────────
            HStack(spacing: 14) {
                settingsIcon("gift", color: Theme.accentGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free Trial")
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.ink)
                    let days = appState.preferences.trialDaysRemaining
                    Text(days == 1 ? "1 day remaining" : "\(days) days remaining")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded)
                }
                Spacer()
            }
            .padding(.vertical, 4)
            divider
            restorePurchasesRow

        } else {
            // ── Trial ended, not unlocked ─────────────────────────────────
            let price = appState.purchaseManager.product?.displayPrice ?? "$4.99"
            Button {
                Task {
                    do {
                        try await appState.purchaseManager.purchase()
                    } catch { }
                }
            } label: {
                HStack(spacing: 14) {
                    settingsIcon("lock.open", color: Theme.accentGold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock I AM Enough")
                            .font(Theme.body(16))
                            .foregroundStyle(Theme.ink)
                        Text("\(price) · One-time · All 365 teachings")
                            .font(Theme.bodyItalic(13))
                            .foregroundStyle(Theme.inkFaded)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.inkFaded.opacity(0.6))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            divider
            restorePurchasesRow
        }
    }

    private var restorePurchasesRow: some View {
        Button {
            Task {
                isRestoringPurchases = true
                await appState.purchaseManager.restorePurchases()
                isRestoringPurchases = false
                if appState.purchaseManager.isUnlocked {
                    restoreMessage = "Purchase restored successfully."
                } else {
                    restoreMessage = "No previous purchase found for this Apple ID."
                }
                showingRestoreAlert = true
            }
        } label: {
            HStack(spacing: 14) {
                if isRestoringPurchases {
                    ProgressView()
                        .frame(width: 28, height: 28)
                } else {
                    settingsIcon("arrow.clockwise", color: Theme.inkFaded)
                }
                Text("Restore Purchases")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(isRestoringPurchases)
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    // MARK: - Sobriety Setup Sheet

    private var sobrietySetupSheet: some View {
        NavigationStack {
            ZStack {
                Theme.parchmentBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.green.opacity(0.6))

                            Text("Change Your Day 1")
                                .font(Theme.display(26))
                                .foregroundStyle(Theme.ink)

                            Text("This is completely optional and private. Choose the date you began — or want to begin — your journey. You can reset or turn this off anytime.")
                                .font(Theme.body(16))
                                .lineSpacing(5)
                                .foregroundStyle(Theme.inkSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 24)

                        DatePicker(
                            "Start Date",
                            selection: $sobrietyDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(Theme.accentGold)
                        .padding(.horizontal, 16)

                        Button {
                            appState.preferences.resetJourney(to: sobrietyDate)
                            showingSobrietySetup = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showingWelcome = true
                            }
                        } label: {
                            Text("Begin")
                                .font(Theme.body(18))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Theme.accentGold)
                                )
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 24)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 24)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showingSobrietySetup = false }
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Journey Section

    private var welcomeRow: some View {
        Button {
            showingWelcome = true
        } label: {
            HStack(spacing: 14) {
                settingsIcon("book.closed", color: Theme.accentGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Why I'm Here")
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.ink)
                    Text("Revisit your welcome & purpose")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.inkFaded.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingWelcome) {
            WelcomeView(isRevisit: true) {
                showingWelcome = false
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
            .presentationDragIndicator(.hidden)
        }
    }

    private var journeyRow: some View {
        let dayNumber = appState.scheduler.personalDayNumber()
        let isTracking = appState.preferences.sobrietyTrackingEnabled

        return HStack(spacing: 14) {
            settingsIcon(
                isTracking ? "leaf.fill" : "flame",
                color: isTracking ? .green.opacity(0.7) : Theme.accentGold
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Journey")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
                Text("Day \(dayNumber)")
                    .font(Theme.display(22))
                    .foregroundStyle(isTracking ? .green.opacity(0.8) : Theme.accentGold)
            }

            Spacer()

            Text("since \(appState.preferences.personalDayOneDate, format: .dateTime.month(.abbreviated).day().year())")
                .font(Theme.smallCaps(9))
                .tracking(1)
                .foregroundStyle(Theme.inkFaded)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Intention Row

    private var intentionRow: some View {
        let remaining = appState.preferences.intentionDaysRemaining
        let active = appState.preferences.intentionDurationDays > 0 && remaining > 0
        let sageGreen = Color(red: 0.49, green: 0.608, blue: 0.416)

        return Button {
            selectedChallengeDays = nil // reset selection each time sheet opens
            showingIntentionSetup = true
        } label: {
            HStack(spacing: 14) {
                settingsIcon("flag", color: active ? sageGreen : Theme.accentGold)

                VStack(alignment: .leading, spacing: 2) {
                    let name = appState.preferences.intentionName
                    Text(active && !name.isEmpty ? name.capitalized : "Set an Intention")
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.ink)
                    Text(active
                         ? "\(appState.preferences.intentionDurationDays)-day challenge · in progress"
                         : "Set a goal or challenge for yourself")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded)
                }

                Spacer()

                if active {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(remaining)")
                            .font(Theme.display(22))
                            .foregroundStyle(sageGreen)
                        Text("days left")
                            .font(Theme.smallCaps(9))
                            .tracking(1.4)
                            .foregroundStyle(sageGreen.opacity(0.7))
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.inkFaded.opacity(0.6))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var cancelIntentionRow: some View {
        Button {
            showingCancelIntentionConfirm = true
        } label: {
            HStack(spacing: 14) {
                settingsIcon("xmark.circle", color: .red.opacity(0.55))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Cancel Challenge")
                        .font(Theme.body(16))
                        .foregroundStyle(.red.opacity(0.72))
                    Text("Didn't reach your goal? Cancel challenge now.")
                        .font(Theme.bodyItalic(13))
                        .foregroundStyle(Theme.inkFaded)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .alert("Cancel Challenge?", isPresented: $showingCancelIntentionConfirm) {
            Button("Keep Going", role: .cancel) {}
            Button("Cancel Challenge", role: .destructive) {
                appState.preferences.clearIntention()
                appState.notificationService.cancelIntentionCompletion()
            }
        } message: {
            Text("Are you sure you want to cancel your challenge? Your progress will be reset.")
        }
    }

    // MARK: - Achievements Section

    @ViewBuilder
    private var achievementsSection: some View {
        if completedChallenges.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "medal")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.inkFaded.opacity(0.35))
                Text("No achievements yet")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.inkFaded)
                Text("Complete a challenge to earn your first badge.")
                    .font(Theme.bodyItalic(13))
                    .foregroundStyle(Theme.inkFaded.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            // Preview: at most 3 most-recent badges
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 20
            ) {
                ForEach(completedChallenges.prefix(3)) { challenge in
                    BadgeView(challenge: challenge)
                }
            }
            .padding(.vertical, 8)

            // "See All" link — always visible so users can explore the badge guide
            divider
            NavigationLink {
                AchievementsView()
            } label: {
                HStack(spacing: 14) {
                    settingsIcon("trophy", color: Theme.accentGold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All Achievements")
                            .font(Theme.body(16))
                            .foregroundStyle(Theme.ink)
                        Text(completedChallenges.count == 1
                             ? "1 badge earned"
                             : "\(completedChallenges.count) badges earned")
                            .font(Theme.bodyItalic(13))
                            .foregroundStyle(Theme.inkFaded)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.inkFaded.opacity(0.6))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Audio Rows

    private var audioToggleRow: some View {
        @Bindable var audio = appState.audioService

        return HStack(spacing: 14) {
            settingsIcon(
                audio.isEnabled ? "speaker.wave.2.fill" : "speaker.slash",
                color: audio.isEnabled ? Theme.accentGold : Theme.inkFaded
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Ambient Sound")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
                Text(audio.isEnabled ? "Playing while you read" : "Off")
                    .font(Theme.bodyItalic(13))
                    .foregroundStyle(Theme.inkFaded)
            }

            Spacer()

            Toggle("", isOn: $audio.isEnabled)
                .labelsHidden()
                .tint(Theme.accentGold)
        }
        .padding(.vertical, 4)
    }

    private var audioVolumeRow: some View {
        @Bindable var audio = appState.audioService

        return HStack(spacing: 14) {
            settingsIcon("speaker.wave.1", color: Theme.inkFaded)

            Slider(value: $audio.volume, in: 0.01...0.15)
                .tint(Theme.accentGold)

            settingsIcon("speaker.wave.3", color: Theme.inkFaded)
        }
        .padding(.vertical, 4)
    }

    private var audioTrackRow: some View {
        @Bindable var audio = appState.audioService

        return HStack(spacing: 14) {
            settingsIcon("music.note", color: Theme.inkFaded)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sound")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
            }

            Spacer()

            Picker("", selection: $audio.selectedTrack) {
                ForEach(audio.availableTracks, id: \.self) { track in
                    Text(track.replacingOccurrences(of: "_", with: " ").capitalized)
                        .tag(track)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.inkSecondary)
            .font(Theme.body(13))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sobriety Section

    @ViewBuilder
    private var sobrietySection: some View {
        if appState.preferences.sobrietyTrackingEnabled {
            // Active tracker — journeyRow already shows the unified display,
            // so here we just offer reset / turn-off options.
            Button {
                showingSobrietyResetConfirm = true
            } label: {
                HStack(spacing: 14) {
                    settingsIcon("arrow.counterclockwise", color: Theme.inkFaded)
                    Text("Reset Journey")
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.inkFaded)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                sobrietyDate = Date()
                showingSobrietySetup = true
            } label: {
                HStack(spacing: 14) {
                    settingsIcon("calendar", color: Theme.inkFaded)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Change Your Start Date")
                            .font(Theme.body(16))
                            .foregroundStyle(Theme.ink)
                        Text("Optional — change if your Day 1 was a different date")
                            .font(Theme.bodyItalic(13))
                            .foregroundStyle(Theme.inkFaded)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.inkFaded)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Notification Rows

    private var notificationToggleRow: some View {
        @Bindable var notifications = appState.notificationService

        return HStack(spacing: 14) {
            settingsIcon(
                notifications.isEnabled ? "bell.fill" : "bell.slash",
                color: notifications.isEnabled ? Theme.accentGold : Theme.inkFaded
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Reminder")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
                Text(notifications.isEnabled
                     ? "Reminds you at \(notifications.reminderTimeString)"
                     : "Off")
                    .font(Theme.bodyItalic(13))
                    .foregroundStyle(Theme.inkFaded)
            }

            Spacer()

            Toggle("", isOn: $notifications.isEnabled)
                .labelsHidden()
                .tint(Theme.accentGold)
        }
        .padding(.vertical, 4)
    }

    private var notificationTimeRow: some View {
        @Bindable var notifications = appState.notificationService

        return HStack(spacing: 14) {
            settingsIcon("clock", color: Theme.inkFaded)

            Text("Reminder Time")
                .font(Theme.body(16))
                .foregroundStyle(Theme.ink)

            Spacer()

            DatePicker(
                "",
                selection: $notifications.reminderDate,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(Theme.accentGold)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Coming Soon Rows

    private func comingSoonRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            settingsIcon(icon, color: Theme.inkFaded)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.bodyItalic(13))
                    .foregroundStyle(Theme.inkFaded)
            }

            Spacer()

            Text("SOON")
                .font(Theme.smallCaps(8))
                .tracking(1.6)
                .foregroundStyle(Theme.inkFaded.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Theme.parchmentShadow.opacity(0.12))
                )
        }
        .padding(.vertical, 4)
    }

    // MARK: - About Rows

    private func aboutRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            settingsIcon(icon, color: Theme.inkFaded)

            Text(title)
                .font(Theme.body(16))
                .foregroundStyle(Theme.ink)

            Spacer()

            Text(value)
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkFaded)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Reusable Components

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Theme.smallCaps(10))
                .tracking(2.6)
                .foregroundStyle(Theme.inkFaded)
                .padding(.leading, 4)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                content()
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
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.accentGold.opacity(0.15))
            .frame(height: 0.5)
            .padding(.vertical, 6)
    }

    private func settingsIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 16))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
