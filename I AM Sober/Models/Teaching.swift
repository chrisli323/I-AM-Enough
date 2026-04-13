//
//  Teaching.swift
//  I AM Sober
//

import Foundation

/// A single daily teaching. Intentionally minimal: no title, no category,
/// no addiction label — just a piece of writing that stands on its own,
/// plus a short reflection prompt the user can carry through their day
/// and respond to in their journal.
struct Teaching: Identifiable, Codable, Hashable {
    /// Stable identifier. Also used as the 1-based position in the library.
    let id: Int
    /// The main body of the teaching.
    let body: String
    /// A short (1–2 sentence) prompt to anchor the day's thought — always
    /// question- or anchor-shaped, always inward-pointing. Rendered as the
    /// placeholder text in the journal entry for this day.
    let reflection: String
}
