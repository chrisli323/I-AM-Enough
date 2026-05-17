//
//  NotificationService.swift
//  I AM Sober
//
//  Manages a single daily local notification reminding the user to
//  read their teaching. Authorization is requested only when the user
//  first toggles notifications on — never at launch. The notification
//  body is a short, private prompt ("Your teaching for today is ready.")
//  with no teaching content visible on the lock screen.
//

import Foundation
import UserNotifications

@Observable
final class NotificationService {

    var isEnabled: Bool {
        didSet {
            preferences.notificationsEnabled = isEnabled
            if isEnabled {
                requestAuthorizationAndSchedule()
            } else {
                cancelAll()
            }
        }
    }

    var reminderHour: Int {
        didSet { preferences.notificationHour = reminderHour; reschedule() }
    }

    var reminderMinute: Int {
        didSet { preferences.notificationMinute = reminderMinute; reschedule() }
    }

    /// Formatted time string for display.
    var reminderTimeString: String {
        String(format: "%d:%02d %@",
               reminderHour == 0 ? 12 : (reminderHour > 12 ? reminderHour - 12 : reminderHour),
               reminderMinute,
               reminderHour >= 12 ? "PM" : "AM")
    }

    /// Binding-friendly Date representation of the reminder time.
    var reminderDate: Date {
        get {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = comps.hour ?? 8
            reminderMinute = comps.minute ?? 0
        }
    }

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Becomes `true` when the user tries to enable reminders but iOS
    /// notifications are blocked. The UI observes this to show an alert
    /// directing the user to Settings. Reset to `false` after the alert
    /// is dismissed.
    var permissionsDenied: Bool = false

    private let preferences: UserPreferences
    private let center = UNUserNotificationCenter.current()

    private static let notificationID = "daily_teaching_reminder"
    private static let intentionCompletionID = "intention_completed"

    // MARK: - Notification messages — rotated so they don't feel stale.
    private static let messages = [
        "Your teaching for today is ready.",
        "A moment of clarity is waiting for you.",
        "Today's wisdom is here. Take a breath and read.",
        "Your daily teaching is waiting. One day at a time.",
        "A few quiet words are ready for you today.",
        "Step in. Today's teaching is here.",
        "Take a moment for yourself. Your teaching awaits."
    ]

    init(preferences: UserPreferences) {
        self.preferences = preferences
        self.isEnabled = preferences.notificationsEnabled
        self.reminderHour = preferences.notificationHour
        self.reminderMinute = preferences.notificationMinute
        checkCurrentStatus()
    }

    // MARK: - Authorization

    private func requestAuthorizationAndSchedule() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.authorizationStatus = granted ? .authorized : .denied
                if granted {
                    self.permissionsDenied = false
                    self.scheduleDaily()
                } else {
                    self.isEnabled = false
                    self.permissionsDenied = true
                }
            }
        }
    }

    private func checkCurrentStatus() {
        center.getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Scheduling

    private func scheduleDaily() {
        cancelAll()

        let content = UNMutableNotificationContent()
        content.title = "I AM Enough"
        content.body = Self.messages.randomElement() ?? Self.messages[0]
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.notificationID,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    private func reschedule() {
        guard isEnabled else { return }
        scheduleDaily()
    }

    private func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }

    // MARK: - Intention Completion Notification

    /// Schedule a one-time "Congratulations" notification to fire at
    /// midnight on the day the challenge completes.
    func scheduleIntentionCompletion(in days: Int) {
        let content = UNMutableNotificationContent()
        content.title = "You did it! 🥳"
        content.body = "Congratulations! You completed your \(days)-day challenge."
        content.sound = .default

        guard let fireDate = Calendar.current.date(
            byAdding: .day, value: days,
            to: Calendar.current.startOfDay(for: Date())
        ) else { return }

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.intentionCompletionID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// Remove any pending intention completion notification (call when challenge is cancelled).
    func cancelIntentionCompletion() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.intentionCompletionID])
    }
}
