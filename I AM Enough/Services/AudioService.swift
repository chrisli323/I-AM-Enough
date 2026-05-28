//
//  AudioService.swift
//  I AM Sober
//
//  Manages ambient background audio on the teaching screen. Wraps
//  AVAudioPlayer with looping, volume control, and fade-in/out.
//  Respects the mute switch and ducks other audio.
//
//  Audio files live in Resources/Audio/. Each track is identified by
//  its filename (without extension). The service persists the user's
//  chosen track and volume via UserPreferences.
//

import AVFoundation
import Foundation

@Observable
final class AudioService {

    // MARK: - Public state

    var isEnabled: Bool {
        didSet {
            preferences.audioEnabled = isEnabled
            guard isReady else { return }
            isEnabled ? play() : stop()
        }
    }

    var volume: Float {
        didSet { preferences.audioVolume = volume; player?.volume = volume }
    }

    var selectedTrack: String {
        didSet {
            preferences.audioTrack = selectedTrack
            guard isReady else { return }
            reload()
        }
    }

    /// Names of available audio files discovered in the bundle.
    private(set) var availableTracks: [String] = []

    // MARK: - Private

    private var player: AVAudioPlayer?
    private let preferences: UserPreferences
    private var isReady = false

    // MARK: - Init

    init(preferences: UserPreferences) {
        self.preferences = preferences
        // Read saved values without triggering didSet (play).
        self.isEnabled = preferences.audioEnabled
        self.volume = preferences.audioVolume
        self.selectedTrack = preferences.audioTrack
        discoverTracks()
        // Don't configure session or play yet — wait for start().
    }

    /// Call once the UI is ready (after the splash screen) so audio
    /// doesn't stutter while the app is still loading resources.
    func start() {
        configureSession()
        isReady = true
        if isEnabled { play() }
    }

    // MARK: - Playback

    func play() {
        guard isEnabled else { return }
        guard player == nil else { player?.play(); return }
        reload()
    }

    func stop() {
        player?.stop()
        player = nil
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        guard isEnabled else { return }
        player?.play()
    }

    // MARK: - Private helpers

    private func reload() {
        player?.stop()
        player = nil
        guard isEnabled else { return }

        let trackName = availableTracks.contains(selectedTrack)
            ? selectedTrack
            : (availableTracks.first ?? selectedTrack)

        guard let url = audioURL(for: trackName) else { return }

        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1 // loop forever
            p.volume = volume
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            print("AudioService: failed to load \(trackName): \(error)")
        }
    }

    private func discoverTracks() {
        let extensions = ["m4a", "mp3", "wav"]
        var names: Set<String> = []
        for ext in extensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Audio") {
                for url in urls {
                    names.insert(url.deletingPathExtension().lastPathComponent)
                }
            }
            // Also check root Resources (no subdirectory)
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    let name = url.deletingPathExtension().lastPathComponent
                    // Only include files that look like ambient tracks
                    if name.lowercased().contains("ambient") ||
                       name.lowercased().contains("nature") ||
                       name.lowercased().contains("ocean") ||
                       name.lowercased().contains("rebirth") ||
                       name.lowercased().contains("dreams") ||
                       name.lowercased().contains("reflection") {
                        names.insert(name)
                    }
                }
            }
        }
        availableTracks = names.sorted()

        // If selected track isn't available, pick the first one
        if !availableTracks.contains(selectedTrack), let first = availableTracks.first {
            selectedTrack = first
        }
    }

    private func audioURL(for trackName: String) -> URL? {
        let extensions = ["m4a", "mp3", "wav"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: trackName, withExtension: ext, subdirectory: "Audio") {
                return url
            }
            if let url = Bundle.main.url(forResource: trackName, withExtension: ext, subdirectory: nil) {
                return url
            }
        }
        return nil
    }

    private func configureSession() {
        do {
            // .ambient respects the mute switch and mixes with other apps
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioService: failed to configure audio session: \(error)")
        }
    }
}
