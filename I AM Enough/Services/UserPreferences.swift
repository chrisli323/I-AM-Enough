//
//  UserPreferences.swift
//  I AM Sober
//
//  Thin wrapper around UserDefaults for the few pieces of per-user state
//  we need in Phase 1. Kept intentionally small — we'll grow it as later
//  phases need more (audio volume, notification time, sobriety date, etc.).
//
//  NOTE: Because every property is *computed* (backed by UserDefaults),
//  we must manually call `access(keyPath:)` in getters and wrap setters
//  in `withMutation(keyPath:)` so that SwiftUI's @Observable tracking
//  knows when values are read and when they change.
//

import Foundation

@Observable
final class UserPreferences {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Stamp the first-open date the very first time the app launches.
        // This is the permanent "install date" — it never changes, even if
        // the user resets their personal Day 1 for the sobriety tracker.
        if defaults.object(forKey: Keys.firstOpenDate) == nil {
            defaults.set(Date(), forKey: Keys.firstOpenDate)
        }
    }

    // MARK: - First open (install date)

    /// The date the user first launched the app. Used as the anchor for
    /// the teaching rotation so everyone sees teachings in order starting
    /// from day 1 of their own install. Never reset.
    var firstOpenDate: Date {
        get {
            access(keyPath: \.firstOpenDate)
            return defaults.object(forKey: Keys.firstOpenDate) as? Date ?? Date()
        }
    }

    // MARK: - Personal Day 1 (display label only)

    /// The date the user considers their personal "Day 1" — used only to
    /// render the "Day N" label on screen. Defaults to `firstOpenDate`.
    /// Resetting this does NOT affect which teaching is shown today.
    var personalDayOneDate: Date {
        get {
            access(keyPath: \.personalDayOneDate)
            return defaults.object(forKey: Keys.personalDayOneDate) as? Date ?? firstOpenDate
        }
        set {
            withMutation(keyPath: \.personalDayOneDate) {
                defaults.set(newValue, forKey: Keys.personalDayOneDate)
            }
        }
    }

    /// Resets the journey — updates both the Day N label and the sobriety
    /// tracker to stay in sync across the entire app.
    func resetJourney(to date: Date = Date()) {
        personalDayOneDate = date
        sobrietyStartDate = date
        sobrietyTrackingEnabled = true
    }

    // MARK: - Audio

    var audioEnabled: Bool {
        get {
            access(keyPath: \.audioEnabled)
            return defaults.object(forKey: Keys.audioEnabled) != nil ? defaults.bool(forKey: Keys.audioEnabled) : true
        }
        set {
            withMutation(keyPath: \.audioEnabled) {
                defaults.set(newValue, forKey: Keys.audioEnabled)
            }
        }
    }

    var audioVolume: Float {
        get {
            access(keyPath: \.audioVolume)
            let val = defaults.float(forKey: Keys.audioVolume)
            return val > 0 ? val : 0.05
        }
        set {
            withMutation(keyPath: \.audioVolume) {
                defaults.set(newValue, forKey: Keys.audioVolume)
            }
        }
    }

    var audioTrack: String {
        get {
            access(keyPath: \.audioTrack)
            return defaults.string(forKey: Keys.audioTrack) ?? "ambient_nature"
        }
        set {
            withMutation(keyPath: \.audioTrack) {
                defaults.set(newValue, forKey: Keys.audioTrack)
            }
        }
    }

    // MARK: - Sobriety Tracker

    /// Whether the user has opted in to sobriety tracking.
    var sobrietyTrackingEnabled: Bool {
        get {
            access(keyPath: \.sobrietyTrackingEnabled)
            return defaults.bool(forKey: Keys.sobrietyTrackingEnabled)
        }
        set {
            withMutation(keyPath: \.sobrietyTrackingEnabled) {
                defaults.set(newValue, forKey: Keys.sobrietyTrackingEnabled)
            }
        }
    }

    /// The date the user set as their sobriety start. Nil if not set.
    var sobrietyStartDate: Date? {
        get {
            access(keyPath: \.sobrietyStartDate)
            return defaults.object(forKey: Keys.sobrietyStartDate) as? Date
        }
        set {
            withMutation(keyPath: \.sobrietyStartDate) {
                defaults.set(newValue, forKey: Keys.sobrietyStartDate)
            }
        }
    }

    func resetSobrietyDate(to date: Date = Date()) {
        sobrietyStartDate = date
        personalDayOneDate = date
    }

    func clearSobrietyTracking() {
        sobrietyTrackingEnabled = false
        withMutation(keyPath: \.sobrietyStartDate) {
            defaults.removeObject(forKey: Keys.sobrietyStartDate)
        }
        // Reset Day N back to install date
        personalDayOneDate = firstOpenDate
    }

    // MARK: - Notifications

    var notificationsEnabled: Bool {
        get {
            access(keyPath: \.notificationsEnabled)
            return defaults.bool(forKey: Keys.notificationsEnabled)
        }
        set {
            withMutation(keyPath: \.notificationsEnabled) {
                defaults.set(newValue, forKey: Keys.notificationsEnabled)
            }
        }
    }

    var notificationHour: Int {
        get {
            access(keyPath: \.notificationHour)
            let val = defaults.integer(forKey: Keys.notificationHour)
            return defaults.object(forKey: Keys.notificationHour) != nil ? val : 8
        }
        set {
            withMutation(keyPath: \.notificationHour) {
                defaults.set(newValue, forKey: Keys.notificationHour)
            }
        }
    }

    var notificationMinute: Int {
        get {
            access(keyPath: \.notificationMinute)
            return defaults.integer(forKey: Keys.notificationMinute)
        }
        set {
            withMutation(keyPath: \.notificationMinute) {
                defaults.set(newValue, forKey: Keys.notificationMinute)
            }
        }
    }

    // MARK: - Prompts

    var hasSeenNotificationPrompt: Bool {
        get {
            access(keyPath: \.hasSeenNotificationPrompt)
            return defaults.bool(forKey: Keys.hasSeenNotificationPrompt)
        }
        set {
            withMutation(keyPath: \.hasSeenNotificationPrompt) {
                defaults.set(newValue, forKey: Keys.hasSeenNotificationPrompt)
            }
        }
    }

    var hasSeenWelcome: Bool {
        get {
            access(keyPath: \.hasSeenWelcome)
            return defaults.bool(forKey: Keys.hasSeenWelcome)
        }
        set {
            withMutation(keyPath: \.hasSeenWelcome) {
                defaults.set(newValue, forKey: Keys.hasSeenWelcome)
            }
        }
    }

    /// True once the user has explicitly tapped "I Agree & Continue" on the
    /// disclaimer screen. Resets if the app is deleted and reinstalled.
    var hasAcceptedDisclaimer: Bool {
        get {
            access(keyPath: \.hasAcceptedDisclaimer)
            return defaults.bool(forKey: Keys.hasAcceptedDisclaimer)
        }
        set {
            withMutation(keyPath: \.hasAcceptedDisclaimer) {
                defaults.set(newValue, forKey: Keys.hasAcceptedDisclaimer)
            }
        }
    }

    // MARK: - Trial Status

    /// Full days elapsed since the very first launch (0 = install day, 6 = Day 7).
    var daysSinceInstall: Int {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: firstOpenDate)
        let today = cal.startOfDay(for: Date())
        return cal.dateComponents([.day], from: start, to: today).day ?? 0
    }

    /// True while the user is within the 7-day free trial (personal Days 1–7).
    var isTrialActive: Bool { daysSinceInstall < 7 }

    /// How many free trial days remain (0 once the trial has ended).
    var trialDaysRemaining: Int { max(0, 7 - daysSinceInstall) }

    // MARK: - Intention / Challenge

    /// The date the user started their current intention challenge. Nil if none set.
    var intentionStartDate: Date? {
        get {
            access(keyPath: \.intentionStartDate)
            return defaults.object(forKey: Keys.intentionStartDate) as? Date
        }
        set {
            withMutation(keyPath: \.intentionStartDate) {
                defaults.set(newValue, forKey: Keys.intentionStartDate)
            }
        }
    }

    /// The user-supplied label for their current intention (e.g. "quit smoking"). Empty string if unnamed.
    var intentionName: String {
        get {
            access(keyPath: \.intentionName)
            return defaults.string(forKey: Keys.intentionName) ?? ""
        }
        set {
            withMutation(keyPath: \.intentionName) {
                defaults.set(newValue, forKey: Keys.intentionName)
            }
        }
    }

    /// The duration in days of the active intention challenge. 0 = no challenge set.
    var intentionDurationDays: Int {
        get {
            access(keyPath: \.intentionDurationDays)
            return defaults.integer(forKey: Keys.intentionDurationDays)
        }
        set {
            withMutation(keyPath: \.intentionDurationDays) {
                defaults.set(newValue, forKey: Keys.intentionDurationDays)
            }
        }
    }

    /// Days remaining in the active challenge. Computed from stored dates — no background timer needed.
    var intentionDaysRemaining: Int {
        access(keyPath: \.intentionStartDate)
        access(keyPath: \.intentionDurationDays)
        guard let start = intentionStartDate, intentionDurationDays > 0 else { return 0 }
        let cal = Calendar.current
        let daysPassed = cal.dateComponents([.day],
            from: cal.startOfDay(for: start),
            to: cal.startOfDay(for: Date())).day ?? 0
        return max(0, intentionDurationDays - daysPassed)
    }

    /// Start a new intention challenge, overwriting any active one.
    func setIntention(days: Int, name: String = "") {
        intentionStartDate = Date()
        intentionDurationDays = days
        intentionName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // ⚠️ TODO: REMOVE BEFORE RELEASE — test-only exact expiry timestamp
    var intentionExpiryDate: Date? {
        get {
            access(keyPath: \.intentionExpiryDate)
            return defaults.object(forKey: Keys.intentionExpiryDate) as? Date
        }
        set {
            withMutation(keyPath: \.intentionExpiryDate) {
                defaults.set(newValue, forKey: Keys.intentionExpiryDate)
            }
        }
    }

    /// Cancel the active intention challenge.
    func clearIntention() {
        intentionStartDate = nil
        intentionDurationDays = 0
        intentionName = ""
        intentionExpiryDate = nil   // ⚠️ TODO: REMOVE WITH intentionExpiryDate
    }

    /// True when a challenge was set and has fully expired (0 days remaining).
    /// Used to trigger the congratulations screen on next app open.
    var isIntentionExpired: Bool {
        access(keyPath: \.intentionStartDate)
        access(keyPath: \.intentionDurationDays)
        access(keyPath: \.intentionExpiryDate)
        guard intentionDurationDays > 0 else { return false }
        // ⚠️ TODO: REMOVE test-mode branch before release
        if let expiry = intentionExpiryDate { return Date() >= expiry }
        return intentionDaysRemaining == 0
    }

    // MARK: - Display

    /// Whether the status bar (time, signal, battery) is hidden while the
    /// app is open. Defaults to `true` for clean screenshots.
    var statusBarHidden: Bool {
        get {
            access(keyPath: \.statusBarHidden)
            // Default true — use object check so false is distinguishable from "never set"
            return defaults.object(forKey: Keys.statusBarHidden) != nil
                ? defaults.bool(forKey: Keys.statusBarHidden)
                : true
        }
        set {
            withMutation(keyPath: \.statusBarHidden) {
                defaults.set(newValue, forKey: Keys.statusBarHidden)
            }
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let firstOpenDate = "firstOpenDate"
        static let personalDayOneDate = "personalDayOneDate"
        static let audioEnabled = "audioEnabled"
        static let audioVolume = "audioVolume"
        static let audioTrack = "audioTrack"
        static let sobrietyTrackingEnabled = "sobrietyTrackingEnabled"
        static let sobrietyStartDate = "sobrietyStartDate"
        static let notificationsEnabled = "notificationsEnabled"
        static let notificationHour = "notificationHour"
        static let notificationMinute = "notificationMinute"
        static let hasSeenNotificationPrompt = "hasSeenNotificationPrompt"
        static let hasSeenWelcome = "hasSeenWelcome"
        static let hasAcceptedDisclaimer = "hasAcceptedDisclaimer"
        static let intentionStartDate = "intentionStartDate"
        static let intentionDurationDays = "intentionDurationDays"
        static let intentionName = "intentionName"
        static let intentionExpiryDate = "intentionExpiryDate" // ⚠️ TODO: REMOVE BEFORE RELEASE
        static let statusBarHidden = "statusBarHidden"
    }
}
