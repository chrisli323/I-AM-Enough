//
//  AppState.swift
//  I AM Sober
//
//  Root container for the app's services. Created once in I_AM_SoberApp
//  and injected into the SwiftUI environment so any view can read/write
//  shared state without passing props through every layer.
//

import Foundation

@Observable
final class AppState {
    let preferences: UserPreferences
    let teachingStore: TeachingStore
    let scheduler: TeachingScheduler
    let router: Router
    let audioService: AudioService
    let notificationService: NotificationService

    init() {
        let preferences = UserPreferences()
        let store = TeachingStore()
        self.preferences = preferences
        self.teachingStore = store
        self.scheduler = TeachingScheduler(store: store, preferences: preferences)
        self.router = Router()
        self.audioService = AudioService(preferences: preferences)
        self.notificationService = NotificationService(preferences: preferences)
    }
}
