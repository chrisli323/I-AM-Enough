//
//  CompletedChallenge.swift
//  I AM Sober
//
//  SwiftData model for a completed intention challenge. Persists each
//  finished goal so the My Achievements section can display earned badges.
//

import SwiftUI
import SwiftData

// MARK: - Badge Tier

enum BadgeTier {
    case bronze, silver, gold, platinum

    /// Assign tier based on challenge duration.
    /// Bronze: 1–13 days  |  Silver: 14–59 days  |  Gold: 60–364 days  |  Platinum: 365+ days
    static func tier(for days: Int) -> BadgeTier {
        if days >= 365 { return .platinum }
        if days >= 60  { return .gold }
        if days >= 14  { return .silver }
        return .bronze
    }

    var name: String {
        switch self {
        case .bronze:   "Bronze"
        case .silver:   "Silver"
        case .gold:     "Gold"
        case .platinum: "Platinum"
        }
    }

    /// Primary (darker) tier colour
    var primaryColor: Color {
        switch self {
        case .bronze:   Color(red: 0.65, green: 0.38, blue: 0.14)
        case .silver:   Color(red: 0.52, green: 0.52, blue: 0.56)
        case .gold:     Color(red: 0.76, green: 0.57, blue: 0.06)
        case .platinum: Color(red: 0.68, green: 0.73, blue: 0.90)
        }
    }

    /// Highlight (lighter) tier colour — used for gradients
    var highlightColor: Color {
        switch self {
        case .bronze:   Color(red: 0.88, green: 0.62, blue: 0.34)
        case .silver:   Color(red: 0.88, green: 0.88, blue: 0.92)
        case .gold:     Color(red: 0.97, green: 0.84, blue: 0.32)
        case .platinum: Color(red: 0.96, green: 0.97, blue: 1.00)
        }
    }

    /// Electric glow colour for the platinum animated halo
    var glowColor: Color {
        switch self {
        case .platinum: Color(red: 0.42, green: 0.56, blue: 0.98)
        default:        primaryColor.opacity(0.5)
        }
    }

    var shadowColor: Color { primaryColor.opacity(0.35) }
}

// MARK: - Model

@Model
final class CompletedChallenge {

    var days: Int
    var completedAt: Date
    var goalName: String

    init(days: Int, goalName: String = "", completedAt: Date = Date()) {
        self.days = days
        self.goalName = goalName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.completedAt = completedAt
    }

    // MARK: Computed

    var tier: BadgeTier { BadgeTier.tier(for: days) }

    /// Human-readable challenge label matching IntentionSetupSheet options.
    var label: String {
        switch days {
        case 1:   return "1 Day"
        case 7:   return "1 Week"
        case 14:  return "2 Weeks"
        case 21:  return "3 Weeks"
        case 365: return "1 Year"
        default:  return "\(days) Days"
        }
    }
}
