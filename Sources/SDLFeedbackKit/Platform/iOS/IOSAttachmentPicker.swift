#if os(iOS)
import Foundation
import PhotosUI
import SwiftUI
import UIKit

struct PlatformAttachmentPickerView: UIViewControllerRepresentable {
    let onOutcome: (AttachmentPickerOutcome) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onOutcome: onOutcome)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.filter = .images
            configuration.selectionLimit = 1

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = context.coordinator
            return picker
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.image"]
            picker.delegate = context.coordinator
            picker.allowsEditing = false
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {
        private let onOutcome: (AttachmentPickerOutcome) -> Void
        private var hasCompleted = false

        init(onOutcome: @escaping (AttachmentPickerOutcome) -> Void) {
            self.onOutcome = onOutcome
        }

        @available(iOS 14.0, *)
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !hasCompleted else { return }
            hasCompleted = true

            guard let result = results.first else {
                complete(.cancelled)
                return
            }

            let provider = result.itemProvider
            Task {
                let outcome = await Self.loadData(from: provider)
                await MainActor.run {
                    self.complete(outcome)
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            guard !hasCompleted else { return }
            hasCompleted = true
            picker.dismiss(animated: true)
            complete(.cancelled)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard !hasCompleted else { return }
            hasCompleted = true

            if let url = info[.imageURL] as? URL {
                do {
                    let data = try Data(contentsOf: url)
                    picker.dismiss(animated: true)
                    complete(.selected(data))
                } catch {
                    picker.dismiss(animated: true)
                    complete(.failed(.attachmentProcessingFailed))
                }
                return
            }

            if let image = info[.originalImage] as? UIImage {
                let data = image.jpegData(compressionQuality: 1.0) ?? image.pngData()
                picker.dismiss(animated: true)
                if let data {
                    complete(.selected(data))
                } else {
                    complete(.failed(.attachmentProcessingFailed))
                }
                return
            }

            picker.dismiss(animated: true)
            complete(.failed(.unsupportedAttachment))
        }

        private func complete(_ outcome: AttachmentPickerOutcome) {
            onOutcome(outcome)
        }

        @available(iOS 14.0, *)
        private static func loadData(from provider: NSItemProvider) async -> AttachmentPickerOutcome {
            guard provider.hasItemConformingToTypeIdentifier("public.image") else {
                return .failed(.unsupportedAttachment)
            }

            do {
                let data = try await withCheckedThrowingContinuation { continuation in
                    provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                        if let data {
                            continuation.resume(returning: data)
                        } else if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(throwing: FeedbackError.attachmentProcessingFailed)
                        }
                    }
                }
                return .selected(data)
            } catch {
                return .failed(.attachmentProcessingFailed)
            }
        }
    }
}
#endif
