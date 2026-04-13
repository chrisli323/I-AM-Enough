//
//  FavoriteTeaching.swift
//  I AM Sober
//
//  SwiftData model for a favorited teaching. Stores the teaching ID
//  and the date it was saved so the favorites list can be displayed
//  chronologically.
//

import Foundation
import SwiftData

@Model
final class FavoriteTeaching {
    @Attribute(.unique) var teachingId: Int
    var savedAt: Date

    init(teachingId: Int, savedAt: Date = Date()) {
        self.teachingId = teachingId
        self.savedAt = savedAt
    }
}
