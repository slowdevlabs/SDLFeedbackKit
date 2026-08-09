import Foundation

struct FeedbackValidator: Sendable {
    func validate(
        context: FeedbackContext,
        draft: FeedbackDraft,
        configuration: FeedbackConfiguration
    ) throws {
        try validateConfiguration(configuration)
        try validateContext(context)
        try validateCategory(draft.category)
        try validateMessage(draft.message, configuration: configuration.message)
        try validateEmail(draft.email, configuration: configuration.emailField)
        try validateMetadata(context.metadata)
        try validateAttachment(draft.attachment, configuration: configuration.attachment)
    }

    func normalize(
        context: FeedbackContext,
        draft: FeedbackDraft,
        configuration: FeedbackConfiguration
    ) throws -> NormalizedFeedbackDraft {
        try validate(context: context, draft: draft, configuration: configuration)

        let normalizedMessage = normalizeMessage(draft.message)
        let normalizedEmail = normalizeEmail(draft.email, configuration: configuration.emailField)
        let attachment = configuration.attachment.isEnabled ? draft.attachment : nil

        return NormalizedFeedbackDraft(
            category: draft.category,
            message: normalizedMessage,
            email: normalizedEmail,
            attachment: attachment
        )
    }

    private func validateConfiguration(_ configuration: FeedbackConfiguration) throws {
        guard configuration.message.minimumLength >= 0,
              configuration.message.maximumLength >= configuration.message.minimumLength,
              configuration.emailField.maximumLength > 0,
              configuration.attachment.maximumAttachmentBytes > 0,
              configuration.attachment.maximumImageDimension > 0,
              configuration.attachment.compressionQuality >= 0.5,
              configuration.attachment.compressionQuality <= 1 else {
            throw FeedbackError.invalidInput
        }
    }

    private func validateContext(_ context: FeedbackContext) throws {
        guard isValidAppID(context.appID), isValidAppName(context.appName) else {
            throw FeedbackError.invalidInput
        }
    }

    private func validateCategory(_ category: FeedbackCategory) throws {
        guard isValidTrimmedText(category.id, maxLength: 64),
              isValidTrimmedText(category.title, maxLength: 200) else {
            throw FeedbackError.invalidInput
        }
    }

    private func validateMessage(
        _ message: String,
        configuration: MessageConfiguration
    ) throws {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if configuration.isRequired {
            guard !trimmed.isEmpty else {
                throw FeedbackError.invalidInput
            }
        }

        if !trimmed.isEmpty {
            guard trimmed.count >= configuration.minimumLength,
                  trimmed.count <= configuration.maximumLength else {
                throw FeedbackError.invalidInput
            }
        }
    }

    private func validateEmail(
        _ email: String?,
        configuration: EmailFieldConfiguration
    ) throws {
        if configuration.isEnabled == false {
            return
        }

        let normalized = normalizeEmail(email, configuration: configuration)
        if configuration.isRequired {
            guard let normalized, !normalized.isEmpty else {
                throw FeedbackError.invalidEmail
            }
        }

        if let normalized {
            guard normalized.count <= configuration.maximumLength,
                  isPlausibleEmail(normalized) else {
                throw FeedbackError.invalidEmail
            }
        }
    }

    private func validateMetadata(_ metadata: [String: String]) throws {
        guard metadata.count <= 32 else {
            throw FeedbackError.invalidInput
        }

        for (key, value) in metadata {
            guard isValidTrimmedText(key, maxLength: 64),
                  value.count <= 1_000 else {
                throw FeedbackError.invalidInput
            }
        }
    }

    private func validateAttachment(
        _ attachment: FeedbackAttachment?,
        configuration: AttachmentConfiguration
    ) throws {
        guard let attachment else { return }

        if configuration.isEnabled == false {
            return
        }

        guard !attachment.data.isEmpty,
              attachment.byteCount == attachment.data.count,
              attachment.byteCount <= configuration.maximumAttachmentBytes,
              isValidTrimmedText(attachment.filename, maxLength: 255),
              isValidTrimmedText(attachment.mimeType, maxLength: 128),
              attachment.pixelWidth.map({ $0 > 0 }) ?? true,
              attachment.pixelHeight.map({ $0 > 0 }) ?? true else {
            if attachment.byteCount > configuration.maximumAttachmentBytes {
                throw FeedbackError.attachmentTooLarge
            }
            throw FeedbackError.invalidInput
        }
    }

    private func normalizeMessage(_ message: String) -> String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizeEmail(
        _ email: String?,
        configuration: EmailFieldConfiguration
    ) -> String? {
        guard configuration.isEnabled else { return nil }
        let trimmed = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private func isValidAppID(_ value: String) -> Bool {
        isValidTrimmedText(value, maxLength: 128)
    }

    private func isValidAppName(_ value: String) -> Bool {
        isValidTrimmedText(value, maxLength: 200)
    }

    private func isValidTrimmedText(_ value: String, maxLength: Int) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxLength
    }

    private func isPlausibleEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let local = parts[0]
        let domain = parts[1]
        return !local.isEmpty && !domain.isEmpty && domain.contains(".")
    }
}

struct NormalizedFeedbackDraft: Sendable {
    let category: FeedbackCategory
    let message: String
    let email: String?
    let attachment: FeedbackAttachment?
}
