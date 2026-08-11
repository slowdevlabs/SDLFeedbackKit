#if canImport(SwiftUI)
import SwiftUI

struct FeedbackSubmissionStatusView: View {
    let state: FeedbackFormState
    let onRetry: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch state {
            case .idle:
                EmptyView()
            case .processingAttachment:
                EmptyView()
            case .submitting:
                statusRow(
                    icon: nil,
                    title: SDLFeedbackLocalizedStrings.submitting(locale: locale),
                    detail: nil
                )
            case .success:
                statusRow(
                    icon: "✓",
                    title: SDLFeedbackLocalizedStrings.successTitle(locale: locale),
                    detail: SDLFeedbackLocalizedStrings.successMessage(locale: locale),
                    color: .green
                )
            case .failure(.cancelled):
                EmptyView()
            case let .failure(error):
                if FeedbackAttachmentPresentation.shouldSuppressGlobalFailure(for: error) {
                    EmptyView()
                } else {
                    statusRow(
                        icon: "!",
                        title: SDLFeedbackLocalizedStrings.errorTitle(locale: locale),
                        detail: localizedMessage(for: error, locale: locale),
                        color: .red
                    )
                    if error == .submissionFailed {
                        Button(SDLFeedbackLocalizedStrings.errorRetry(locale: locale)) {
                            onRetry()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func statusRow(
        icon: String?,
        title: String,
        detail: String?,
        color: Color = .secondary
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if let icon {
                Text(icon)
                    .font(.headline)
                    .foregroundColor(color)
            } else {
                FeedbackActivityIndicator()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(color)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func localizedMessage(for error: FeedbackError, locale: Locale) -> String {
        switch error {
        case .invalidInput:
            return SDLFeedbackLocalizedStrings.errorGeneric(locale: locale)
        case .invalidEmail:
            return SDLFeedbackLocalizedStrings.errorInvalidEmail(locale: locale)
        case .attachmentTooLarge:
            return SDLFeedbackLocalizedStrings.attachmentTooLarge(locale: locale)
        case .unsupportedAttachment:
            return SDLFeedbackLocalizedStrings.attachmentFailed(locale: locale)
        case .attachmentProcessingFailed:
            return SDLFeedbackLocalizedStrings.attachmentLoadFailed(locale: locale)
        case .submissionFailed:
            return SDLFeedbackLocalizedStrings.errorGeneric(locale: locale)
        case .cancelled:
            return SDLFeedbackLocalizedStrings.errorGeneric(locale: locale)
        }
    }
}
#endif
