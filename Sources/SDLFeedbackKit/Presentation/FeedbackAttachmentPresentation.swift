#if canImport(SwiftUI)
import Foundation

enum FeedbackAttachmentPresentation {
    static func processingMessage(for state: FeedbackFormState, locale: Locale) -> String? {
        if case .processingAttachment = state {
            return SDLFeedbackLocalizedStrings.attachmentPreparing(locale: locale)
        }
        return nil
    }

    static func attachmentErrorMessage(for state: FeedbackFormState, locale: Locale) -> String? {
        guard case let .failure(error) = state else {
            return nil
        }
        return attachmentErrorMessage(for: error, locale: locale)
    }

    static func attachmentErrorMessage(for error: FeedbackError, locale: Locale) -> String? {
        switch error {
        case .attachmentTooLarge:
            return SDLFeedbackLocalizedStrings.attachmentTooLarge(locale: locale)
        case .unsupportedAttachment:
            return SDLFeedbackLocalizedStrings.attachmentFailed(locale: locale)
        case .attachmentProcessingFailed:
            return SDLFeedbackLocalizedStrings.attachmentLoadFailed(locale: locale)
        default:
            return nil
        }
    }

    static func shouldSuppressGlobalFailure(for error: FeedbackError) -> Bool {
        switch error {
        case .attachmentTooLarge, .unsupportedAttachment, .attachmentProcessingFailed:
            return true
        default:
            return false
        }
    }
}
#endif
