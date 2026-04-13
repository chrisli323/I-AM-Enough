//
//  JournalListView.swift
//  I AM Sober
//
//  Reverse-chronological list of journal entries. Days with no entry are
//  intentionally absent — we don't want this to feel like a streak chart
//  the user is failing at. The "+" button creates today's entry.
//
//  Watches Router.pendingJournalDate so the teaching screen can deep-link
//  into a specific day's entry by switching to this tab.
//

import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \JournalEntry.date, order: .reverse)
    private var entries: [JournalEntry]

    @State private var path = NavigationPath()

    var body: some View {
        @Bindable var router = appState.router

        NavigationStack(path: $path) {
            ZStack {
                Theme.parchmentBackground

                ScrollViewReader { _ in
                    ScrollView {
                        if entries.isEmpty {
                            emptyState
                                .padding(.top, 80)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(entries) { entry in
                                    Button {
                                        path.append(entry.date)
                                    } label: {
                                        JournalEntryRow(entry: entry)
                                    }
                                    .buttonStyle(.plain)
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
                    Text("Journal")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.ink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append(Date())
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }
            .navigationDestination(for: Date.self) { date in
                JournalEntryView(date: date)
            }
        }
        .onChange(of: router.pendingJournalDate) { _, newValue in
            if let date = newValue {
                path = NavigationPath()
                path.append(date)
                router.pendingJournalDate = nil
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 44, design: .serif))
                .foregroundStyle(Theme.inkFaded)
            Text("Your journal is waiting.")
                .font(Theme.body(20))
                .foregroundStyle(Theme.inkSecondary)
            Text("Reflect on today's teaching to begin.")
                .font(Theme.bodyItalic(16))
                .foregroundStyle(Theme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

}

// MARK: - Row

private struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            dateBlock

            VStack(alignment: .leading, spacing: 6) {
                if !entry.body.isEmpty {
                    Text(entry.body)
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                } else if entry.photoFilename != nil {
                    Text("(Photo entry)")
                        .font(Theme.bodyItalic(14))
                        .foregroundStyle(Theme.inkFaded)
                }

                Text(entry.date, format: .dateTime.weekday(.abbreviated))
                    .font(Theme.smallCaps(9))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.inkFaded)
            }

            Spacer(minLength: 0)

            if let filename = entry.photoFilename,
               let image = PhotoStorage.load(filename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.accentGold.opacity(0.35), lineWidth: 0.6)
                    )
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

    private var dateBlock: some View {
        VStack(spacing: 0) {
            Text(entry.date, format: .dateTime.day())
                .font(Theme.display(26))
                .foregroundStyle(Theme.ink)
            Text(entry.date, format: .dateTime.month(.abbreviated))
                .font(Theme.smallCaps(10))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Theme.inkFaded)
        }
        .frame(width: 48)
    }
}
