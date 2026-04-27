//
//  CameraPicker.swift
//  I AM Sober
//
//  UIImagePickerController wrapper for camera capture.
//  Each shot is normalised (orientation collapsed) and appended to the
//  shared images array — the caller keeps the picker open by re-presenting
//  it; there is no in-session multi-shot mechanism inside this wrapper.
//

import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    /// Newly captured images are appended here.
    @Binding var images: [UIImage]
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let raw = info[.originalImage] as? UIImage {
                parent.images.append(normalized(raw))
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        /// Collapse imageOrientation into the pixel data so the image
        /// always displays upright and un-mirrored regardless of which
        /// camera or orientation was used.
        private func normalized(_ image: UIImage) -> UIImage {
            guard image.imageOrientation != .up else { return image }
            let renderer = UIGraphicsImageRenderer(size: image.size)
            return renderer.image { _ in image.draw(at: .zero) }
        }
    }
}
