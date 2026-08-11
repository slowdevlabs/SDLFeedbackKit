#if os(iOS)
import Foundation
import Photos
import PhotosUI
import SwiftUI
import UIKit

struct PlatformAttachmentPickerView: UIViewControllerRepresentable {
    let onSelectionAccepted: () -> Void
    let onOutcome: (AttachmentPickerOutcome) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectionAccepted: onSelectionAccepted, onOutcome: onOutcome)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.filter = .images
            configuration.selectionLimit = 1
            if let representationMode = Coordinator.diagnosticRepresentationMode() {
                configuration.preferredAssetRepresentationMode = representationMode
            }
            IOSAttachmentPickerDebugLog.log("picker.configuration.representationMode = \(Coordinator.diagnosticRepresentationModeDescription())")

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
        private let onSelectionAccepted: () -> Void
        private let onOutcome: (AttachmentPickerOutcome) -> Void
        private var hasCompleted = false

        init(
            onSelectionAccepted: @escaping () -> Void,
            onOutcome: @escaping (AttachmentPickerOutcome) -> Void
        ) {
            self.onSelectionAccepted = onSelectionAccepted
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
            Self.logProviderDiagnostics(provider)
            IOSAttachmentPickerDebugLog.log("picker.selectionAccepted")
            onSelectionAccepted()
            Task {
                let outcome = await Self.loadAttachment(from: provider)
                self.complete(outcome)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            guard !hasCompleted else { return }
            hasCompleted = true
            complete(.cancelled)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard !hasCompleted else { return }
            hasCompleted = true

            if let url = info[.imageURL] as? URL {
                IOSAttachmentPickerDebugLog.log("picker.selectionAccepted")
                onSelectionAccepted()
                do {
                    complete(.selectedFile(try Self.copyTemporaryFile(from: url)))
                } catch {
                    complete(.failed(.attachmentProcessingFailed))
                }
                return
            }

            if let image = info[.originalImage] as? UIImage {
                IOSAttachmentPickerDebugLog.log("picker.selectionAccepted")
                onSelectionAccepted()
                let data = image.jpegData(compressionQuality: 1.0) ?? image.pngData()
                if let data {
                    complete(.selected(data))
                } else {
                    complete(.failed(.attachmentProcessingFailed))
                }
                return
            }

            complete(.failed(.unsupportedAttachment))
        }

        private func complete(_ outcome: AttachmentPickerOutcome) {
            switch outcome {
            case .selected:
                IOSAttachmentPickerDebugLog.log("picker.outcome.selected")
            case .selectedFile:
                IOSAttachmentPickerDebugLog.log("picker.outcome.selectedFile")
            case .cancelled:
                IOSAttachmentPickerDebugLog.log("picker.outcome.cancelled")
            case .failed:
                IOSAttachmentPickerDebugLog.log("picker.outcome.failed")
            }
            onOutcome(outcome)
        }

        private static func copyTemporaryFile(from sourceURL: URL) throws -> URL {
            let fileExtension = sourceURL.pathExtension.isEmpty ? "img" : sourceURL.pathExtension
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("sdlfeedbackkit-\(UUID().uuidString)")
                .appendingPathExtension(fileExtension)

            try? FileManager.default.removeItem(at: temporaryURL)
            try FileManager.default.copyItem(at: sourceURL, to: temporaryURL)
            return temporaryURL
        }

        @available(iOS 14.0, *)
        private static func loadAttachment(from provider: NSItemProvider) async -> AttachmentPickerOutcome {
            let diagnosticConfiguration = AttachmentPickerDiagnosticConfiguration.current()
            IOSAttachmentPickerDebugLog.log("diagnostic.requestKind = \(diagnosticConfiguration.requestKind.rawValue)")

            let hasImage = provider.hasItemConformingToTypeIdentifier(AttachmentPickerImageTypeResolver.genericImageTypeIdentifier)
            guard hasImage else {
                IOSAttachmentPickerDebugLog.log("provider.hasImage = false")
                return .failed(.unsupportedAttachment)
            }

            IOSAttachmentPickerDebugLog.log("provider.hasImage = true")
            guard let resolution = Self.resolveImageType(
                for: provider,
                requestedTypeOverride: diagnosticConfiguration.requestedTypeOverride
            ) else {
                IOSAttachmentPickerDebugLog.log("provider.resolution.selected = nil")
                return .failed(.unsupportedAttachment)
            }

            IOSAttachmentPickerDebugLog.log("provider.resolvedType = \(resolution.identifier)")
            IOSAttachmentPickerDebugLog.log("provider.requestedType = \(resolution.identifier)")
            IOSAttachmentPickerDebugLog.log("provider.resolution.genericFallback = \(resolution.usedGenericFallback)")
            do {
                switch diagnosticConfiguration.requestKind {
                case .production:
                    if let url = try await loadTemporaryFile(from: provider, requestedType: resolution.identifier) {
                        return .selectedFile(url)
                    }

                    let data = try await loadDataRepresentation(from: provider, requestedType: resolution.identifier)
                    return .selected(data)
                case .file:
                    if let url = try await loadTemporaryFile(from: provider, requestedType: resolution.identifier) {
                        return .selectedFile(url)
                    }
                    return .failed(.attachmentProcessingFailed)
                case .data:
                    let data = try await loadDataRepresentation(from: provider, requestedType: resolution.identifier)
                    return .selected(data)
                }
            } catch {
                return .failed(.attachmentProcessingFailed)
            }
        }

        @available(iOS 14.0, *)
        private static func loadTemporaryFile(from provider: NSItemProvider, requestedType: String) async throws -> URL? {
            guard provider.hasItemConformingToTypeIdentifier(requestedType) else {
                return nil
            }

            let start = Date()
            IOSAttachmentPickerDebugLog.log("provider.file.load.started type=\(requestedType)")
            return try await withCheckedThrowingContinuation { continuation in
                provider.loadFileRepresentation(forTypeIdentifier: requestedType) { url, error in
                    let elapsed = Date().timeIntervalSince(start)
                    IOSAttachmentPickerDebugLog.log("provider.file.load.callback type=\(requestedType) elapsed=\(Self.formatElapsed(elapsed))")
                    if let url {
                        do {
                            let copiedURL = try copyTemporaryFile(from: url)
                            IOSAttachmentPickerDebugLog.log("provider.file.load.success type=\(requestedType) path=\(copiedURL.lastPathComponent)")
                            continuation.resume(returning: copiedURL)
                        } catch {
                            let nsError = error as NSError
                            IOSAttachmentPickerDebugLog.log(
                                "provider.file.load.error type=\(requestedType) errorDomain=\(nsError.domain) code=\(nsError.code)"
                            )
                            continuation.resume(throwing: error)
                        }
                    } else if let error {
                        let nsError = error as NSError
                        IOSAttachmentPickerDebugLog.log(
                            "provider.file.load.error type=\(requestedType) errorDomain=\(nsError.domain) code=\(nsError.code)"
                        )
                        continuation.resume(throwing: error)
                    } else {
                        IOSAttachmentPickerDebugLog.log("provider.file.load.nilURL type=\(requestedType)")
                        continuation.resume(throwing: FeedbackError.attachmentProcessingFailed)
                    }
                }
            }
        }

        @available(iOS 14.0, *)
        private static func loadDataRepresentation(from provider: NSItemProvider, requestedType: String) async throws -> Data {
            let start = Date()
            IOSAttachmentPickerDebugLog.log("provider.data.load.started type=\(requestedType)")
            return try await withCheckedThrowingContinuation { continuation in
                provider.loadDataRepresentation(forTypeIdentifier: requestedType) { data, error in
                    let elapsed = Date().timeIntervalSince(start)
                    IOSAttachmentPickerDebugLog.log("provider.data.load.callback type=\(requestedType) elapsed=\(Self.formatElapsed(elapsed))")
                    if let data {
                        IOSAttachmentPickerDebugLog.log("provider.data.load.success type=\(requestedType) bytes=\(data.count)")
                        continuation.resume(returning: data)
                    } else if let error {
                        let nsError = error as NSError
                        IOSAttachmentPickerDebugLog.log(
                            "provider.data.load.error type=\(requestedType) errorDomain=\(nsError.domain) code=\(nsError.code)"
                        )
                        continuation.resume(throwing: error)
                    } else {
                        let nsError = FeedbackError.attachmentProcessingFailed as NSError
                        IOSAttachmentPickerDebugLog.log("provider.data.load.error type=\(requestedType) errorDomain=\(nsError.domain) code=\(nsError.code)")
                        continuation.resume(throwing: FeedbackError.attachmentProcessingFailed)
                    }
                }
            }
        }

        private static func logProviderDiagnostics(_ provider: NSItemProvider) {
            let registeredTypes = provider.registeredTypeIdentifiers
            IOSAttachmentPickerDebugLog.log("provider.registeredTypes = \(registeredTypes)")
            let hasImage = provider.hasItemConformingToTypeIdentifier(AttachmentPickerImageTypeResolver.genericImageTypeIdentifier)
            IOSAttachmentPickerDebugLog.log("provider.hasImage = \(hasImage)")
            IOSAttachmentPickerDebugLog.log("provider.hasJPEG = \(provider.hasItemConformingToTypeIdentifier("public.jpeg"))")
            IOSAttachmentPickerDebugLog.log("provider.hasPNG = \(provider.hasItemConformingToTypeIdentifier("public.png"))")
            IOSAttachmentPickerDebugLog.log("provider.hasHEIC = \(provider.hasItemConformingToTypeIdentifier("public.heic"))")
            IOSAttachmentPickerDebugLog.log("provider.hasHEIF = \(provider.hasItemConformingToTypeIdentifier("public.heif"))")
            IOSAttachmentPickerDebugLog.log("provider.isLivePhoto = \(provider.canLoadObject(ofClass: PHLivePhoto.self))")
            let resolution = Self.resolveImageType(for: provider, requestedTypeOverride: AttachmentPickerDiagnosticConfiguration.current().requestedTypeOverride)
            IOSAttachmentPickerDebugLog.log("provider.resolution.candidate = \(resolution?.identifier ?? "nil")")
            IOSAttachmentPickerDebugLog.log("provider.resolution.selected = \(resolution?.identifier ?? "nil")")
            IOSAttachmentPickerDebugLog.log("provider.requestedType = \(resolution?.identifier ?? "nil")")
            IOSAttachmentPickerDebugLog.log("provider.resolution.genericFallback = \(resolution?.usedGenericFallback ?? false)")
        }

        private static func formatElapsed(_ elapsed: TimeInterval) -> String {
            String(format: "%.3f", elapsed)
        }

        private static func resolveImageType(
            for provider: NSItemProvider,
            requestedTypeOverride: String?
        ) -> AttachmentPickerImageTypeResolution? {
            if let requestedTypeOverride {
                guard provider.hasItemConformingToTypeIdentifier(requestedTypeOverride) else {
                    return nil
                }
                return AttachmentPickerImageTypeResolution(identifier: requestedTypeOverride, usedGenericFallback: requestedTypeOverride == AttachmentPickerImageTypeResolver.genericImageTypeIdentifier)
            }

            let resolution = AttachmentPickerImageTypeResolver.resolvePreferredImageType(
                from: provider.registeredTypeIdentifiers,
                hasImageConformance: provider.hasItemConformingToTypeIdentifier(AttachmentPickerImageTypeResolver.genericImageTypeIdentifier)
            )

            if let resolution {
                IOSAttachmentPickerDebugLog.log("provider.resolution.selected = \(resolution.identifier)")
            } else {
                IOSAttachmentPickerDebugLog.log("provider.resolution.selected = nil")
            }

            return resolution
        }

        @available(iOS 14.0, *)
        fileprivate static func diagnosticRepresentationMode() -> PHPickerConfiguration.AssetRepresentationMode? {
            switch AttachmentPickerDiagnosticConfiguration.current().representationMode {
            case .automatic:
                return .automatic
            case .current:
                return .current
            case .compatible:
                return .compatible
            case .defaultUnset:
                return nil
            }
        }

        fileprivate static func diagnosticRepresentationModeDescription() -> String {
            AttachmentPickerDiagnosticConfiguration.current().representationMode.rawValue
        }
    }
}

private enum IOSAttachmentPickerDebugLog {
    static func log(_ message: String) {
#if DEBUG
        print("[SDLFeedbackKit] \(message)")
#endif
    }
}
#endif
