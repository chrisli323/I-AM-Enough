//
//  Router.swift
//  I AM Sober
//
//  Lightweight cross-tab navigation. Lets the teaching screen jump to a
//  specific journal entry by setting `pendingJournalDate` and switching
//  to the journal tab. The journal tab consumes the pending date and
//  opens the matching entry, then clears it.
//

import Foundation

@Observable
final class Router {

    enum Tab: Hashable {
        case home
        case journal
        case favorites
        case settings
    }

    var selectedTab: Tab = .home

    /// Set by the teaching screen when the user taps "Reflect in Journal".
    /// `JournalListView` watches this and pushes the matching entry view.
    var pendingJournalDate: Date?

    /// When true, SettingsView should auto-scroll to the Daily Reminder section.
    var scrollToNotifications = false

    /// When true, the congratulations sheet is shown over the Today tab.
    var showCongratulations = false

    /// Toggled each time the user taps the Today tab while already on it.
    /// TeachingView watches this to snap the pager back to the current day.
    var returnToTodayTrigger = false

    func openJournal(for date: Date) {
        pendingJournalDate = date
        selectedTab = .journal
    }
}
