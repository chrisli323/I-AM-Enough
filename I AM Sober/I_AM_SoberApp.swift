//
//  I_AM_SoberApp.swift
//  I AM Sober
//
//  Created by Chris Lee on 4/9/26.
//

import SwiftUI
import SwiftData

@main
struct I_AM_SoberApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(for: [JournalEntry.self, FavoriteTeaching.self, CompletedChallenge.self])
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                appState.audioService.resume()
            case .inactive, .background:
                appState.audioService.pause()
            @unknown default:
                break
            }
        }
    }
}
