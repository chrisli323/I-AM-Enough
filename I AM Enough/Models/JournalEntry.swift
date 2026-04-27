//
//  JournalEntry.swift
//  I AM Sober
//
//  One entry per calendar day, persisted via SwiftData on-device. The
//  `dateKey` is a "yyyy-MM-dd" string used to enforce one-per-day and to
//  do fast lookups by date. Photos are stored as files in the app's
//  sandbox; only the filename lives in the database.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {

    /// "yyyy-MM-dd" — guarantees one entry per local calendar day.
    @Attribute(.unique) var dateKey: String

    /// The exact moment the day began (start-of-day in local time). Used
    /// for sorting and for displaying the date.
    var date: Date

    /// Which teaching prompted this entry — useful for showing the
    /// teaching above the editor when the user revisits an old entry.
    var teachingId: Int

    /// The user's writing. May be empty if they only attached a photo.
    var body: String

    /// Legacy single-photo filename — kept for migration only. New entries
    /// use `photoFilenames` instead.
    var photoFilename: String?

    /// Filenames (not full paths) of all attached photos. Replaces
    /// `photoFilename` for entries created after multi-photo support.
    var photoFilenames: [String] = []

    var createdAt: Date
    var updatedAt: Date

    init(date: Date, teachingId: Int, body: String = "", photoFilename: String? = nil) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        self.dateKey = JournalEntry.dateKey(for: startOfDay)
        self.date = startOfDay
        self.teachingId = teachingId
        self.body = body
        self.photoFilename = photoFilename
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }

    /// Returns true if the entry has nothing the user actually wrote or
    /// attached. Used to decide whether to keep or delete on save.
    var isEmpty: Bool {
        body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && photoFilename == nil
            && photoFilenames.isEmpty
    }

    /// Stable date key formatter — POSIX locale + yyyy-MM-dd so it never
    /// drifts with the user's region.
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
