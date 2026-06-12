//
//  JournalEntryView.swift
//  I AM Sober
//
//  Detail view for a single day's journal entry. Supports multiple
//  attached photos — tap the camera icon to add more via the camera or
//  photo library. Long-press any photo to delete it or save it to the
//  camera roll.
//

import SwiftUI
import PhotosUI
import SwiftData
import Photos

struct JournalEntryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @State private var entry: JournalEntry?
    @State private var bodyText: String = ""

    /// Loaded / newly-captured images in display order.
    @State private var attachedImages: [UIImage] = []
    /// Parallel array of on-disk filenames. nil = not yet saved to disk.
    @State private var attachedFilenames: [String?] = []

    @State private var teachingExpanded: Bool = false
    @State private var showingPhotoMenu = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var pickerItems: [PhotosPickerItem] = []

    /// Index of the photo currently jiggling (only one at a time).
    @State private var jigglingIndex: Int? = nil
    /// Index of the photo showing the "Saved" toast.
    @State private var toastIndex: Int? = nil

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

                    sectionDivider

                    photoCaptureInvite

                    // Photos — stacked vertically, each with its own controls
                    ForEach(attachedImages.indices, id: \.self) { i in
                        attachedPhoto(at: i)
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
                if jigglingIndex != nil {
                    withAnimation { jigglingIndex = nil }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingPhotoMenu = true
                } label: {
                    Image(systemName: attachedImages.isEmpty ? "camera" : "camera.badge.plus")
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
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take a Photo") { showingCamera = true }
            }
            Button("Choose from Library") { showingPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: nil,
            matching: .images,
            photoLibrary: .shared()
        )
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(images: $attachedImages)
                .ignoresSafeArea()
        }
        .onChange(of: attachedImages.count) { old, new in
            // When camera appends a new image, extend filenames array with nil.
            if new > attachedFilenames.count {
                let added = new - attachedFilenames.count
                attachedFilenames.append(contentsOf: [String?](repeating: nil, count: added))
            }
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                var loaded: [UIImage] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        loaded.append(image)
                    }
                }
                await MainActor.run {
                    attachedImages.append(contentsOf: loaded)
                    attachedFilenames.append(contentsOf: [String?](repeating: nil, count: loaded.count))
                    pickerItems = []
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

    private var sectionDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Theme.accentGold.opacity(0.45))
                .frame(height: 0.6)
            Text("\u{2766}")
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(Theme.accentGold)
            Rectangle()
                .fill(Theme.accentGold.opacity(0.45))
                .frame(height: 0.6)
        }
        .padding(.vertical, 4)
    }

    private var photoCaptureInvite: some View {
        PhotoCaptureInviteCard { showingPhotoMenu = true }
    }

    @ViewBuilder
    private func attachedPhoto(at index: Int) -> some View {
        if index < attachedImages.count {
            let image = attachedImages[index]
            let isJiggling = jigglingIndex == index
            let showToast = toastIndex == index

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
                    .rotationEffect(isJiggling ? .degrees(0.8) : .degrees(-0.8))
                    .animation(
                        isJiggling
                            ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                            : .default,
                        value: isJiggling
                    )
                    .onLongPressGesture {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        withAnimation { jigglingIndex = index }
                    }
                    .onTapGesture {
                        if jigglingIndex != nil {
                            withAnimation { jigglingIndex = nil }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if showToast {
                            Label("Saved to Camera Roll", systemImage: "checkmark.circle.fill")
                                .font(Theme.smallCaps(11))
                                .tracking(0.8)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.55), in: Capsule())
                                .padding(.bottom, 14)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }

                // Delete badge — top-left
                if isJiggling {
                    Button {
                        withAnimation(.snappy) {
                            jigglingIndex = nil
                            removePhoto(at: index)
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

                // Save badge — top-right
                if isJiggling {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.snappy) { jigglingIndex = nil }
                            saveToCamera(image, index: index)
                        } label: {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color(red: 0.20, green: 0.55, blue: 0.30))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .offset(x: 8, y: -8)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private func saveToCamera(_ image: UIImage, index: Int) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else { return }
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                withAnimation(.easeInOut(duration: 0.3)) { toastIndex = index }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.easeInOut(duration: 0.4)) { toastIndex = nil }
                }
            }
        }
    }

    // MARK: - Persistence

    private func loadEntry() {
        let key = JournalEntry.dateKey(for: Calendar.current.startOfDay(for: date))
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.dateKey == key }
        )
        guard let existing = try? modelContext.fetch(descriptor).first else { return }
        entry = existing
        bodyText = existing.body

        // Migrate legacy single-photo to array format
        if let legacyFilename = existing.photoFilename, existing.photoFilenames.isEmpty {
            existing.photoFilenames = [legacyFilename]
            existing.photoFilename = nil
            try? modelContext.save()
        }

        // Load all photos
        var images: [UIImage] = []
        var filenames: [String?] = []
        for filename in existing.photoFilenames {
            if let img = PhotoStorage.load(filename) {
                images.append(img)
                filenames.append(filename)
            }
        }
        attachedImages = images
        attachedFilenames = filenames
    }

    private func save() {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasContent = !trimmed.isEmpty || !attachedImages.isEmpty

        if let existing = entry {
            if !hasContent {
                // Delete all photos and the entry
                for filename in existing.photoFilenames {
                    PhotoStorage.delete(filename)
                }
                modelContext.delete(existing)
                entry = nil
                try? modelContext.save()
                return
            }

            // Save any new (unsaved) images and collect all current filenames
            var savedFilenames: [String] = []
            for (i, image) in attachedImages.enumerated() {
                if let existingFilename = i < attachedFilenames.count ? attachedFilenames[i] : nil {
                    savedFilenames.append(existingFilename)
                } else {
                    if let filename = try? PhotoStorage.save(image) {
                        savedFilenames.append(filename)
                        if i < attachedFilenames.count {
                            attachedFilenames[i] = filename
                        }
                    }
                }
            }

            // Delete any files that were removed
            for oldFilename in existing.photoFilenames where !savedFilenames.contains(oldFilename) {
                PhotoStorage.delete(oldFilename)
            }

            existing.photoFilenames = savedFilenames
            existing.photoFilename = nil    // clear legacy field
            existing.body = trimmed
            existing.updatedAt = Date()

        } else if hasContent {
            // Save all photos for new entry
            var savedFilenames: [String] = []
            for (i, image) in attachedImages.enumerated() {
                if let filename = try? PhotoStorage.save(image) {
                    savedFilenames.append(filename)
                    if i < attachedFilenames.count {
                        attachedFilenames[i] = filename
                    }
                }
            }
            let teachingId = appState.scheduler.teaching(for: date).id
            let newEntry = JournalEntry(
                date: date,
                teachingId: teachingId,
                body: trimmed,
                photoFilename: nil
            )
            newEntry.photoFilenames = savedFilenames
            modelContext.insert(newEntry)
            entry = newEntry
        }

        try? modelContext.save()
    }

    private func removePhoto(at index: Int) {
        guard index < attachedImages.count else { return }
        attachedImages.remove(at: index)
        if index < attachedFilenames.count {
            attachedFilenames.remove(at: index)
        }
        // Adjust toast/jiggle indices
        if let t = toastIndex, t == index { toastIndex = nil }
        if let j = jigglingIndex, j == index { jigglingIndex = nil }
    }
}

// MARK: - Photo capture invite card

/// Standalone view so it can own the @State needed for the idle bob animation.
private struct PhotoCaptureInviteCard: View {
    let onTap: () -> Void
    @State private var bobbing = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: "camera.badge.plus")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Theme.inkSecondary)
                    .offset(y: bobbing ? -5 : 0)
                    .animation(
                        .easeInOut(duration: 1.15).repeatForever(autoreverses: true),
                        value: bobbing
                    )

                Text("CAPTURE YOUR JOY")
                    .font(Theme.smallCaps(10))
                    .tracking(2.6)
                    .foregroundStyle(Theme.inkFaded)

                Text("Photograph a happy moment, something that made you smile, or anything that brought you peace today.")
                    .font(Theme.bodyItalic(14))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.inkFaded.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.parchmentShadow.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                    )
                    .foregroundStyle(Theme.accentGold.opacity(0.45))
            )
        }
        .buttonStyle(ParchmentTapButtonStyle())
        .onAppear {
            // Small delay so it doesn't start mid-scroll-in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                bobbing = true
            }
        }
    }
}

// MARK: - Parchment tap button style

/// Dims and gently scales down on press — tactile feedback without
/// disrupting the dashed-border card layout.
private struct ParchmentTapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.60 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
