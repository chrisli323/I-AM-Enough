//
//  PhotoStorage.swift
//  I AM Sober
//
//  On-device photo storage for journal entries. Images are written into
//  Application Support/JournalPhotos/ as JPEGs, never copied to the
//  shared photo library, never uploaded anywhere. The directory is
//  included in standard iCloud Backup so photos survive a device
//  restore or reinstall.
//
//  Photos are downscaled before saving to keep storage footprint light.
//

import UIKit

enum PhotoStorage {

    /// Maximum dimension (in pixels) any saved image is downscaled to.
    private static let maxDimension: CGFloat = 1200
    /// JPEG compression quality.
    private static let jpegQuality: CGFloat = 0.75

    // MARK: - Public API

    /// Saves an image to disk and returns the filename to store in the
    /// journal entry. Throws if the image can't be encoded.
    static func save(_ image: UIImage) throws -> String {
        let directory = try ensureDirectory()
        let filename = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)

        let resized = downscale(image, maxDimension: maxDimension)
        guard let data = resized.jpegData(compressionQuality: jpegQuality) else {
            throw PhotoStorageError.encodingFailed
        }
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return filename
    }

    /// Loads an image previously saved by `save(_:)`.
    static func load(_ filename: String) -> UIImage? {
        guard let url = url(for: filename),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Removes a saved image. Silently ignores missing files.
    static func delete(_ filename: String) {
        guard let url = url(for: filename) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Full URL for a saved photo, or nil if the directory can't be
    /// resolved.
    static func url(for filename: String) -> URL? {
        guard let directory = try? ensureDirectory() else { return nil }
        return directory.appendingPathComponent(filename)
    }

    // MARK: - Private

    private static func ensureDirectory() throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
		let directory = appSupport.appendingPathComponent("JournalPhotos", isDirectory: true)
        if !fm.fileExists(atPath: directory.path) {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum PhotoStorageError: Error {
    case encodingFailed
}
