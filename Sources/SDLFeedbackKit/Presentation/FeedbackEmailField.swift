#if canImport(SwiftUI)
import SwiftUI

struct FeedbackEmailField: View {
    @Binding var text: String
    let isRequired: Bool
    let validationError: FeedbackError?
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text(SDLFeedbackLocalizedStrings.emailTitle(locale: locale))
                    .fixedSize(horizontal: false, vertical: true)
                if !isRequired {
                    Text(" (")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(SDLFeedbackLocalizedStrings.optional(locale: locale))
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(")")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.headline)
            .accessibilityElement(children: .combine)

            TextField("", text: $text)
                .textFieldStyle(.plain)
                .modifier(FeedbackEmailInputTraits())
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: FeedbackFormPresentationMetrics.controlCornerRadius, style: .continuous)
                        .fill(FeedbackFormPresentationMetrics.controlSurfaceFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FeedbackFormPresentationMetrics.controlCornerRadius, style: .continuous)
                        .strokeBorder(
                            FeedbackFormPresentationMetrics.controlBorderColor,
                            lineWidth: FeedbackFormPresentationMetrics.controlBorderWidth
                        )
                )

            if let validationError {
                Text(localizedMessage(for: validationError))
                    .font(.footnote)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func localizedMessage(for error: FeedbackError) -> String {
        switch error {
        case .invalidEmail:
            return SDLFeedbackLocalizedStrings.errorInvalidEmail(locale: locale)
        default:
            return SDLFeedbackLocalizedStrings.errorInvalidEmail(locale: locale)
        }
    }
}

private struct FeedbackEmailInputTraits: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        return content
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        #elseif os(macOS)
        return content
        #else
        return content
        #endif
    }
}
#endif
