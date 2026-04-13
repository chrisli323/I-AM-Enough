//
//  TeachingScheduler.swift
//  I AM Sober
//
//  Maps a calendar date to the teaching the user should see.
//
//  Two pools:
//
//  1. **Milestones** — Day 1, 7, 14, 30, then every 30 days up to 365.
//     These are tied to the user's personal day number (resettable) and
//     contain day-specific language ("Thirty days. Look at what you have
//     done."). When the user resets Day 1, milestones reset with it.
//
//  2. **General pool** — All other days. No day-specific language. Rotated
//     using the permanent `firstOpenDate` so the user never sees repeats,
//     even across resets.
//
//  The scheduler checks milestones first. If today's personal day number
//  matches a milestone, that teaching is returned. Otherwise the general
//  pool is used.
//

import Foundation

struct TeachingScheduler {

    let store: TeachingStore
    let preferences: UserPreferences
    var calendar: Calendar = .current

    /// The teaching to show on the given date.
    ///
    /// Logic:
    /// 1. Compute the user's personal day number (resettable).
    /// 2. If a milestone exists for that day number, return it.
    /// 3. Otherwise, pull from the general pool using the permanent
    ///    install-date counter (never repeats across resets).
    func teaching(for date: Date = Date()) -> Teaching {
        let dayNumber = personalDayNumber(for: date)

        // Check milestones first
        if let milestone = store.milestone(for: dayNumber) {
            return milestone
        }

        // General pool — indexed by days since install
        let index = generalPoolIndex(for: date)
        return store.teaching(at: index)
    }

    /// Zero-based index into the general pool for the given date.
    /// Driven by `firstOpenDate` (permanent), so resets don't cause repeats.
    func generalPoolIndex(for date: Date) -> Int {
        let count = max(store.count, 1)
        let start = calendar.startOfDay(for: preferences.firstOpenDate)
        let today = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return ((days % count) + count) % count
    }

    /// The 1-based "Day N" label shown to the user. Driven by the user-
    /// resettable `personalDayOneDate`, so it can reset without affecting
    /// the general pool rotation.
    func personalDayNumber(for date: Date = Date()) -> Int {
        let start = calendar.startOfDay(for: preferences.personalDayOneDate)
        let today = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(days + 1, 1)
    }
}
