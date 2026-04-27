//
//  CameraPicker.swift
//  I AM Sober
//
//  UIImagePickerController wrapper for camera capture.
//
//  Front-camera flip fix: iOS 16+ returns front-camera photos with
//  .up orientation but the pixel data is already horizontally mirrored
//  in the buffer. Older iOS returns .leftMirrored orientation and lets
//  draw(in:) apply the flip. We handle both cases explicitly:
//    • orientation != .up  → draw(in:) collapses orientation (incl. mirror)
//    • orientation == .up + front camera → draw(in:) + explicit horizontal flip
//  This guarantees the saved image always matches the camera preview.
//

import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
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
                let isFront = picker.cameraDevice == .front
                parent.images.append(corrected(raw, frontCamera: isFront))
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        /// Produces a pixel-correct, orientation-up image that matches the
        /// camera preview regardless of iOS version or camera position.
        private func corrected(_ image: UIImage, frontCamera: Bool) -> UIImage {
            let size = image.size

            // Step 1 — collapse imageOrientation into the pixel data.
            // UIImage.draw(in:) applies the stored orientation transform,
            // so the result is always orientation .up.
            UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: size))
            let upright = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()

            // Step 2 — handle the iOS 16+ front-camera case.
            // On older iOS the image arrived as .leftMirrored, so step 1
            // already applied the mirror. On iOS 16+ it arrives as .up
            // with pre-mirrored pixels, so step 1 left them mirrored and
            // we must flip explicitly to match the preview.
            guard frontCamera && image.imageOrientation == .up else {
                return upright
            }

            UIGraphicsBeginImageContextWithOptions(size, false, upright.scale)
            let ctx = UIGraphicsGetCurrentContext()!
            // Flip horizontally: translate to right edge, then scale x by -1.
            ctx.translateBy(x: size.width, y: 0)
            ctx.scaleBy(x: -1, y: 1)
            upright.draw(in: CGRect(origin: .zero, size: size))
            let flipped = UIGraphicsGetImageFromCurrentImageContext() ?? upright
            UIGraphicsEndImageContext()
            return flipped
        }
    }
}
