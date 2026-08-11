import Foundation

enum SDLFeedbackLocalizedStrings {
    private static let bundle: Bundle = .module
    private static let tableName = "Localizable"

    static func title(locale: Locale) -> String {
        localized("feedback.title", locale: locale)
    }

    static func categoryTitle(locale: Locale) -> String {
        localized("feedback.category.title", locale: locale)
    }

    static func categoryGeneral(locale: Locale) -> String {
        localized("feedback.category.general", locale: locale)
    }

    static func categoryBug(locale: Locale) -> String {
        localized("feedback.category.bug", locale: locale)
    }

    static func categoryFeatureRequest(locale: Locale) -> String {
        localized("feedback.category.feature_request", locale: locale)
    }

    static func categoryOther(locale: Locale) -> String {
        localized("feedback.category.other", locale: locale)
    }

    static func categoryCollapsed(locale: Locale) -> String {
        localized("feedback.category.collapsed", locale: locale)
    }

    static func categoryExpanded(locale: Locale) -> String {
        localized("feedback.category.expanded", locale: locale)
    }

    static func messageTitle(locale: Locale) -> String {
        localized("feedback.message.title", locale: locale)
    }

    static func messagePlaceholder(locale: Locale) -> String {
        localized("feedback.message.placeholder", locale: locale)
    }

    static func emailTitle(locale: Locale) -> String {
        localized("feedback.email.title", locale: locale)
    }

    static func emailOptional(locale: Locale) -> String {
        localized("feedback.email.optional", locale: locale)
    }

    static func optional(locale: Locale) -> String {
        localized("feedback.email.optional", locale: locale)
    }

    static func attachmentAdd(locale: Locale) -> String {
        localized("feedback.attachment.add", locale: locale)
    }

    static func attachmentReplace(locale: Locale) -> String {
        localized("feedback.attachment.replace", locale: locale)
    }

    static func attachmentRemove(locale: Locale) -> String {
        localized("feedback.attachment.remove", locale: locale)
    }

    static func attachmentPreparing(locale: Locale) -> String {
        localized("feedback.attachment.preparing", locale: locale)
    }

    static func attachmentFailed(locale: Locale) -> String {
        localized("feedback.attachment.failed", locale: locale)
    }

    static func attachmentLoadFailed(locale: Locale) -> String {
        localized("feedback.attachment.load_failed", locale: locale)
    }

    static func attachmentTooLarge(locale: Locale) -> String {
        localized("feedback.attachment.too_large", locale: locale)
    }

    static func attachmentTitle(locale: Locale) -> String {
        localized("feedback.attachment.title", locale: locale)
    }

    static func attachmentNone(locale: Locale) -> String {
        localized("feedback.attachment.none", locale: locale)
    }

    static func privacyPolicyLabel(locale: Locale) -> String {
        localized("feedback.privacy.policy", locale: locale)
    }

    static func privacyDisclosureBody(appName: String, locale: Locale) -> String {
        localizedStringWithFormat(
            "feedback.privacy.disclosure.body",
            locale: locale,
            appName
        )
    }

    static func submit(locale: Locale) -> String {
        localized("feedback.submit", locale: locale)
    }

    static func submitting(locale: Locale) -> String {
        localized("feedback.submitting", locale: locale)
    }

    static func successTitle(locale: Locale) -> String {
        localized("feedback.success.title", locale: locale)
    }

    static func successMessage(locale: Locale) -> String {
        localized("feedback.success.message", locale: locale)
    }

    static func errorTitle(locale: Locale) -> String {
        localized("feedback.error.title", locale: locale)
    }

    static func errorGeneric(locale: Locale) -> String {
        localized("feedback.error.generic", locale: locale)
    }

    static func errorRetry(locale: Locale) -> String {
        localized("feedback.error.retry", locale: locale)
    }

    static func errorInvalidEmail(locale: Locale) -> String {
        localized("feedback.error.invalid_email", locale: locale)
    }

    static func cancel(locale: Locale) -> String {
        localized("feedback.cancel", locale: locale)
    }

    static func categoryTitle(for category: FeedbackCategory, locale: Locale) -> String? {
        switch category.id {
        case "general":
            return categoryGeneral(locale: locale)
        case "bug":
            return categoryBug(locale: locale)
        case "feature_request":
            return categoryFeatureRequest(locale: locale)
        case "other":
            return categoryOther(locale: locale)
        default:
            return nil
        }
    }

    private static func localized(_ key: String, locale: Locale) -> String {
        localizedBundle(for: locale).localizedString(forKey: key, value: nil, table: tableName)
    }

    private static func localizedStringWithFormat(
        _ key: String,
        locale: Locale,
        _ arguments: CVarArg...
    ) -> String {
        let format = localized(key, locale: locale)
        return String(format: format, locale: locale, arguments: arguments)
    }

    private static func localizedBundle(for locale: Locale) -> Bundle {
        for identifier in localizationIdentifiers(for: locale) {
            if let bundle = bundle(forLocalization: identifier) {
                return bundle
            }
        }
        return bundle
    }

    private static func bundle(forLocalization identifier: String) -> Bundle? {
        guard let path = bundle.path(forResource: identifier, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }

    private static func localizationIdentifiers(for locale: Locale) -> [String] {
        var identifiers: [String] = []

        if let languageCode = locale.languageCode {
            if let scriptCode = locale.scriptCode {
                identifiers.append("\(languageCode)-\(scriptCode)")
            }
            if let regionCode = locale.regionCode {
                identifiers.append("\(languageCode)-\(regionCode)")
            }
            identifiers.append(languageCode)
        }

        let normalized = locale.identifier.replacingOccurrences(of: "_", with: "-")
        if !normalized.isEmpty {
            identifiers.append(normalized)
        }

        identifiers.append("en")

        var seen: Set<String> = []
        return identifiers.filter { seen.insert($0).inserted }
    }
}
