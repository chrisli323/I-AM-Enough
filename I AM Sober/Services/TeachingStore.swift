//
//  TeachingStore.swift
//  I AM Sober
//
//  Loads the bundled teachings.json (general pool) and milestones.json
//  (day-specific milestone teachings) once at launch. The scheduler
//  checks milestones first, then falls back to the general pool.
//

import Foundation

@Observable
final class TeachingStore {

    /// General teachings — no day-specific language. Rotated based on
    /// install date so the user never sees repeats.
    private(set) var teachings: [Teaching] = []

    /// Milestone teachings keyed by personal day number (1, 7, 14, 30, etc.).
    /// These reference the milestone directly and are tied to the user's
    /// personal journey, not the install date.
    private(set) var milestones: [Int: Teaching] = [:]

    init() {
        loadTeachings()
        loadMilestones()
    }

    var count: Int { teachings.count }

    func teaching(at index: Int) -> Teaching {
        guard !teachings.isEmpty else { return Self.fallback }
        let wrapped = ((index % teachings.count) + teachings.count) % teachings.count
        return teachings[wrapped]
    }

    /// Returns the milestone teaching for the given personal day number,
    /// or nil if no milestone exists for that day.
    func milestone(for dayNumber: Int) -> Teaching? {
        milestones[dayNumber]
    }

    // MARK: - Loading

    private func loadTeachings() {
        guard let url = Bundle.main.url(forResource: "teachings", withExtension: "json") else {
            assertionFailure("teachings.json missing from bundle")
            teachings = [Self.fallback]
            return
        }
        do {
            let data = try Data(contentsOf: url)
            teachings = try JSONDecoder().decode([Teaching].self, from: data)
        } catch {
            assertionFailure("Failed to decode teachings.json: \(error)")
            teachings = [Self.fallback]
        }
    }

    private func loadMilestones() {
        guard let url = Bundle.main.url(forResource: "milestones", withExtension: "json") else {
            // Milestones are optional during development
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([MilestoneEntry].self, from: data)
            for entry in entries {
                milestones[entry.day] = Teaching(
                    id: -entry.day, // negative IDs distinguish milestones
                    body: entry.body,
                    reflection: entry.reflection,
                    journalPrompt: entry.journalPrompt ?? "What is present in you today that deserves to be written down?"
                )
            }
        } catch {
            assertionFailure("Failed to decode milestones.json: \(error)")
        }
    }

    private static let fallback = Teaching(
        id: 0,
        body: "Take one full breath. You are here. That alone is enough for this moment.",
        reflection: "Whatever today holds, return to the breath. It is always available.",
        journalPrompt: "What are you feeling right now, in this moment, without any need to explain or justify it?"
    )
}

// MARK: - Milestone JSON shape

private struct MilestoneEntry: Codable {
    let day: Int
    let body: String
    let reflection: String
    let journalPrompt: String?
}
