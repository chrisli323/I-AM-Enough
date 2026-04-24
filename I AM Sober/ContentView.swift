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
            TabView(selection: Binding(
                get: { router.selectedTab },
                set: { newTab in
                    if newTab == .home && router.selectedTab == .home {
                        // Re-tap on the already-active Today tab — snap back to today.
                        router.returnToTodayTrigger.toggle()
                    }
                    router.selectedTab = newTab
                }
            )) {
                TeachingView()
                    .tabItem { Label("Today", systemImage: "sun.max") }
                    .tag(Router.Tab.home)

                JournalListView()
                    .tabItem { Label("Journal", systemImage: "book") }
                    .tag(Router.Tab.journal)

                FavoritesView()
                    .tabItem { Label("Favorites", systemImage: "heart") }
                    .tag(Router.Tab.favorites)

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                    .tag(Router.Tab.settings)
            }
            .toolbarBackground(.thinMaterial.opacity(0.45), for: .tabBar)
            .tint(Theme.inkFadedDark)
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


#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
