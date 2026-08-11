import Foundation

enum FeedbackEmailValidation {
    static func normalizedEmail(
        _ email: String?,
        configuration: EmailFieldConfiguration
    ) -> String? {
        guard configuration.isEnabled else { return nil }

        let trimmed = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else {
            return nil
        }

        return trimmed
    }

    static func validationError(
        for email: String?,
        configuration: EmailFieldConfiguration
    ) -> FeedbackError? {
        guard configuration.isEnabled else {
            return nil
        }

        guard let normalized = normalizedEmail(email, configuration: configuration) else {
            return nil
        }

        guard normalized.count <= configuration.maximumLength,
              isPlausibleEmail(normalized) else {
            return .invalidEmail
        }

        return nil
    }

    static func isValid(
        _ email: String?,
        configuration: EmailFieldConfiguration
    ) -> Bool {
        validationError(for: email, configuration: configuration) == nil
    }

    private static func isPlausibleEmail(_ value: String) -> Bool {
        guard !value.contains(where: { $0.isWhitespace }) else {
            return false
        }

        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            return false
        }

        let local = parts[0]
        let domain = parts[1]

        guard !local.isEmpty,
              !domain.isEmpty,
              domain.contains(".") else {
            return false
        }

        return true
    }
}
