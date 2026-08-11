import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

enum AttachmentPickerOutcome: Sendable {
    case selected(Data)
    case selectedFile(URL)
    case cancelled
    case failed(FeedbackError)
}

struct AttachmentPickerDiagnosticConfiguration: Sendable, Equatable {
    enum RepresentationMode: String, Sendable {
        case defaultUnset = "default-unset"
        case automatic
        case current
        case compatible
    }

    enum RequestKind: String, Sendable {
        case production
        case file
        case data
    }

    let representationMode: RepresentationMode
    let requestKind: RequestKind
    let requestedTypeOverride: String?

    static func current(environment: [String: String] = ProcessInfo.processInfo.environment) -> AttachmentPickerDiagnosticConfiguration {
#if DEBUG
        let representationMode = RepresentationMode(rawValue: environment["SDLFeedbackKitAttachmentRepresentationMode"]?.lowercased() ?? "") ?? .defaultUnset
        let requestKind = RequestKind(rawValue: environment["SDLFeedbackKitAttachmentRequestKind"]?.lowercased() ?? "") ?? .production
        let requestedTypeOverride = environment["SDLFeedbackKitAttachmentRequestedType"]
            .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }

        return AttachmentPickerDiagnosticConfiguration(
            representationMode: representationMode,
            requestKind: requestKind,
            requestedTypeOverride: requestedTypeOverride
        )
#else
        return AttachmentPickerDiagnosticConfiguration(
            representationMode: .defaultUnset,
            requestKind: .production,
            requestedTypeOverride: nil
        )
#endif
    }
}

struct AttachmentPickerImageTypeResolution: Sendable, Equatable {
    let identifier: String
    let usedGenericFallback: Bool
}

enum AttachmentPickerImageTypeResolver {
    static let genericImageTypeIdentifier = "public.image"
    private static let privatePhotoThumbnailPrefix = "com.apple.private.photos.thumbnail."
    private static let preferredConcreteImageTypeIdentifiers = [
        "public.heic",
        "public.heif",
        "public.png",
        "public.jpeg"
    ]

    static func resolvePreferredImageType(
        from registeredTypeIdentifiers: [String],
        hasImageConformance: Bool
    ) -> AttachmentPickerImageTypeResolution? {
        for preferredIdentifier in preferredConcreteImageTypeIdentifiers {
            guard registeredTypeIdentifiers.contains(preferredIdentifier) else {
                continue
            }
            guard isPreferredConcreteImageTypeIdentifier(preferredIdentifier) else {
                continue
            }
            return AttachmentPickerImageTypeResolution(identifier: preferredIdentifier, usedGenericFallback: false)
        }

        for identifier in registeredTypeIdentifiers {
            guard isPreferredConcreteImageTypeIdentifier(identifier) else {
                continue
            }
            return AttachmentPickerImageTypeResolution(identifier: identifier, usedGenericFallback: false)
        }

        guard hasImageConformance else {
            return nil
        }

        return AttachmentPickerImageTypeResolution(identifier: genericImageTypeIdentifier, usedGenericFallback: true)
    }

    static func isPreferredConcreteImageTypeIdentifier(_ identifier: String) -> Bool {
        guard identifier != genericImageTypeIdentifier else {
            return false
        }

        guard !identifier.hasPrefix(privatePhotoThumbnailPrefix) else {
            return false
        }

        #if canImport(UniformTypeIdentifiers)
        if #available(iOS 14.0, macOS 11.0, *) {
            if let type = UTType(identifier), type.conforms(to: .image) {
                return true
            }
        }
        #endif

        return false
    }
}
