//
//  JournalEntryView.swift
//  I AM Sober
//
//  Detail view for a single day's journal entry. Loads (or creates) the
//  entry for `date`, shows the teaching that prompted it as a collapsible
//  reminder at the top, then a full-screen editor with the reflection
//  prompt as placeholder text. A camera/photo button at the bottom lets
//  the user attach (or replace) one image.
//

import SwiftUI
import PhotosUI
import SwiftData

struct JournalEntryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @State private var entry: JournalEntry?
    @State private var bodyText: String = ""
    @State private var attachedImage: UIImage?
    @State private var teachingExpanded: Bool = false

    @State private var showingPhotoMenu = false
    @State private var showingCamera = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoJiggling = false

    @FocusState private var editorFocused: Bool

    var body: some View {
        let teaching = appState.scheduler.teaching(for: date)

        ZStack {
            Theme.parchmentBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    teachingReminder(teaching: teaching)

                    promptHint(teaching.reflection)

                    editor(for: teaching)

                    if let attachedImage {
                        attachedPhoto(attachedImage)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, Theme.pageHorizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .onTapGesture {
                editorFocused = false
            }
        }
        .toolbarBackground(Theme.parchmentLight, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingPhotoMenu = true
                } label: {
                    Image(systemName: attachedImage == nil ? "camera" : "camera.fill")
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .foregroundStyle(Theme.inkSecondary)
                .fontWeight(.semibold)
            }
        }
        .confirmationDialog("Add a photo", isPresented: $showingPhotoMenu, titleVisibility: .hidden) {
            Button("Take a Photo") { showingCamera = true }
            PhotosPicker(
                "Choose from Library",
                selection: $pickerItem,
                matching: .images,
                photoLibrary: .shared()
            )
            if attachedImage != nil {
                Button("Remove Photo", role: .destructive) {
                    removePhoto()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(image: $attachedImage)
                .ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        attachedImage = image
                    }
                }
            }
        }
        .onAppear { loadEntry() }
        .onDisappear { save() }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date, format: .dateTime.weekday(.wide))
                .font(Theme.smallCaps())
                .textCase(.uppercase)
                .tracking(2.4)
                .foregroundStyle(Theme.inkFaded)

            Text(date, format: .dateTime.month(.wide).day().year())
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)
        }
    }

    private func teachingReminder(teaching: Teaching) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { teachingExpanded.toggle() }
            } label: {
                HStack {
                    Text("TODAY'S TEACHING")
                        .font(Theme.smallCaps(10))
                        .tracking(2.6)
                        .foregroundStyle(Theme.inkFaded)
                    Spacer()
                    Image(systemName: teachingExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkFaded)
                }
            }
            .buttonStyle(.plain)

            if teachingExpanded {
                Text(teaching.body)
                    .font(Theme.body(17))
                    .lineSpacing(7)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.parchmentShadow.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.accentGold.opacity(0.30), lineWidth: 0.6)
        )
    }

    private func promptHint(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TO REFLECT ON")
                .font(Theme.smallCaps(10))
                .tracking(2.6)
                .foregroundStyle(Theme.inkFaded)
            Text(text)
                .font(Theme.bodyItalic(16))
                .lineSpacing(5)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func editor(for teaching: Teaching) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(teaching.journalPrompt)
                .font(Theme.body(20))
                .foregroundStyle(Theme.ink)

            ZStack(alignment: .topLeading) {
                // Hidden sizing text — mirrors the editor content so the
                // frame grows/shrinks dynamically with the actual text.
                // The 2-line minimum keeps the field from collapsing to zero.
                Text(bodyText.isEmpty ? " \n " : bodyText + " ")
                    .font(Theme.body(17))
                    .lineSpacing(6)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(0)

                if bodyText.isEmpty {
                    Text("Write your thoughts here...")
                        .font(Theme.body(17))
                        .foregroundStyle(Theme.inkFaded.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $bodyText)
                    .focused($editorFocused)
                    .font(Theme.body(17))
                    .lineSpacing(6)
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.parchmentShadow.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.accentGold.opacity(0.20), lineWidth: 0.6)
            )
        }
        .padding(.top, 8)
    }

    private func attachedPhoto(_ image: UIImage) -> some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.accentGold.opacity(0.35), lineWidth: 0.6)
                )
                .shadow(color: Theme.ink.opacity(0.3), radius: 8, x: 0, y: 4)
                .shadow(color: Theme.parchmentShadow.opacity(0.2), radius: 3, x: 0, y: 2)
                .rotationEffect(photoJiggling ? .degrees(0.8) : .degrees(-0.8))
                .animation(
                    photoJiggling
                        ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                        : .default,
                    value: photoJiggling
                )
                .onLongPressGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation { photoJiggling = true }
                }
                .onTapGesture {
                    if photoJiggling {
                        withAnimation { photoJiggling = false }
                    }
                }

            // Delete badge — appears when jiggling
            if photoJiggling {
                Button {
                    withAnimation(.snappy) {
                        photoJiggling = false
                        removePhoto()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .offset(x: -8, y: -8)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Persistence

    private func loadEntry() {
        let key = JournalEntry.dateKey(for: Calendar.current.startOfDay(for: date))
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.dateKey == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            entry = existing
            bodyText = existing.body
            if let filename = existing.photoFilename {
                attachedImage = PhotoStorage.load(filename)
            }
        }
    }

    private func save() {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasContent = !trimmed.isEmpty || attachedImage != nil

        if let existing = entry {
            // Update existing
            if !hasContent {
                // User cleared everything — delete the entry and its photo.
                if let filename = existing.photoFilename {
                    PhotoStorage.delete(filename)
                }
                modelContext.delete(existing)
                entry = nil
                try? modelContext.save()
                return
            }

            // Photo handling: write a new file only if the image actually
            // changed (we detect this by checking whether the current file
            // can still load to the same instance — simpler heuristic: if
            // there's an attached image but no filename, save it; if the
            // user removed the image, delete the file).
            if attachedImage == nil, let filename = existing.photoFilename {
                PhotoStorage.delete(filename)
                existing.photoFilename = nil
            } else if let image = attachedImage, existing.photoFilename == nil {
                if let filename = try? PhotoStorage.save(image) {
                    existing.photoFilename = filename
                }
            } else if let image = attachedImage,
                      let oldFilename = existing.photoFilename,
                      PhotoStorage.load(oldFilename) !== image {
                // User picked a different image — replace the file.
                PhotoStorage.delete(oldFilename)
                if let newFilename = try? PhotoStorage.save(image) {
                    existing.photoFilename = newFilename
                }
            }

            existing.body = trimmed
            existing.updatedAt = Date()
        } else if hasContent {
            // Create new
            var photoFilename: String?
            if let image = attachedImage {
                photoFilename = try? PhotoStorage.save(image)
            }
            let teachingId = appState.scheduler.teaching(for: date).id
            let newEntry = JournalEntry(
                date: date,
                teachingId: teachingId,
                body: trimmed,
                photoFilename: photoFilename
            )
            modelContext.insert(newEntry)
            entry = newEntry
        }

        try? modelContext.save()
    }

    private func removePhoto() {
        attachedImage = nil
    }
}
