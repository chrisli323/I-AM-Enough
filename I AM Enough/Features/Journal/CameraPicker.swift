//
//  CameraPicker.swift
//  I AM Sober
//
//  UIImagePickerController wrapper for camera capture.
//
//  The raw image from UIImagePickerController already carries the correct
//  imageOrientation metadata. SwiftUI's Image(uiImage:) reads that metadata
//  and renders it correctly — identical to the native Camera app — so we
//  pass the image through untouched. PhotoStorage.downscale() normalises
//  orientation into the pixel data when the image is written to disk.
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
            // Pass the image through unchanged. imageOrientation metadata is
            // intact; SwiftUI and PhotoStorage both read it correctly.
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
