#if canImport(SwiftUI)
import SwiftUI

struct FeedbackSubmissionStatusView: View {
    let state: FeedbackFormState
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch state {
            case .idle:
                EmptyView()
            case .processingAttachment:
                statusRow(
                    icon: nil,
                    title: SDLFeedbackStrings.attachmentPreparing,
                    detail: nil
                )
            case .submitting:
                statusRow(
                    icon: nil,
                    title: SDLFeedbackStrings.submitting,
                    detail: nil
                )
            case .success:
                statusRow(
                    icon: "✓",
                    title: SDLFeedbackStrings.successTitle,
                    detail: SDLFeedbackStrings.successMessage,
                    color: .green
                )
            case .failure(.cancelled):
                EmptyView()
            case let .failure(error):
                statusRow(
                    icon: "!",
                    title: SDLFeedbackStrings.errorTitle,
                    detail: localizedMessage(for: error),
                    color: .red
                )
                if error == .submissionFailed {
                    Button(SDLFeedbackStrings.errorRetry) {
                        onRetry()
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

    private func localizedMessage(for error: FeedbackError) -> String {
        switch error {
        case .invalidInput:
            return SDLFeedbackStrings.errorGeneric
        case .invalidEmail:
            return SDLFeedbackStrings.errorInvalidEmail
        case .attachmentTooLarge:
            return SDLFeedbackStrings.attachmentTooLarge
        case .unsupportedAttachment, .attachmentProcessingFailed:
            return SDLFeedbackStrings.attachmentFailed
        case .submissionFailed:
            return SDLFeedbackStrings.errorGeneric
        case .cancelled:
            return ""
        }
    }
}
#endif
