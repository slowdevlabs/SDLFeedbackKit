import Foundation

enum SDLFeedbackStrings {
    static let bundle: Bundle = .module

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }

    static var title: String { localized("feedback.title") }

    static var categoryTitle: String { localized("feedback.category.title") }
    static var categoryGeneral: String { localized("feedback.category.general") }
    static var categoryBug: String { localized("feedback.category.bug") }
    static var categoryFeatureRequest: String { localized("feedback.category.feature_request") }
    static var categoryOther: String { localized("feedback.category.other") }

    static var messageTitle: String { localized("feedback.message.title") }
    static var messagePlaceholder: String { localized("feedback.message.placeholder") }

    static var emailTitle: String { localized("feedback.email.title") }
    static var emailOptional: String { localized("feedback.email.optional") }

    static var attachmentAdd: String { localized("feedback.attachment.add") }
    static var attachmentReplace: String { localized("feedback.attachment.replace") }
    static var attachmentRemove: String { localized("feedback.attachment.remove") }
    static var attachmentPreparing: String { localized("feedback.attachment.preparing") }
    static var attachmentFailed: String { localized("feedback.attachment.failed") }
    static var attachmentTooLarge: String { localized("feedback.attachment.too_large") }
    static var attachmentTitle: String { localized("feedback.attachment.title") }
    static var attachmentNone: String { localized("feedback.attachment.none") }

    static var submit: String { localized("feedback.submit") }
    static var submitting: String { localized("feedback.submitting") }

    static var successTitle: String { localized("feedback.success.title") }
    static var successMessage: String { localized("feedback.success.message") }

    static var errorTitle: String { localized("feedback.error.title") }
    static var errorGeneric: String { localized("feedback.error.generic") }
    static var errorRetry: String { localized("feedback.error.retry") }
    static var errorInvalidEmail: String { localized("feedback.error.invalid_email") }

    static var cancel: String { localized("feedback.cancel") }
}
