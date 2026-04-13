//
//  FavoritesView.swift
//  I AM Sober
//
//  Lists all favorited teachings, most recently saved first.
//  Tapping a row expands it to show the full teaching text.
//  Swipe to delete removes the favorite.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FavoriteTeaching.savedAt, order: .reverse)
    private var favorites: [FavoriteTeaching]

    @State private var expandedId: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.parchmentBackground

                ScrollViewReader { _ in
                    ScrollView {
                        if favorites.isEmpty {
                            emptyState
                                .padding(.top, 80)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(favorites) { favorite in
                                    favoriteRow(favorite)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .toolbarBackground(Theme.parchmentLight, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Favorites")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 44, design: .serif))
                .foregroundStyle(Theme.inkFaded)
            Text("No favorites yet.")
                .font(Theme.body(20))
                .foregroundStyle(Theme.inkSecondary)
            Text("Tap the heart on any teaching to save it here.")
                .font(Theme.bodyItalic(16))
                .foregroundStyle(Theme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    private func favoriteRow(_ favorite: FavoriteTeaching) -> some View {
        let teaching = appState.teachingStore.teaching(at: favorite.teachingId - 1)
        let isExpanded = expandedId == favorite.teachingId

        return Button {
            withAnimation(.snappy) {
                expandedId = isExpanded ? nil : favorite.teachingId
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(favorite.savedAt, format: .dateTime.month(.abbreviated).day().year())
                            .font(Theme.smallCaps(9))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.inkFaded)

                        Text(teaching.body)
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(isExpanded ? nil : 3)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Button {
                        withAnimation(.snappy) {
                            modelContext.delete(favorite)
                            try? modelContext.save()
                        }
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Rectangle()
                            .fill(Theme.accentGold.opacity(0.3))
                            .frame(height: 0.5)

                        Text("TO CARRY WITH YOU")
                            .font(Theme.smallCaps(9))
                            .tracking(2.4)
                            .foregroundStyle(Theme.inkFaded)

                        Text(teaching.reflection)
                            .font(Theme.bodyItalic(14))
                            .lineSpacing(5)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.parchmentLight.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.accentGold.opacity(0.30), lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
    }
}
