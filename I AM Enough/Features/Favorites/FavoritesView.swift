//
//  FavoritesView.swift
//  I AM Sober
//
//  Lists all favorited teachings, most recently saved first.
//  Tapping a row expands it to show the full teaching text.
//  Swipe left, long-press, or tap the heart to remove a favorite —
//  all three paths require a confirmation alert before deletion.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FavoriteTeaching.savedAt, order: .reverse)
    private var favorites: [FavoriteTeaching]

    @State private var expandedId: Int?
    @State private var favoriteToDelete: FavoriteTeaching? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.parchmentBackground
                    .ignoresSafeArea()

                if favorites.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(favorites) { favorite in
                            favoriteRow(favorite)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 7, leading: 20, bottom: 7, trailing: 20))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        favoriteToDelete = favorite
                                    } label: {
                                        Label("Remove", systemImage: "heart.slash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        favoriteToDelete = favorite
                                    } label: {
                                        Label("Remove Favorite", systemImage: "heart.slash")
                                    }
                                }
                        }

                        // Bottom breathing room
                        Color.clear
                            .frame(height: 10)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .padding(.top, 10)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Favorites")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.ink)
                }
            }
            .alert("Remove Favorite?", isPresented: Binding(
                get: { favoriteToDelete != nil },
                set: { if !$0 { favoriteToDelete = nil } }
            )) {
                Button("Remove", role: .destructive) {
                    if let fav = favoriteToDelete {
                        withAnimation(.snappy) {
                            modelContext.delete(fav)
                            try? modelContext.save()
                        }
                    }
                    favoriteToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    favoriteToDelete = nil
                }
            } message: {
                Text("This teaching will be removed from your favorites.")
            }
        }
    }

    // MARK: - Subviews

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
        // Milestone teachings have negative IDs (id = -dayNumber).
        // General teachings have positive IDs (1-based array position).
        let teaching: Teaching = {
            if favorite.teachingId < 0 {
                let dayNumber = -favorite.teachingId
                return appState.teachingStore.milestone(for: dayNumber)
                    ?? appState.teachingStore.teaching(at: 0)
            } else {
                return appState.teachingStore.teaching(at: favorite.teachingId - 1)
            }
        }()
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

                    // Heart button — routes through the confirmation alert
                    Button {
                        favoriteToDelete = favorite
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
