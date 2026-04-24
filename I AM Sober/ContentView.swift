//
//  ContentView.swift
//  I AM Sober
//
//  Root view. Shows the splash screen on launch, then dissolves into
//  the three-tab shell (Home / Journal / Settings).
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var showingSplash = true
    @State private var showingWelcome = false
    @State private var showingNotificationPrompt = false

    var body: some View {
        @Bindable var router = appState.router

        ZStack {
            TabView(selection: $router.selectedTab) {
                TeachingView()
                    .tag(Router.Tab.home)

                JournalListView()
                    .tag(Router.Tab.journal)

                FavoritesView()
                    .tag(Router.Tab.favorites)

                SettingsView()
                    .tag(Router.Tab.settings)
            }
            .toolbar(.hidden, for: .tabBar)
            // Prevent the hidden UITabBar from painting a white strip
            .toolbarBackground(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CustomTabBar(selectedTab: $router.selectedTab)
                    .opacity(showingSplash ? 0 : 1)
            }
            .opacity(showingSplash ? 0 : 1)

            if showingSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showingSplash = false
                    }
                    // Start audio after splash so it doesn't stutter during loading
                    appState.audioService.start()
                    // Check if a challenge completed while app was closed
                    checkIntentionExpiry()
                    // Show welcome on first ever launch
                    if !appState.preferences.hasSeenWelcome {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingWelcome = true
                        }
                    } else if !appState.preferences.hasSeenNotificationPrompt {
                        // Returning user who hasn't seen the notification prompt yet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showingNotificationPrompt = true
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { checkIntentionExpiry() }
        }
        // Poll every 10 seconds while the app is open so the sheet fires the
        // moment the challenge timer hits zero — not just on next launch.
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            guard scenePhase == .active else { return }
            checkIntentionExpiry()
        }
        .sheet(isPresented: Binding(
            get: { appState.router.showCongratulations },
            set: { appState.router.showCongratulations = $0 }
        )) {
            CongratulatoryView(challengeDays: appState.preferences.intentionDurationDays) {
                let days = appState.preferences.intentionDurationDays
                let challenge = CompletedChallenge(days: days)
                modelContext.insert(challenge)
                try? modelContext.save()
                appState.router.showCongratulations = false
                appState.preferences.clearIntention()
                appState.router.selectedTab = .home
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showingWelcome) {
            WelcomeView {
                appState.preferences.hasSeenWelcome = true
                showingWelcome = false
                // Prompt for notifications after welcome is dismissed
                if !appState.preferences.hasSeenNotificationPrompt {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showingNotificationPrompt = true
                    }
                }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
        .alert("Daily Reminder", isPresented: $showingNotificationPrompt) {
            Button("Not Now") {
                appState.preferences.hasSeenNotificationPrompt = true
            }
            Button("Set Time") {
                appState.preferences.hasSeenNotificationPrompt = true
                appState.notificationService.isEnabled = true
                appState.router.selectedTab = .settings
                appState.router.scrollToNotifications = true
            }
        } message: {
            Text("Set a daily reminder for your teachings.")
        }
    }

    // MARK: - Helpers

    private func checkIntentionExpiry() {
        guard appState.preferences.isIntentionExpired else { return }
        guard !appState.router.showCongratulations else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appState.router.showCongratulations = true
        }
    }
}

// MARK: - Custom tab bar with micro-bounce

/// A parchment-tinted tab bar where the selected icon springs upward with a
/// brief overshoot when tapped — a small flourish that reinforces the warm,
/// handcrafted feel of the rest of the app.
private struct CustomTabBar: View {
    @Binding var selectedTab: Router.Tab

    /// The tab that most recently received a tap — drives the bounce animation.
    @State private var bouncingTab: Router.Tab? = nil

    private let items: [(tab: Router.Tab, icon: String, label: String)] = [
        (.home,      "sun.max",   "Today"),
        (.journal,   "book",      "Journal"),
        (.favorites, "heart",     "Favorites"),
        (.settings,  "gearshape", "Settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab) { item in
                VStack(spacing: 4) {
                    Image(systemName: item.icon)
                        .font(.system(size: 21, weight: .regular))
                        // Spring upward on selection, settle back in place
                        .scaleEffect(bouncingTab == item.tab ? 1.38 : 1.0)
                        .offset(y: bouncingTab == item.tab ? -3 : 0)
                        .animation(
                            .spring(response: 0.28, dampingFraction: 0.45),
                            value: bouncingTab
                        )

                    Text(item.label)
                        .font(Theme.smallCaps(9))
                        .tracking(1.2)
                }
                .foregroundStyle(
                    selectedTab == item.tab
                        ? Theme.inkFadedDark
                        : Theme.inkFaded.opacity(0.55)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                // Use tap gesture instead of Button to avoid system press highlights
                .contentShape(Rectangle())
                .onTapGesture {
                    guard selectedTab != item.tab else { return }
                    selectedTab = item.tab
                    bouncingTab = item.tab
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        if bouncingTab == item.tab { bouncingTab = nil }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .background(
            ZStack(alignment: .top) {
                // Solid parchment base so no system white bleeds through,
                // then a thin material layer on top for the frosted-glass depth.
                Theme.parchmentLight
                Rectangle()
                    .fill(.thinMaterial.opacity(0.55))
                // Gold top hairline
                Rectangle()
                    .fill(Theme.accentGold.opacity(0.35))
                    .frame(height: 0.5)
            }
        )
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
